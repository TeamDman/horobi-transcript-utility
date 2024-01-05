use indicatif::{ProgressBar, ProgressStyle};
use rayon::prelude::*;
use serde::{Deserialize, Serialize};
use serde_json;
use std::env;
use std::fs::File;
use std::io::{self, BufRead, BufReader, Write};
use std::path::Path;

#[derive(Serialize, Deserialize, Debug)]
struct YouTubeEntry {
    video_title: String,
    video_url: String,
    channel_name: String,
    channel_url: String,
    watch_time: String,
}
fn extract_data(chunk: &str) -> YouTubeEntry {
    let fragment = scraper::Html::parse_fragment(chunk);

    let video_selector =
        scraper::Selector::parse(r#"a[href^="https://www.youtube.com/watch?v="]"#).unwrap();
    let channel_selector =
        scraper::Selector::parse(r#"a[href^="https://www.youtube.com/channel/"]"#).unwrap();

    let video_title = fragment
        .select(&video_selector)
        .next()
        .map(|e| e.inner_html())
        .unwrap_or_default();
    let video_url = fragment
        .select(&video_selector)
        .next()
        .and_then(|e| e.value().attr("href"))
        .unwrap_or_default()
        .to_string();
    let channel_name = fragment
        .select(&channel_selector)
        .next()
        .map(|e| e.inner_html())
        .unwrap_or_default();
    let channel_url = fragment
        .select(&channel_selector)
        .next()
        .and_then(|e| e.value().attr("href"))
        .unwrap_or_default()
        .to_string();

    let content_cell_selector = scraper::Selector::parse(
        "div.content-cell.mdl-cell.mdl-cell--6-col.mdl-typography--body-1",
    )
    .unwrap();
    let content_cell = fragment.select(&content_cell_selector).next().unwrap();

    let watch_time = content_cell
        .children()
        .filter(|n| n.value().is_text())
        .last()
        .map(|n| n.value().as_text().unwrap().trim())
        .unwrap_or_default()
        .to_string();

    YouTubeEntry {
        video_title,
        video_url,
        channel_name,
        channel_url,
        watch_time,
    }
}

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();
    if args.len() != 2 {
        println!("Usage: program <path_to_html_file>");
        return Ok(());
    }

    let path = &args[1];
    let file = File::open(path)?;
    let reader = BufReader::new(file);

    let delimiter = r#"<div class="outer-cell mdl-cell mdl-cell--12-col mdl-shadow--2dp">"#;
    let mut chunks = Vec::new();

    for line in reader.lines().filter_map(Result::ok) {
        if line.contains(delimiter) {
            chunks.extend(
                line.split(delimiter)
                    .skip(1)
                    .map(|s| format!("{}{}", delimiter, s))
            );
        }
    }

    let pb = ProgressBar::new(chunks.len() as u64);
    pb.set_style(ProgressStyle::default_bar()
        .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {pos}/{len} ({eta})").unwrap()
        .progress_chars("=>-"));

    let entries: Vec<YouTubeEntry> = chunks.par_iter()
        .map(|chunk| {
            let data = extract_data(chunk);
            pb.inc(1);
            data
        })
        .collect();

    pb.finish_with_message("Processing complete");

    // Serialize and write to file
    let output_path = Path::new("target/youtube_watch_history.json");
    let mut output_file = File::create(output_path)?;
    write!(output_file, "{}", serde_json::to_string_pretty(&entries)?)?;

    println!("Data has been written to {:?}", output_path);

    Ok(())
}