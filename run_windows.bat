@echo off
setlocal

:: Step A: Create and activate a Python virtual environment
echo Creating virtual environment
if not exist venv (
    python -m venv venv
) else (
    echo Existing venv detected. Activating.
)

echo Activating virtual environment
call venv\Scripts\activate

:: Step B: Install requirements from requirements.txt
echo ---------------------------------------------------------------
echo Installing python requirements from requirements.txt
pip install -r requirements.txt

:: Step C: Clone the git repository for full wiki articles into a directory called "wiki-dataset"
echo ---------------------------------------------------------------
echo Downloading Wikipedia dataset. As of 2024-07-26, this is about 43GB
if not exist wiki-dataset (
    git clone https://huggingface.co/datasets/NeuML/wikipedia-20240101 wiki-dataset
) else (
    echo Existing wiki-dataset directory detected.
)

:: Step D: Clone the git repository for txtai wiki summaries into a directory called txtai-wikipedia
echo ---------------------------------------------------------------
echo Downloading txtai-wikipedia dataset. As of 2024-07-26, this is about 15GB.
if not exist txtai-wikipedia (
    git clone https://huggingface.co/NeuML/txtai-wikipedia txtai-wikipedia
) else (
    echo Existing txtai-wikipedia directory detected.
)

:: Finally: Start the API
echo ---------------------------------------------------------------
echo Starting API. If this is the first run, setup may take 10-15 minutes depending on your machine.
echo Setup time is due to indexing wikipedia article titles into a json file for API speed.
echo ---------------------------------------------------------------
echo API Starting...
python start_api.py

endlocal