# Offline Wikipedia Text API

Welcome to the Offline Wikipedia Text API! This project provides a simple way to search and retrieve Wikipedia articles from an offline dataset using the `txtai` library. The API offers three endpoints to get full articles by title, full articles by search prompt, and summary snippets of articles by search prompt.

## Features

- **Offline Access**: All Wikipedia article texts are stored offline, allowing for fast and private access.
- **Search Functionality**: Uses the powerful `txtai` library to search for articles by prompts.

## Requirements

* This project requires a minimum of 60GB of hard disk space to store the related datasets
* This project utilizes Git to pull down the needed datasets (https://git-scm.com/downloads)
  * This can be skipped by downloading the datasets into their respective folders in the project directory.
    * "wiki-dataset" folder: https://huggingface.co/datasets/NeuML/wikipedia-20240101
    * "txtai-wikipedia" folder: https://huggingface.co/NeuML/txtai-wikipedia
  * The existence of the two dataset folders should skip the git calls, bypassing their need.
* This project is a Python project, and requires Python to run.

## Important Notes

During first run, the app will first download about 60GB worth of datasets (see above), and then will take about 10-15
minutes to do some indexing. This will only occur on first run; just let it do its thing. If, for any reason, you kill
the process halfway through and need to redo it, you can simply delete the "title_to_index.json" file and it will be
recreated. You can also delete the "wiki-dataset" and "txtai-wikipedia" folders to redownload.

If you're dataset savvy and want to make new, more up to date, datasets to use with this- NeuML's huggingface repos give
instructions on how.

This project relies heavily on [txtai](https://github.com/neuml/txtai/), which uses various libraries to download
and utilize small models itself for searching. Please see that project for an understanding of what gets downloaded
and where.



1. **Clone the Repository**
    ```sh
    git clone https://github.com/SomeOddCodeGuy/OfflineWikipediaTextApi
    cd OfflineWikipediaTextApi
    ```
### Installation via Scripts

2. **Run the API**
    - For Windows:
        ```sh
        run_windows.bat
        ```
    
    - For Linux or MacOS:
      - There are currently scripts within "Untested", though there is a known issue for MacOS related to git. A workaround 
        is presented in the README for that folder.

### Manual Installation

1) Pull down the code from https://github.com/SomeOddCodeGuy/OfflineWikipediaTextApi
   `git clone https://github.com/SomeOddCodeGuy/OfflineWikipediaTextApi`
2) Open command prompt and navigate to the folder containing the code
   `cd OfflineWikipediaTextApi`
3) Optional: create a python virtual environment.
   1) Windows: `python -m venv venv`
   2) MacOS/Linux: `python3 -m venv venv`
4) Optional: activate python virtual environment.
   1) Windows: `venv\Scripts\activate`
   2) MacOS/Linux: `venv/bin/activate`
   3) Fish shell: `venv/bin/activate.fish`
5) Pip install the requirements from requirements.txt
   1) Windows: `python -m pip install -r requirements.txt`
   2) Linux/MacOS: `python -m pip install -r requirements.txt`
6) Pull down the two needed datasets into the following folders within the project folder:
   1) `wiki-dataset` folder: https://huggingface.co/datasets/NeuML/wikipedia-20240101
       You would need git-lfs installed to clone it
       Windows: https://git-lfs.com/
       Mac: https://git-lfs.com/ or `brew install git-lfs`
       Linux Ubuntu/Debian: `sudo apt install git-lfs`
       Then run:
         `git lfs install`
         `git clone https://huggingface.co/datasets/NeuML/wikipedia-20240101`
       The dataset requieres to be called `wiki-dataset` so rename it:
         `mv wikipedia-20240101 wiki-dataset`      
   3) `txtai-wikipedia` folder: https://huggingface.co/NeuML/txtai-wikipedia
       `git clone https://huggingface.co/NeuML/txtai-wikipedia`
   5) See project structure below to make sure you did it right
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
    "host": "0.0.0.0",
    "port": 5728,
    "verbose": false
}
```

The "verbose" is for changing whether the API library uvicorn outputs all logs vs just warning logs. Set to 
warning by default. 

## Endpoints

### 1. Get Full Article by Title

**Endpoint**: `/articles/{title}`

#### Example cURL Command
```sh
curl -X GET "http://localhost:5728/articles/Applications%20of%20quantum%20mechanics"
```

### 2. Get Wiki Summaries by Prompt

**Endpoint**: `/summaries`

#### Example cURL Command
```sh
curl -G "http://localhost:5728/summaries" --data-urlencode "prompt=Quantum Physics" --data-urlencode "percentile=0.5" --data-urlencode "num_results=1"
```

### 3. Get Full Wiki Articles by Prompt

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

Please see ThirdParty-Licenses directory for details on their licenses.

## License and Copyright

    OfflineWikipediaTextApi
    Copyright (C) 2024 Christopher Smith
