## Contents of this Directory
Any file within this directory (other than the readme) is something that is untested.
Use at your own peril.

To use the below files, pull them into the root directory of the application (with the run_windows.bat file) and then
run them.

Current Contents:
------------------------
**run_linux.sh** - This is an AI translated linux version of the run_windows.bat file. 
I do not have a linux system to test with, so I can't be sure it'll work. If you
have a linux system and want to give it a try, please let me know how it goes. I
do urge you, however, to take caution and look over the file first to ensure that
it doesn't do anything that you aren't comfortable with it doing on your system.

**run_macos.sh** This I have run on my own Mac Studio and it worked EXCEPT for the
git clone call. I need to find a workaround for that. More information in the "KNOWN ISSUE"
section below.


## KNOWN ISSUE:

### MacOS
When running the bash script for MacOS, it tries to git clone the two datasets mentioned above. This works fine on my 
Windows computer, but if you are using the XCode provided git on MacOS then it does not come with git-lfs. 
I tested the script on my Mac, and it only seemed to pull the file headers for the datasets. So instead of 
60GB of dataset files, it pulled down 4KB of dataset files.

The result is that when it tries to start the API, the api complains about a memory issue. That's because it's trying to
read the datasets and failing.

The workaround for Mac users is to manually download the two datasets and put them in their respective folders:
* "wiki-dataset" folder: https://huggingface.co/datasets/NeuML/wikipedia-20240101
* "txtai-wikipedia" folder: https://huggingface.co/NeuML/txtai-wikipedia

The structure for the two datasets in the project, as of 2024-07-28, would look like:
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