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

:: Pre-flight: verify required tools are installed (we don't auto-install anything)
set MISSING_GIT=
set MISSING_LFS=
set MISSING_PYTHON=
where git >nul 2>nul
if errorlevel 1 set MISSING_GIT=1
where git-lfs >nul 2>nul
if errorlevel 1 set MISSING_LFS=1
where python >nul 2>nul
if errorlevel 1 set MISSING_PYTHON=1

if not defined MISSING_GIT if not defined MISSING_LFS if not defined MISSING_PYTHON goto tools_ok

echo ---------------------------------------------------------------
echo ERROR: Required tool(s) not found on PATH:
if defined MISSING_GIT    echo   - git
if defined MISSING_LFS    echo   - git-lfs
if defined MISSING_PYTHON echo   - python
echo.
echo This script will NOT auto-install anything. The Wikipedia dataset is
echo distributed via Git LFS - without git-lfs, the download will silently
echo produce broken pointer files instead of the real data, and the API
echo will fail to start. Please install the missing tool(s) yourself,
echo then re-run.
echo.
echo Install from:
echo   git:      https://git-scm.com/download/win  (Git for Windows usually
echo                                                 includes git-lfs)
echo   git-lfs:  https://git-lfs.com/  (only if Git for Windows did not
echo                                     include it)
echo   python:   https://www.python.org/downloads/windows/
echo.
echo After installing git-lfs, open a NEW terminal and run once:
echo     git lfs install
echo ---------------------------------------------------------------
exit /b 1

:tools_ok

:: Pre-flight: confirm before kicking off a multi-GB dataset download
set NEED_DOWNLOAD=0
if not exist "%WIKI_DATASET_DIR%" set NEED_DOWNLOAD=1
if not exist "%TXT_AI_DIR%" set NEED_DOWNLOAD=1
if "%NEED_DOWNLOAD%"=="0" goto skip_download_prompt

echo ---------------------------------------------------------------
echo WARNING: One or more datasets need to be downloaded.
if not exist "%WIKI_DATASET_DIR%" echo   - wiki-dataset ^(NeuML/wikipedia-20260401^)  ~50GB
if not exist "%TXT_AI_DIR%" echo   - txtai-wikipedia                          ~17GB
echo.
set /p CONFIRM="Continue with download? [y/N] "
if /i "%CONFIRM%"=="y" goto skip_download_prompt
if /i "%CONFIRM%"=="yes" goto skip_download_prompt
echo Aborted.
exit /b 0

:skip_download_prompt

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
echo Downloading Wikipedia dataset. As of 2026-05-28, this is about 50GB
if not exist "%WIKI_DATASET_DIR%" (
    set GIT_LFS_SKIP_SMUDGE=1
    git clone --depth 1 https://huggingface.co/datasets/NeuML/wikipedia-20260401 "%WIKI_DATASET_DIR%"
    set GIT_LFS_SKIP_SMUDGE=
)
if not exist "%WIKI_DATASET_DIR%\.git" goto skip_wiki_finalize
echo Pulling LFS files for wiki dataset (this may take a while)...
pushd "%WIKI_DATASET_DIR%"
git lfs pull
popd
:skip_wiki_finalize

:: Step D: Clone the git repository for txtai wiki summaries into the specified directory
echo ---------------------------------------------------------------
echo Downloading txtai-wikipedia dataset. As of 2026-05-28, this is about 17GB.
if not exist "%TXT_AI_DIR%" (
    set GIT_LFS_SKIP_SMUDGE=1
    git clone --depth 1 https://huggingface.co/NeuML/txtai-wikipedia "%TXT_AI_DIR%"
    set GIT_LFS_SKIP_SMUDGE=
)
if not exist "%TXT_AI_DIR%\.git" goto skip_txtai_finalize
echo Pulling LFS files for txtai dataset (this may take a while)...
pushd "%TXT_AI_DIR%"
git lfs pull
popd
:skip_txtai_finalize

:: Notice: if .git folders are present, tell the user they can be removed
set SHOW_NOTICE=0
if exist "%WIKI_DATASET_DIR%\.git" set SHOW_NOTICE=1
if exist "%TXT_AI_DIR%\.git" set SHOW_NOTICE=1
if "%SHOW_NOTICE%"=="0" goto skip_notice
echo.
echo ---------------------------------------------------------------
echo NOTICE: Git LFS keeps a duplicate copy of the binary files inside
echo the .git folder of each dataset. Once you have the data, those
echo copies are not needed. Removing them is OPTIONAL and frees disk:
echo.
if exist "%WIKI_DATASET_DIR%\.git" echo   %WIKI_DATASET_DIR%\.git    ^(~25GB^)
if exist "%TXT_AI_DIR%\.git" echo   %TXT_AI_DIR%\.git  ^(~8.4GB^)
echo.
echo To remove them yourself, run (only if you have what you need):
if exist "%WIKI_DATASET_DIR%\.git" echo   rmdir /s /q "%WIKI_DATASET_DIR%\.git"
if exist "%TXT_AI_DIR%\.git" echo   rmdir /s /q "%TXT_AI_DIR%\.git"
echo.
echo Trade-off: with .git removed you cannot 'git pull' to update.
echo To move to a newer dataset snapshot you would re-clone the folder.
echo ---------------------------------------------------------------
:skip_notice

:: Finally: Start the API
echo ---------------------------------------------------------------
echo Starting API. If this is the first run, setup may take 10-15 minutes depending on your machine.
echo Setup time is due to indexing Wikipedia article titles into a json file for API speed.
echo ---------------------------------------------------------------
echo API Starting...
python start_api.py --database_dir "%DATABASE_DIR%"

endlocal