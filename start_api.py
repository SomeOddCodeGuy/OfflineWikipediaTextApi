import os
import json

import colorama
from colorama import Fore, Style
from fastapi import FastAPI, HTTPException, Query
from datasets import Dataset, concatenate_datasets
import uvicorn
from txtai.embeddings import Embeddings

# Correcting an issue in Windows
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"

WIKI_DATASET_DIR = os.path.join("wiki-dataset", "train")
TXT_AI_DIR = "txtai-wikipedia"
DICTIONARY_FILE = "title_to_index.json"
CONFIG_FILE = "config.json"

def load_config():
    """Load the configuration from the JSON file."""
    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)

def load_wiki_dataset():
    """Load the Wikipedia dataset."""
    arrow_files = [os.path.join(WIKI_DATASET_DIR, f) for f in os.listdir(WIKI_DATASET_DIR) if f.endswith('.arrow')]
    datasets = [Dataset.from_file(file) for file in arrow_files]
    return concatenate_datasets(datasets)

def load_title_to_index(ds):
    """Load or create the title to index mapping."""
    if os.path.exists(DICTIONARY_FILE):
        with open(DICTIONARY_FILE, 'r') as f:
            return json.load(f)
    else:
        title_to_index = {record['title']: i for i, record in enumerate(ds)}
        with open(DICTIONARY_FILE, 'w') as f:
            json.dump(title_to_index, f)
        return title_to_index

# Load configuration
config = load_config()
host = config.get("host", "0.0.0.0")
port = config.get("port", 5728)
verbose = config.get("verbose", False)
log_level = "info" if verbose else "warning"

# Load datasets and mappings
ds = load_wiki_dataset()
title_to_index = load_title_to_index(ds)

# Initialize FastAPI app
app = FastAPI()

# Initialize txtai embeddings
embeddings = Embeddings()
embeddings.load(path=TXT_AI_DIR)

@app.get("/articles/{title}")
async def get_full_article_by_title(title: str):
    """Get the full article by title."""
    index = title_to_index.get(title)
    if index is not None:
        record = ds[index]
        return {"title": record["title"], "text": record["text"]}
    else:
        raise HTTPException(status_code=404, detail=f"No record found with title {title}")

@app.get("/summaries")
async def get_wiki_summary_by_prompt(
    prompt: str = Query(..., description="Search prompt"),
    percentile: float = Query(0.5, description="Percentile for search relevance"),
    num_results: int = Query(1, description="Number of results to return")
):
    """Get wiki summaries by search prompt."""
    search_query = f"SELECT id, text FROM txtai WHERE similar('{prompt}') and percentile >= {percentile}"
    try:
        results = embeddings.search(search_query, num_results)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search error: {e}")

    if not results:
        raise HTTPException(status_code=404, detail="No results found for prompt")

    summaries = []
    for result in results:
        index = title_to_index.get(result['id'])
        if index is not None:
            record = ds[index]
            summary_text = record["text"][:500]  # Return a summary snippet of the first 500 characters
            summaries.append({"title": record["title"], "text": summary_text})
        else:
            raise HTTPException(status_code=404, detail=f"No record found with title {result['id']}")

    return summaries

@app.get("/articles")
async def get_full_wiki_article_by_prompt(
    prompt: str = Query(..., description="Search prompt"),
    percentile: float = Query(0.5, description="Percentile for search relevance"),
    num_results: int = Query(1, description="Number of results to return")
):
    """Get full wiki articles by search prompt."""
    search_query = f"SELECT id FROM txtai WHERE similar('{prompt}') and percentile >= {percentile}"
    try:
        results = embeddings.search(search_query, num_results)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search error: {e}")

    if not results:
        raise HTTPException(status_code=404, detail="No results found for prompt")

    articles = []
    for result in results:
        title_id = result['id']
        index = title_to_index.get(title_id)
        if index is not None:
            record = ds[index]
            articles.append({"title": record["title"], "text": record["text"]})
        else:
            raise HTTPException(status_code=404, detail=f"No record found with title {title_id}")

    return articles


if __name__ == "__main__":
    colorama.init(autoreset=True)
    print("---------------------------------------------------------------")
    print("API started!")
    print(f"Host: {Fore.CYAN}{host}")
    print(f"Port: {Fore.CYAN}{port}")

    if log_level == "info":
        log_color = Fore.GREEN
    else:
        log_color = Fore.YELLOW

    print(f"Log level: {log_color}{log_level}")
    print(f"Please {Fore.RED}ctrl + c{Style.RESET_ALL} to end")

    uvicorn.run(app, host=host, port=port, log_level=log_level)
