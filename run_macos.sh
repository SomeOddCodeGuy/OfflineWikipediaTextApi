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


# Pre-flight: verify required tools are installed (we don't auto-install anything)
MISSING=""
command -v git >/dev/null 2>&1     || MISSING="$MISSING git"
command -v git-lfs >/dev/null 2>&1 || MISSING="$MISSING git-lfs"
command -v python3 >/dev/null 2>&1 || MISSING="$MISSING python3"

if [ -n "$MISSING" ]; then
    echo "---------------------------------------------------------------"
    echo "ERROR: Required tool(s) not found on PATH:$MISSING"
    echo ""
    echo "This script will not auto-install anything. The Wikipedia dataset is"
    echo "distributed via Git LFS - without git-lfs, the download will silently"
    echo "produce broken pointer files instead of the real data, and the API"
    echo "will fail to start. The git that ships with Xcode Command Line Tools"
    echo "does NOT include git-lfs by default."
    echo ""
    echo "Install the missing tool(s) yourself, then re-run. Common options:"
    echo "  git:      https://git-scm.com/download/mac  (or 'xcode-select --install')"
    echo "  git-lfs:  https://git-lfs.com/  (download installer, or 'brew install git-lfs')"
    echo "  python3:  https://www.python.org/downloads/macos/"
    echo ""
    echo "After installing git-lfs, run once to register the smudge filter:"
    echo "    git lfs install"
    echo "---------------------------------------------------------------"
    exit 1
fi


# Pre-flight: confirm before kicking off a multi-GB dataset download
if [ ! -d "$WIKI_DATASET_DIR" ] || [ ! -d "$TXT_AI_WIKIPEDIA_DIR" ]; then
    echo "---------------------------------------------------------------"
    echo "WARNING: One or more datasets need to be downloaded."
    [ ! -d "$WIKI_DATASET_DIR" ]      && echo "  - wiki-dataset (NeuML/wikipedia-20260401)  ~50GB"
    [ ! -d "$TXT_AI_WIKIPEDIA_DIR" ]  && echo "  - txtai-wikipedia                          ~17GB"
    echo ""
    read -r -p "Continue with download? [y/N] " response
    case "$response" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "Aborted."; exit 0 ;;
    esac
fi


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
echo "Downloading Wikipedia dataset. As of 2026-05-28, this is about 50GB"
if [ ! -d "${WIKI_DATASET_DIR}" ]; then
    # Shallow clone with LFS smudge skipped so the initial fetch is fast
    GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1 https://huggingface.co/datasets/NeuML/wikipedia-20260401 "${WIKI_DATASET_DIR}"
fi
if [ -d "${WIKI_DATASET_DIR}/.git" ]; then
    echo "Pulling LFS files for wiki dataset (this may take a while)..."
    # pushd/popd keeps cwd safe even if `git lfs pull` fails mid-way.
    pushd "${WIKI_DATASET_DIR}" >/dev/null && { git lfs pull || echo "LFS pull failed for wiki dataset"; popd >/dev/null; }
else
    echo "Existing wiki-dataset directory detected (no .git folder present)."
fi

# Step D: Clone the git repository for txtai wiki summaries
echo "---------------------------------------------------------------"
echo "Downloading txtai-wikipedia dataset. As of 2026-05-28, this is about 17GB."
if [ ! -d "${TXT_AI_WIKIPEDIA_DIR}" ]; then
    GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1 https://huggingface.co/NeuML/txtai-wikipedia "${TXT_AI_WIKIPEDIA_DIR}"
fi
if [ -d "${TXT_AI_WIKIPEDIA_DIR}/.git" ]; then
    echo "Pulling LFS files for txtai dataset (this may take a while)..."
    pushd "${TXT_AI_WIKIPEDIA_DIR}" >/dev/null && { git lfs pull || echo "LFS pull failed for txtai dataset"; popd >/dev/null; }
else
    echo "Existing txtai-wikipedia directory detected (no .git folder present)."
fi

# Notice: if .git folders are present, tell the user they can be removed
if [ -d "${WIKI_DATASET_DIR}/.git" ] || [ -d "${TXT_AI_WIKIPEDIA_DIR}/.git" ]; then
    echo ""
    echo "---------------------------------------------------------------"
    echo "NOTICE: Git LFS keeps a duplicate copy of the binary files inside"
    echo "the .git folder of each dataset. Once you have the data, those"
    echo "copies are not needed. Removing them is OPTIONAL and frees disk:"
    echo ""
    [ -d "${WIKI_DATASET_DIR}/.git" ]     && echo "  ${WIKI_DATASET_DIR}/.git    (~25GB)"
    [ -d "${TXT_AI_WIKIPEDIA_DIR}/.git" ] && echo "  ${TXT_AI_WIKIPEDIA_DIR}/.git  (~8.4GB)"
    echo ""
    echo "To remove them yourself, run (only if you have what you need):"
    [ -d "${WIKI_DATASET_DIR}/.git" ]     && echo "  rm -rf \"${WIKI_DATASET_DIR}/.git\""
    [ -d "${TXT_AI_WIKIPEDIA_DIR}/.git" ] && echo "  rm -rf \"${TXT_AI_WIKIPEDIA_DIR}/.git\""
    echo ""
    echo "Trade-off: with .git removed you cannot 'git pull' to update."
    echo "To move to a newer dataset snapshot you would re-clone the folder."
    echo "---------------------------------------------------------------"
fi

# Finally: Start the API
echo "---------------------------------------------------------------"
echo "Starting API. If this is the first run, setup may take 10-15 minutes depending on your machine."
echo "Setup time is due to indexing wikipedia article titles into a json file for API speed."
echo "---------------------------------------------------------------"
echo "API Starting..."
python3 start_api.py --database_dir "${DATABASE_DIR}"
