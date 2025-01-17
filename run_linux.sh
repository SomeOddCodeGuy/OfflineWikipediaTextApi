#!/bin/bash

# Stop script on any error code and trap errors for easier debugging
set -eE
trap 'echo >&2 "Error - exited with status $? at line $LINENO"' ERR

# Step 0: Parse any arguments we care about
DATABASE_DIR="."
WIKI_DATA_SET_DIR="$DATA_DIR/wiki-dataset"
TXTAI_WIKIPEDIA_DIR="$DATA_DIR/txtai-wikipedia"
OTHER_ARGS=()

function help() {
    echo "usage: $0 [-h] [-d DATABASE_DIR]"
    echo
    echo "Offline Wikipedia Text API"
    echo
    echo "options:"
    echo "-h, --help            show this help message and exit"
    echo "-d DATABASE_DIR, --database_dir DATABASE_DIR"
    echo "                      Base directory containing the wiki-dataset and txtai-wikipedia"
    echo "                      folders."
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --database_dir|-d)
      DATABASE_DIR="$2"
      shift 2
      ;;
    --help|-h)
      help
      exit 0
      ;;
    *)
      # For any unrecognized args, store them to pass through
      OTHER_ARGS+=("$1")
      shift
      ;;
  esac
done


# Step A: Create and activate a Python virtual environment
echo Creating virtual environment
if [ ! -f "venv" ]; then
    python -m venv venv
else
    echo Existing venv detected. Activating.
fi

echo Activating virtual environment
source venv/bin/activate

# Step B: Install requirements from requirements.txt
echo ---------------------------------------------------------------
echo Installing python requirements from requirements.txt
pip install -r requirements.txt

# Step C: Clone the git repository for full wiki articles into a directory called "wiki-dataset"
echo ---------------------------------------------------------------
echo Downloading Wikipedia dataset. As of 2024-11-14, this is about 44GB
if [ ! -d "$WIKI_DATA_SET_DIR" ]; then
    git clone https://huggingface.co/datasets/NeuML/wikipedia-20240901 "$WIKI_DATA_SET_DIR"
else
    echo Existing wiki-dataset directory detected.
fi

# Step D: Clone the git repository for txtai wiki summaries into a directory called txtai-wikipedia
echo ---------------------------------------------------------------
echo Downloading txtai-wikipedia dataset. As of 2024-11-14, this is about 15GB.
if [ ! -d "$TXTAI_WIKIPEDIA_DIR" ]; then
    git clone https://huggingface.co/NeuML/txtai-wikipedia "$TXTAI_WIKIPEDIA_DIR"
else
    echo Existing txtai-wikipedia directory detected.
fi

# Finally: Start the API
echo ---------------------------------------------------------------
echo Starting API. If this is the first run, setup may take 10-15 minutes depending on your machine.
echo Setup time is due to indexing wikipedia article titles into a json file for API speed.
echo ---------------------------------------------------------------
echo API Starting...
python start_api.py --database_dir "$DATABASE_DIR" "${OTHER_ARGS[@]}"