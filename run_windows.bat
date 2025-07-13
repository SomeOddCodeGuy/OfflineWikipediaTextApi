@echo off
setlocal

:: Step 0: Parse input arguments for database directory
set DATABASE_DIR=.

:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="--database_dir" (
    set DATABASE_DIR=%~2
    shift
    shift
) else (
    shift
)
goto parse_args
:args_done

:: Normalize paths
set WIKI_DATASET_DIR=%DATABASE_DIR%\wiki-dataset
set TXT_AI_DIR=%DATABASE_DIR%\txtai-wikipedia

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

:: Step C: Clone the git repository for full wiki articles into the specified directory
echo ---------------------------------------------------------------
echo Downloading Wikipedia dataset. As of 2025-07-13, this is about 46GB
if not exist "%WIKI_DATASET_DIR%" (
    git clone https://huggingface.co/datasets/NeuML/wikipedia-20250620 "%WIKI_DATASET_DIR%"
) else (
    echo Existing wiki-dataset directory detected.
)

:: Step D: Clone the git repository for txtai wiki summaries into the specified directory
echo ---------------------------------------------------------------
echo Downloading txtai-wikipedia dataset. As of 2025-07-13, this is about 15GB.
if not exist "%TXT_AI_DIR%" (
    git clone https://huggingface.co/NeuML/txtai-wikipedia "%TXT_AI_DIR%"
) else (
    echo Existing txtai-wikipedia directory detected.
)

:: Finally: Start the API
echo ---------------------------------------------------------------
echo Starting API. If this is the first run, setup may take 10-15 minutes depending on your machine.
echo Setup time is due to indexing Wikipedia article titles into a json file for API speed.
echo ---------------------------------------------------------------
echo API Starting...
python start_api.py --database_dir "%DATABASE_DIR%"

endlocal