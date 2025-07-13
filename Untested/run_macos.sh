#!/bin/bash

# Step 0: Parse any arguments we care about
DATABASE_DIR="."

while [[ $# -gt 0 ]]; do
  case $1 in
    --database_dir|-d)
      DATABASE_DIR="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--database_dir <path>]"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

WIKI_DATASET_DIR="${DATABASE_DIR}/wiki-dataset"
TXT_AI_WIKIPEDIA_DIR="${DATABASE_DIR}/txtai-wikipedia"

# Step A: Create and activate a Python virtual environment
echo "Creating virtual environment"
if [ ! -d "venv" ]; then
    python3 -m venv venv
else
    echo "Existing venv detected. Activating."
fi

echo "Activating virtual environment"
source venv/bin/activate

# Step B: Install requirements from requirements.txt
echo "---------------------------------------------------------------"
echo "Installing python requirements from requirements.txt"
pip install -r requirements.txt

# Step C: Clone the git repository for full wiki articles
echo "---------------------------------------------------------------"
echo "Downloading Wikipedia dataset. As of 2025-07-13, this is about 46GB"
if [ ! -d "${WIKI_DATASET_DIR}" ]; then
    git clone https://huggingface.co/datasets/NeuML/wikipedia-20250620 "${WIKI_DATASET_DIR}"
else
    echo "Existing wiki-dataset directory detected."
fi

# Step D: Clone the git repository for txtai wiki summaries
echo "---------------------------------------------------------------"
echo "Downloading txtai-wikipedia dataset. As of 2025-07-13, this is about 15GB."
if [ ! -d "${TXT_AI_WIKIPEDIA_DIR}" ]; then
    git clone https://huggingface.co/NeuML/txtai-wikipedia "${TXT_AI_WIKIPEDIA_DIR}"
else
    echo "Existing txtai-wikipedia directory detected."
fi

# Finally: Start the API
echo "---------------------------------------------------------------"
echo "Starting API. If this is the first run, setup may take 10-15 minutes depending on your machine."
echo "Setup time is due to indexing wikipedia article titles into a json file for API speed."
echo "---------------------------------------------------------------"
echo "API Starting..."
python3 start_api.py --database_dir "${DATABASE_DIR}"