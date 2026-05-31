# Offline Wikipedia Text API

Welcome to the Offline Wikipedia Text API! This project provides a simple way to search and retrieve Wikipedia articles from an offline dataset using the `txtai` library. The API offers three endpoints to get full articles by title, full articles by search prompt, and summary snippets of articles by search prompt.

## Features

- **Offline Access**: All Wikipedia article texts are stored offline, allowing for fast and private access.
- **Search Functionality**: Uses the powerful `txtai` library to search for articles by prompts.

## Requirements

* This project requires a minimum of ~70GB of free disk space during installation (the two datasets together are ~67GB after download). After the install completes you can optionally delete the `.git` folders inside each dataset directory to reclaim roughly half of that space.
* This project utilizes Git to pull down the needed datasets (https://git-scm.com/downloads)
  * This can be skipped by downloading the datasets into their respective folders in the project directory.
    * "wiki-dataset" folder: https://huggingface.co/datasets/NeuML/wikipedia-20260401
    * "txtai-wikipedia" folder: https://huggingface.co/NeuML/txtai-wikipedia
  * The existence of the two dataset folders should skip the git calls, bypassing their need.
* This project is a Python project, and requires Python to run.

## Important Notes

Scripts are provided for Linux (`run_linux.sh`), MacOS (`run_macos.sh`), and Windows (`run_windows.bat`). Each one runs a
pre-flight check for `git`, `git-lfs`, and `python` and will stop with an instructional error if any are missing, so a
missing Git LFS install (a common issue on macOS, where the Xcode-supplied git does not include git-lfs) is caught up
front instead of silently producing broken pointer files.

During first run, the app will first download about 67GB worth of datasets (see above), and then will take about 10-15
minutes to do some indexing. This will only occur on first run; just let it do its thing. If, for any reason, you kill
the process halfway through and need to redo it, you can simply delete the "title_to_index.json" file and it will be
recreated. You can also delete the "wiki-dataset" and "txtai-wikipedia" folders to redownload.

If you're dataset savvy and want to make new, more up to date, datasets to use with this- NeuML's Hugging Face repos give
instructions on how.

This project relies heavily on [txtai](https://github.com/neuml/txtai/), which uses various libraries to download
and utilize small models itself for searching. Please see that project for an understanding of what gets downloaded
and where.

> NOTE: There is a known issue within txtai on Windows 11 and MacOS with the following
> error: `Error #15: Initializing libomp.dylib, but found libomp.dylib already initialized.` You can see the issues and
> the various workarounds here: [txt issues](https://github.com/neuml/txtai/issues?q=is%3Aissue%20state%3Aclosed%20KMP_DUPLICATE_LIB_OK)
>
> On Mac, I personally use `KMP_DUPLICATE_LIB_OK=TRUE bash run_macos.sh`, setting the environment variable suggested in the
> error, and it seems to work alright.
>
> For a little while I had this set in the .py file, but given the warning that it could result in
> unexpected behavior within the app, I thought it better to let the users decide for themselves rather than having it where they can't see it.
> If you run into this issue, you should look over the issues link above for workarounds suggested there.
>
> -Socg


1. **Clone the Repository**
    ```sh
    git clone https://github.com/SomeOddCodeGuy/OfflineWikipediaTextApi
    cd OfflineWikipediaTextApi
    ```
### Installation via Scripts

2. **Run the API** 
    - **For Windows**:
    
        *To run with the default configuration (current directory as the base for datasets):*
        ```cmd
        run_windows.bat
        ```
        *To run with a custom directory for the wiki data (parent of `wiki-dataset` and `txtai-wikipedia`):*
        ```cmd
        run_windows.bat --database_dir path\to\datadirs
        ```
    
    - **For Linux**:
        
        *To run with the default configuration (current directory as the base for datasets):*
        ```sh
        ./run_linux.sh
        ```
        *Or with custom directory for the wiki data (parent of wiki-dataset and txtai-wikipedia):*
        ```sh
        ./run_linux.sh --database_dir path/to/datadirs
        ```

    - **For MacOS**:

        ```sh
        ./run_macos.sh
        ```
        *Or with a custom data directory:*
        ```sh
        ./run_macos.sh --database_dir path/to/datadirs
        ```
        On MacOS, if you hit the `libomp.dylib already initialized` error noted above, prefix the command with the
        workaround env var: `KMP_DUPLICATE_LIB_OK=TRUE ./run_macos.sh`.

### Manual Installation

1) Pull down the code from https://github.com/SomeOddCodeGuy/OfflineWikipediaTextApi
   `git clone https://github.com/SomeOddCodeGuy/OfflineWikipediaTextApi`
2) Open command prompt and navigate to the folder containing the code
   `cd OfflineWikipediaTextApi`
3) Optional: create a python virtual environment.
   1) Windows: `python -m venv venv`
   2) MacOS: `python3 -m venv venv`
   3) Linux: `python -m venv venv`
4) Optional: activate python virtual environment.
   1) Windows: `venv\Scripts\activate`
   2) MacOS/Linux: `venv/bin/activate`
   3) Fish shell: `venv/bin/activate.fish`
5) Pip install the requirements from requirements.txt
   1) Windows: `python -m pip install -r requirements.txt`
   2) MacOS: `python3 -m pip install -r requirements.txt`
   3) Linux: `python -m pip install -r requirements.txt`
