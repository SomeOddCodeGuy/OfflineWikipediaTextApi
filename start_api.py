import os
import json
from typing import List, Dict

import colorama
from colorama import Fore, Style
from fastapi import FastAPI, HTTPException, Query
from datasets import Dataset, concatenate_datasets
import uvicorn
from txtai.embeddings import Embeddings

from collections import Counter
import re

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

def escape_sql_string(s) -> str:
    s = s.replace("'", "")
    s = s.replace("\"", "")
    s = s.replace(";", "")
    return s

@app.get("/articles/{title}")
async def get_full_article_by_title(title: str):
    """Get the full article by title."""
    title = escape_sql_string(title)
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
    num_results: int = Query(5, description="Number of results to return")
):
    prompt = escape_sql_string(prompt)
    """Get wiki summaries by search prompt."""
    search_query = f"SELECT id, title, text FROM txtai WHERE similar('{prompt}') and percentile >= {percentile}"
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
async def get_full_wiki_articles_by_prompt(
    prompt: str = Query(..., description="Search prompt"),
    percentile: float = Query(0.5, description="Percentile for search relevance"),
    num_results: int = Query(5, description="Number of results to return")
):
    """Get full wiki articles by search prompt."""
    prompt = escape_sql_string(prompt)
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

@app.get("/top_article")
async def get_top_full_article_by_prompt(
    prompt: str = Query(..., description="Search prompt"),
    percentile: float = Query(0.5, description="Percentile for search relevance"),
    num_results: int = Query(5, description="Number of results to return")
):
    prompt = escape_sql_string(prompt)
    """Get the top wiki article by search prompt."""
    search_query = f"SELECT id, text FROM txtai WHERE similar('{prompt}') and percentile >= {percentile}"
    try:
        results = embeddings.search(search_query, num_results)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search error: {e}")

    if not results:
        raise HTTPException(status_code=404, detail="No results found for prompt")

    articles = []
    for result in results:
        index = title_to_index.get(result['id'])
        if index is not None:
            record = ds[index]
            article_text = record["text"]
            articles.append({"title": record["title"], "text": article_text})
        else:
            raise HTTPException(status_code=404, detail=f"No record found with title {result['id']}")

    best_article = select_best_wikipedia_article(prompt, articles)
    if best_article:
        return best_article
    else:
        raise HTTPException(status_code=404, detail="No suitable article found")

@app.get("/top_n_articles")
async def get_top_n_full_articles_by_prompt(
    prompt: str = Query(..., description="Search prompt"),
    percentile: float = Query(0.5, description="Percentile for search relevance"),
    num_results: int = Query(20, description="Number of results to return"),
    num_top_articles: int = Query(8, description="number of top articles to return")
):
    prompt = escape_sql_string(prompt)
    """Get the top N wiki articles by search prompt."""
    search_query = f"SELECT id, text FROM txtai WHERE similar('{prompt}') and percentile >= {percentile}"
    try:
        results = embeddings.search(search_query, num_results)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search error: {e}")

    if not results:
        raise HTTPException(status_code=404, detail="No results found for prompt")

    articles = []
    for result in results:
        index = title_to_index.get(result['id'])
        if index is not None:
            record = ds[index]
            article_text = record["text"]
            articles.append({"title": record["title"], "text": article_text})
        else:
            raise HTTPException(status_code=404, detail=f"No record found with title {result['id']}")

    top_n_articles = select_top_n_wikipedia_articles(prompt, articles, num_top_articles)
    if top_n_articles:
        return top_n_articles
    else:
        raise HTTPException(status_code=404, detail="No suitable article found")

def select_best_wikipedia_article(prompt: str, articles: List[Dict[str, str]]) -> Dict[str, str]:
    """
    Select the best matching article based on the prompt, accounting for token frequencies.

    Args:
        prompt (str): The original prompt.
        articles (list): List of dictionaries with 'title' and 'text'.

    Returns:
        dict: The article dictionary with the highest similarity score.
    """

    def tokenize(text):
        return re.findall(r'\w+', text.lower())

    prompt_tokens = tokenize(prompt)
    prompt_counter = Counter(prompt_tokens)
    best_score = -1
    best_article = None

    for article in articles:
        title_tokens = tokenize(article.get('title', ''))
        text_tokens = tokenize(article.get('text', ''))

        title_counter = Counter(title_tokens)
        text_counter = Counter(text_tokens)

        title_overlap = sum((prompt_counter & title_counter).values())
        text_overlap = sum((prompt_counter & text_counter).values())

        # Assign weights (title matches are more significant)
        score = title_overlap * 2 + text_overlap

        if verbose:
            print(f"Article Title: {article.get('title', '')}")
            print(f"Title Overlap Count: {title_overlap}, Text Overlap Count: {text_overlap}, Score: {score}")

        if score > best_score:
            best_score = score
            best_article = article

    return best_article

def select_top_n_wikipedia_articles(prompt: str, articles: List[Dict[str, str]], num_top_articles: int) -> List[Dict[str, str]]:
    """
    Select the top_n articles based on the prompt, accounting for token frequencies.

    Args:
        prompt (str): The original prompt.
        articles (list): List of dictionaries with 'title' and 'text'.
        num_top_articles (int): The number of top articles to return.

    Returns:
        List of dict: The articles dictionaries with the highest similarity score.
    """

    def tokenize(text):
        return re.findall(r'\w+', text.lower())

    prompt_tokens = tokenize(prompt)
    prompt_counter = Counter(prompt_tokens)
    best_score = -1
    best_article = None

    scored_articles = []

    for article in articles:
        title_tokens = tokenize(article.get('title', ''))
        text_tokens = tokenize(article.get('text', ''))

        title_counter = Counter(title_tokens)
        text_counter = Counter(text_tokens)

        title_overlap = sum((prompt_counter & title_counter).values())
        text_overlap = sum((prompt_counter & text_counter).values())

        # Assign weights (title matches are more significant)
        score = title_overlap * 2 + text_overlap

        if verbose:
            print(f"Article Title: {article.get('title', '')}")
            print(f"Title Overlap Count: {title_overlap}, Text Overlap Count: {text_overlap}, Score: {score}")

        scored_articles.append((score, article))

    #positive will be decending top articles, negative ascending
    if num_top_articles >= 0:
        # Sort articles by score in descending order and select the top_n articles
        scored_articles.sort(reverse=True, key=lambda x: x[0])
        top_n_articles = [article for score, article in scored_articles[:num_top_articles]]
    else:
        # Sort articles by score in ascending order and select the top_n articles
        #useful to have top article last as LLM chat context length truncated from top
        scored_articles.sort(reverse=False, key=lambda x: x[0])
        #since num_top_articles is already negative, this takes last n articles
        top_n_articles = [article for score, article in scored_articles[num_top_articles:]]

    return top_n_articles





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
