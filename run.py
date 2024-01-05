from youtube_transcript_api import YouTubeTranscriptApi, TranscriptsDisabled, NoTranscriptFound
from pathlib import Path
from tqdm import tqdm

def get_video_id(url):
    # Extract the video ID from the YouTube URL
    if "v=" in url:
        return url.split("v=")[1].split("&")[0]
    return url.rsplit("/", 1)[-1]

def fetch_and_save_transcript(video_id, output_dir):
    transcript_file = output_dir / f"{video_id}.txt"
    translated_file = output_dir / f"{video_id}-translated.txt"
    error_file = output_dir / f"error-{video_id}"

    # Skip if output or error file already exists
    if transcript_file.exists() or translated_file.exists() or error_file.exists():
        print(f"Skipping {video_id} because it already exists")
        return
    try:
        transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)

        transcript = None
        for lang_code in ['en', 'en-US']:
            try:
                transcript = transcript_list.find_transcript([lang_code])
                file_name = transcript_file
                break
            except NoTranscriptFound:
                continue

        if not transcript:
            for t in transcript_list:
                if t.language_code.startswith('en'):
                    transcript = t
                    file_name = transcript_file
                    break

        if not transcript:
            transcript = transcript_list.find_generated_transcript(['en']).translate('en')
            file_name = translated_file

        file_name.write_text(str(transcript.fetch()))

    except (TranscriptsDisabled, NoTranscriptFound):
        error_file.touch()

def main():
    input_file = Path('inputs/input.txt')
    output_dir = Path('outputs')
    output_dir.mkdir(exist_ok=True)

    urls = input_file.read_text().splitlines()

    # Process each URL with a progress bar
    for url in tqdm(urls, desc="Processing videos", unit="video"):
        video_id = get_video_id(url.strip())
        fetch_and_save_transcript(video_id, output_dir)

if __name__ == "__main__":
    main()
