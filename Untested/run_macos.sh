#!/bin/bash

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

# Step C: Clone the git repository for full wiki articles into a directory called "wiki-dataset"
echo "---------------------------------------------------------------"
echo "Downloading Wikipedia dataset. As of 2024-07-26, this is about 43GB"
if [ ! -d "wiki-dataset" ]; then
    git clone https://huggingface.co/datasets/NeuML/wikipedia-20240101 wiki-dataset
else
    echo "Existing wiki-dataset directory detected."
fi

# Step D: Clone the git repository for txtai wiki summaries into a directory called txtai-wikipedia
echo "---------------------------------------------------------------"
echo "Downloading txtai-wikipedia dataset. As of 2024-07-26, this is about 15GB."
if [ ! -d "txtai-wikipedia" ]; then
    git clone https://huggingface.co/NeuML/txtai-wikipedia txtai-wikipedia
else
    echo "Existing txtai-wikipedia directory detected."
fi

# Finally: Start the API
echo "---------------------------------------------------------------"
echo "Starting API. If this is the first run, setup may take 10-15 minutes depending on your machine."
echo "Setup time is due to indexing wikipedia article titles into a json file for API speed."
echo "---------------------------------------------------------------"
echo "API Starting..."
python3 start_api.py
