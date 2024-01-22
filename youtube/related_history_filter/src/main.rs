use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::fs::File;
use std::io::{self, BufRead, BufReader, Write};

#[derive(Serialize, Deserialize, Debug)]
struct YouTubeEntry {
    video_title: String,
    video_url: String,
    channel_name: String,
    channel_url: String,
    watch_time: String,
}
fn main() -> io::Result<()> {
    // Read the JSON array
    let file = File::open("../related_history_grabber/target/youtube_watch_history.json")?;
    let reader = BufReader::new(file);
    let entries: Vec<YouTubeEntry> = serde_json::from_reader(reader)?;

    // Read the input.txt file and extract video IDs
    let input_file = File::open("../inputs/input.txt")?;
    let input_reader = BufReader::new(input_file);
    let mut video_ids = HashSet::new();
    for line in input_reader.lines() {
        let line = line?;
        if let Some(id) = extract_video_id(&line) {
            video_ids.insert(id);
        }
    }

    // Find matching indices and expand them
    let mut output_indices = HashSet::new();
    for (i, entry) in entries.iter().enumerate() {
        if let Some(id) = extract_video_id(&entry.video_url) {
            if video_ids.contains(&id) {
                output_indices.extend(i.saturating_sub(2)..=i + 2);
            }
        }
    }

    // Write to output.txt
    let mut output_file = File::create("target/output.txt")?;
    for &index in &output_indices {
        if let Some(entry) = entries.get(index) {
            println!("{}", entry.video_title);
            writeln!(output_file, "{}", entry.video_url)?;
        }
    }

    Ok(())
}

fn extract_video_id(url: &str) -> Option<String> {
    url.split("watch?v=")
        .nth(1) // After "watch?v="
        .and_then(|substr| substr.split('&').next()) // Before any '&' character
        .map(|id| id.to_owned())
}