6) Pull down the two needed datasets into the following folders within the project folder:
   1) `wiki-dataset` folder: https://huggingface.co/datasets/NeuML/wikipedia-20260401 
        You would need git-lfs installed to clone it
        Windows: https://git-lfs.com/
        Mac: https://git-lfs.com/ or `brew install git-lfs`
        Linux Ubuntu/Debian: `sudo apt install git-lfs`
        Then run:
        `git lfs install`
        `git clone https://huggingface.co/datasets/NeuML/wikipedia-20260401`
        The dataset requieres to be called `wiki-dataset` so rename it:
        `mv wikipedia-20260401 wiki-dataset`      
   2) `txtai-wikipedia` folder: https://huggingface.co/NeuML/txtai-wikipedia
        `git clone https://huggingface.co/NeuML/txtai-wikipedia`
   3) See project structure below to make sure you did it right
7) Run start_api.py
   1) Windows: python start_api.py
   2) MacOS/Linux: python3 start_api.py

Step 7 will take between 10-15 minutes on the first run only. This is to index some stuff for future runs. After that
it should be fast.

Your project should look like this:

```plain

- OfflineWikipediaTextApi/
   - wiki-dataset/
       - train/
           - data-00000-of-00044.arrow
           - data-00001-of-00044.arrow
           - ...
       - pageviews.sqlite
       - README.md
   - txtai-wikipedia
       - config.json
       - documents
       - embeddings
       - README.md
   - start_api.py
   - ...
```


## Configuration

The API configuration is managed through the `config.json` file:

```json
{
    "host": "127.0.0.1",
    "port": 5728,
    "verbose": false
}
```

The "verbose" is for changing whether the API library uvicorn outputs all logs vs just warning logs. Set to 
warning by default.

The "host" defaults to `127.0.0.1` so the API is only reachable from the same machine. If you need to access it
from other devices on your LAN, change this to `0.0.0.0`. Only do that on a trusted network — this API has no
authentication and exposing it on a public network would let anyone query your dataset.

There are also three OPTIONAL caps you can set in `config.json` if you want defense-in-depth limits on incoming
requests. None of them are enforced unless you add them, so the default behavior is unchanged:

```json
{
    "max_prompt_length": 500,
    "max_title_length": 500,
    "max_num_results": 200
}
```

If a request exceeds a configured cap, the API returns HTTP 400. Leave any key out (or do not add this section at
all) to disable that cap entirely.

## Endpoints

### 1. Get Top Article by Prompt Query

**Endpoint**: `/top_article`

#### Example cURL Command
```sh
curl -G "http://localhost:5728/top_article" --data-urlencode "prompt=Quantum Physics" --data-urlencode "percentile=0.5" --data-urlencode "num_results=10"
```

`NOTE: The num_results for top_article is the number of results to compare to find the top article. This endpoint
always returns a single result, but the higher your num_results the more articles it will compare in an attempt to
find the top scoring`

### 2. Get Top N Articles by Prompt Query

**Endpoint**: `/top_n_articles`

#### Example cURL Command
```sh
curl -G "http://localhost:5728/top_n_articles" --data-urlencode "prompt=quantum physics and gravity" --data-urlencode "percentile=0.4" --data-urlencode "num_results=80" --data-urlencode "num_top_articles=6"
```

`NOTE: The num_results for top_n_articles is the number of results to compare to find the top N articles, where num_top_articles is N.
The output articles are given in order of score, where largest scored article is first by default (descending).
If percentile, num_results, and num_top_articles are not specified, then default values of 0.5, 20, and 8 will be used respectively.
num_top_articles can also be negative, where a negative number will give the results as ascending score rather then descending - this is useful
when context is truncated by LLM.`

### 3. Get Full Article by Title

**Endpoint**: `/articles/{title}`

#### Example cURL Command
```sh
curl -X GET "http://localhost:5728/articles/Applications%20of%20quantum%20mechanics"
```

### 4. Get Wiki Summaries by Prompt Query

**Endpoint**: `/summaries`

#### Example cURL Command
```sh
curl -G "http://localhost:5728/summaries" --data-urlencode "prompt=Quantum Physics" --data-urlencode "percentile=0.5" --data-urlencode "num_results=1"
```

### 5. Get Full Wiki Articles by Prompt Query

**Endpoint**: `/articles`

#### Example cURL Command
```sh
curl -G "http://localhost:5728/articles" --data-urlencode "prompt=Artificial Intelligence" --data-urlencode "percentile=0.5" --data-urlencode "num_results=1"
```

## License

This project is licensed under the Apache 2.0 License. See the `LICENSE` file for more details.

### Third-Party Licenses

This project imports dependencies in the requirements.txt:

- [Uvicorn](https://github.com/encode/uvicorn/)
- [FastAPI](https://github.com/tiangolo/fastapi/)
- [Datasets](https://github.com/huggingface/datasets/)
- [Txtai](https://github.com/neuml/txtai/)
- [Faiss-cpu](https://github.com/facebookresearch/faiss/)
- [Colorama](https://github.com/tartley/colorama/)
- [NumPy](https://github.com/numpy/numpy/)
- [PyTorch](https://github.com/pytorch/pytorch/)
- [Accelerate](https://github.com/huggingface/accelerate/)

Please see ThirdParty-Licenses directory for details on their licenses.

## License and Copyright

    OfflineWikipediaTextApi
    Copyright (C) 2024 Christopher Smith
