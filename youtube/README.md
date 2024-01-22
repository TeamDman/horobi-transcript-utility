# Horobi Transcript Utility - YouTube

Given a list of YouTube URLs, fetch an english transcript for each video and save it to the outputs folder.

It should skip URLs with existing outputs.

Paste a list of links into [`inputs/input.txt`](inputs/input.txt) to get started.

## Requirements

```
youtube-transcript-api
pathlib
tqdm

optional

beautifulsoup4
``````

## YouTube History

To get a list of all the videos you've watched, go to [https://takeout.google.com/](https://takeout.google.com/), select YouTube and download the history.

Interestingly, the output is an HTML file that the browser renders better than VSCode does for it in text form. However, the dev tools don't like the big page.

We want to extract all the videos that are near the ones we want to transcribe. For example, if you have a list of stand-up comedy videos you found by searching your YouTube watch history, there are likely videos you watched around the same time that you also want to transcribe.

Python is also struggling with this 47mb HTML file.