//! Bookmarks launcher using `rofi`.
//!
//! Reads a TOML file at `~/.bookmarks`, presents an indexed menu via `rofi`,
//! and opens the chosen URL with `xdg-open`.
use rofi;
use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::Command;

/// Entry point.
///
/// Loads bookmarks from `~/.bookmarks`, displays them in a `rofi` menu (up to
/// 15 visible lines), and opens the selected URL with `xdg-open`.
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let home = env::var("HOME").map(PathBuf::from)?;
    let bookmarks_file = home.join(".bookmarks");

    if !bookmarks_file.exists() {
        eprintln!(
            "No known bookmark was found. Add them to the {} file",
            bookmarks_file.display()
        );
        std::process::exit(1);
    }

    let parsed = load_bookmarks(&bookmarks_file)?;

    if parsed.is_empty() {
        eprintln!("No bookmarks found in {}", bookmarks_file.display());
        std::process::exit(1);
    }

    let keys: Vec<String> = parsed.iter().map(|(k, _)| k.clone()).collect();

    match run_rofi(&keys) {
        Ok(Some(idx)) => {
            if let Some((_, url)) = parsed.get(idx) {
                open_url(url);
            }
        }
        Ok(None) => { /* cancelled or not found */ }
        Err(e) => eprintln!("Rofi error: {}", e),
    }

    Ok(())
}

/// Load bookmarks from a TOML file.
///
/// Returns a vector of `(label, url)` pairs where `label` is "section: name".
fn load_bookmarks(path: &PathBuf) -> Result<Vec<(String, String)>, Box<dyn std::error::Error>> {
    let contents = fs::read_to_string(path)?;
    let toml_value: toml::Value = toml::from_str(&contents)?;

    let mut parsed: Vec<(String, String)> = Vec::new();
    if let Some(table) = toml_value.as_table() {
        for (section, items) in table {
            if let Some(items_table) = items.as_table() {
                for (name, bookmark_val) in items_table {
                    let label = format!("{}: {}", section, name);
                    let url = bookmark_val
                        .as_str()
                        .map(|s| s.to_string())
                        .unwrap_or_else(|| bookmark_val.to_string());
                    parsed.push((label, url));
                }
            }
        }
    }

    Ok(parsed)
}

/// Show a `rofi` menu for `keys` and return the selected index.
///
/// Returns `Ok(Some(index))` on selection, `Ok(None)` when cancelled or not
/// found, and `Err` on other `rofi` errors.
fn run_rofi(keys: &[String]) -> Result<Option<usize>, rofi::Error> {
    let mut r = rofi::Rofi::new(keys);
    r.lines(15);
    r.prompt("Bookmarks");
    match r.run_index() {
        Ok(i) => Ok(Some(i)),
        Err(rofi::Error::Interrupted) => Ok(None),
        Err(rofi::Error::NotFound) => {
            eprintln!("User input was not found");
            Ok(None)
        }
        Err(e) => Err(e),
    }
}

/// Open the given `url` using `xdg-open`.
fn open_url(url: &str) {
    let _ = Command::new("xdg-open").arg(url).spawn();
}
