//! Shortcuts launcher using `rofi`.
//!
//! Reads a TOML file at `~/.shortcuts`, collects commands from the file,
//! also augments with scripts found in a local `home/bin` (if discoverable)
//! and `~/bin`, shows choices in `rofi` and runs the selected command via the
//! user's shell without blocking.
use rofi;
use std::collections::BTreeMap;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

/// Entry point. Loads `~/.shortcuts`, augments with scripts, shows rofi menu,
/// and runs the selected command without blocking.
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let home = env::var("HOME").map(PathBuf::from)?;
    let shortcuts_file = home.join(".shortcuts");

    let mut parsed = if shortcuts_file.exists() {
        load_shortcuts(&shortcuts_file)?
    } else {
        eprintln!(
            "Warning: shortcuts file not found at {} — continuing without it",
            shortcuts_file.display()
        );
        BTreeMap::new()
    };

    // // Try to discover a local `home/bin` inside the repo layout by walking
    // // ancestors of the executable and checking for an `home/bin` directory.
    // if let Some(local_bin) = find_repo_home_bin() {
    //     add_executable_scripts(&mut parsed, &local_bin, "Local script")?;
    // }

    // Add ~/bin scripts
    let user_bin = home.join("bin");
    if user_bin.exists() {
        add_executable_scripts(&mut parsed, &user_bin, "Bin script")?;
    }

    if parsed.is_empty() {
        eprintln!("Warning: no shortcuts available after loading files and scripts");
        return Ok(());
    }

    let keys: Vec<String> = parsed.keys().cloned().collect();

    match run_rofi(&keys) {
        Ok(Some(idx)) => {
            if let Some((_, cmd)) = parsed.iter().nth(idx) {
                run_shortcut(cmd);
            }
        }
        Ok(None) => { /* cancelled or not found */ }
        Err(e) => eprintln!("Rofi error: {}", e),
    }

    Ok(())
}

/// Load shortcuts from a TOML file into a map of `label -> command`.
fn load_shortcuts(path: &Path) -> Result<BTreeMap<String, String>, Box<dyn std::error::Error>> {
    let contents = fs::read_to_string(path)?;
    let toml_value: toml::Value = toml::from_str(&contents)?;

    let mut parsed: BTreeMap<String, String> = BTreeMap::new();
    if let Some(table) = toml_value.as_table() {
        for (section, items) in table {
            if let Some(items_table) = items.as_table() {
                for (name, command_val) in items_table {
                    let label = format!("{}: {}", section, name);
                    let cmd = command_val
                        .as_str()
                        .map(|s| s.to_string())
                        .unwrap_or_else(|| command_val.to_string());
                    parsed.insert(label, cmd);
                }
            }
        }
    }

    Ok(parsed)
}

/// Add executable scripts from `dir` to `map` using the given `prefix`.
fn add_executable_scripts(
    map: &mut BTreeMap<String, String>,
    dir: &Path,
    prefix: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    if !dir.exists() {
        return Ok(());
    }

    for entry in fs::read_dir(dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_file() {
            #[cfg(unix)]
            {
                use std::os::unix::fs::PermissionsExt;
                if path.metadata()?.permissions().mode() & 0o111 == 0 {
                    continue;
                }
            }

            if let Some(stem) = path.file_stem().and_then(|s| s.to_str()) {
                map.insert(format!("{}: {}", prefix, stem), path.to_string_lossy().to_string());
            }
        }
    }

    Ok(())
}


/// Show a `rofi` menu for `keys` and return the selected index (non-blocking
/// behavior is handled elsewhere).
fn run_rofi(keys: &[String]) -> Result<Option<usize>, rofi::Error> {
    let mut r = rofi::Rofi::new(keys);
    r.lines(15);
    r.prompt("Shortcut");
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

/// Run the selected command via the user's shell without blocking.
fn run_shortcut(cmd: &str) {
    // Launch via sh -c so we accept shell commands as strings (like the
    // original python script which used `shell=True`). Use `spawn` so the
    // launcher doesn't block.
    let _ = Command::new("sh").arg("-c").arg(cmd).spawn();
}
