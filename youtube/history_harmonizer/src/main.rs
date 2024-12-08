use colored::*;
use eyre::Result;
use rand::seq::SliceRandom; // For random selection
use serde::Deserialize;
use std::cmp::Ordering;
use std::collections::HashMap;
use std::collections::HashSet;
use std::fs;
use std::path::Path;
use std::path::PathBuf;

#[derive(Debug, Deserialize)]
struct HistoryEntry {
    time: String, // Keep as a string for exact JSON matching
    title: String,
    // #[serde(rename = "titleUrl")]
    // title_url: Option<String>,
}

fn main() -> Result<()> {
    color_eyre::install()?;

    let downloads_folder = get_downloads_folder()?;
    let compare_folder = downloads_folder.join("compare");

    // Define file paths relative to the compare folder
    let old_search_history_path = compare_folder.join("old-search-history.json");
    let new_search_history_path = compare_folder.join("new-search-history.json");
    let old_watch_history_path = compare_folder.join("old-watch-history.json");
    let new_watch_history_path = compare_folder.join("new-watch-history.json");

    // Collect errors for each validation
    let mut errors = Vec::new();

    // Validate each pair of old and new files
    if let Err(err) = validate_history(
        &old_search_history_path,
        &new_search_history_path,
        "Search History",
    ) {
        errors.push(err);
    }

    if let Err(err) = validate_history(
        &old_watch_history_path,
        &new_watch_history_path,
        "Watch History",
    ) {
        errors.push(err);
    }

    // Report all errors at the end
    if !errors.is_empty() {
        println!("\n{}", "Validation completed with errors:".red().bold());
        for (i, err) in errors.iter().enumerate() {
            println!("{}. {}", (i + 1).to_string().cyan(), err);
        }
        eyre::bail!(
            "{}",
            "Validation failed for one or more history files".red()
        );
    }

    println!(
        "{}",
        "Validation completed successfully. No issues found.".green()
    );
    Ok(())
}
fn validate_history(old_path: &Path, new_path: &Path, history_type: &str) -> Result<()> {
    println!(
        "{} {} {} {} {}",
        "Validating".blue(),
        history_type.bold(),
        "between".blue(),
        old_path.display().to_string().yellow(),
        new_path.display().to_string().yellow()
    );

    // Load and parse the JSON files
    let old_data: Vec<HistoryEntry> = load_history_file(old_path)?;
    let mut new_data: Vec<HistoryEntry> = load_history_file(new_path)?;

    // Ensure `new_data` is sorted by `time`
    new_data.sort_by(|a, b| a.time.cmp(&b.time));

    // Convert new data to a hashmap keyed by timestamp
    let new_map: HashSet<_> = new_data.iter().map(|entry| &entry.time).collect();

    let missing_entries: Vec<&HistoryEntry> = old_data
        .iter()
        .filter(|old_entry| !new_map.contains(&old_entry.time))
        .collect();

    if !missing_entries.is_empty() {
        println!(
            "{} {} {} {}",
            "Some entries are missing in the new".yellow(),
            history_type.cyan(),
            "file:".yellow(),
            format!("{} entries total", missing_entries.len()).red()
        );

        // Group by year and sort years
        let mut summary: Vec<(&str, Vec<&HistoryEntry>)> = missing_entries
            .iter()
            .fold(HashMap::new(), |mut acc, entry| {
                let year = &entry.time[..4]; // Extract year from timestamp
                acc.entry(year).or_insert_with(Vec::new).push(*entry);
                acc
            })
            .into_iter()
            .collect();

        summary.sort_by_key(|&(year, _)| year);

        // Print the entries by year
        for (year, entries) in summary {
            let example = entries.choose(&mut rand::thread_rng()).unwrap();
            println!(
                "\n{} {}\n  {}: {}\n  {}: \"{}\"",
                "Example missing entry from".blue(),
                year.cyan(),
                "Timestamp".yellow(),
                example.time.yellow(),
                "Title".green(),
                example.title.green()
            );
            if let Some((before, after)) = find_nearest(&new_data, &example.time) {
                println!(
                    "    {}: {}\n    {}: {}",
                    "Nearest before".bold().blue(),
                    before.time.yellow(),
                    "Nearest after".bold().blue(),
                    after.time.yellow()
                );
            } else {
                println!("    {}", "No nearby entries found in the new file.".red());
            }

            if entries.len() > 1 {
                println!(
                    "  {} {} {} {}.",
                    "Plus".bright_black(),
                    (entries.len() - 1).to_string().red(),
                    "more entries are missing from".bright_black(),
                    year
                );
            }
        }

        let total_missing = missing_entries.len();
        println!(
            "\n{} {}",
            "Summary:".green(),
            format!(
                "{} total missing entries in the {} file.",
                total_missing.to_string().cyan(),
                history_type.cyan()
            )
        );

        eyre::bail!(
            "{} {}",
            "Some".yellow(),
            format!("{} entries are missing in the new file!", history_type).red()
        );
    }

    println!("{} {}", history_type.cyan(), "validation passed.".green());
    Ok(())
}

fn find_nearest<'a>(
    sorted_entries: &'a [HistoryEntry],
    target_time: &String,
) -> Option<(&'a HistoryEntry, &'a HistoryEntry)> {
    let mut before: Option<&HistoryEntry> = None;
    let mut after: Option<&HistoryEntry> = None;

    for entry in sorted_entries {
        match entry.time.cmp(target_time) {
            Ordering::Less => before = Some(entry),
            Ordering::Equal => return None, // Exact match; no need to find nearest
            Ordering::Greater => {
                after = Some(entry);
                break;
            }
        }
    }

    match (before, after) {
        (Some(b), Some(a)) => Some((b, a)),
        (Some(b), None) => Some((b, b)), // Only before exists
        (None, Some(a)) => Some((a, a)), // Only after exists
        _ => None,                       // No entries found
    }
}

fn load_history_file<T: for<'de> Deserialize<'de>>(path: &Path) -> Result<Vec<T>> {
    let content = fs::read_to_string(path)
        .map_err(|e| eyre::eyre!("Failed to read file {}: {}", path.display(), e))?;
    let entries: Vec<T> = serde_json::from_str(&content)
        .map_err(|e| eyre::eyre!("Failed to parse JSON in file {}: {}", path.display(), e))?;
    Ok(entries)
}

fn get_downloads_folder() -> Result<PathBuf> {
    if let Some(downloads_dir) = dirs::download_dir() {
        Ok(downloads_dir)
    } else {
        eyre::bail!("Could not find the Downloads folder");
    }
}
