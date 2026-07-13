use clap::{Parser, Subcommand};
use std::env;
use std::io::Write;
use std::process::{Command, Stdio};

/// Sink/source names containing any of these substrings (case-insensitive) are excluded.
const IGNORED_SINKS: &[&str] = &[
    "Dell Universal Dock",
    // HDMI / DisplayPort passthrough outputs
    "HDMI",
    // secondary chat-mix sink; mic lives in SOURCES
    "SteelSeries Arctis 7 Chat",
];
const IGNORED_SOURCES: &[&str] = &["Dell Universal Dock"];

/// Tokens filtered out when scoring sink-source name similarity (vendor/hardware prefixes).
const SCORE_NOISE_TOKENS: &[&str] = &["sof-soundwire"];

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand, Debug)]
enum Commands {
    /// Open a rofi picker to select an audio device (sets both sink and matched source)
    Switch,
    /// Open two rofi pickers: choose input (source) first, then output (sink) independently
    Manual,
    /// Print i3blocks-compatible output (full, short, color)
    I3,
}

struct AudioDevice {
    id: String,
    name: String,
    is_active: bool,
}

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Some(Commands::Switch) => {
            if let Err(e) = open_paired_picker() {
                eprintln!("Error: {}", e);
            }
        }
        Some(Commands::Manual) => {
            if let Err(e) = open_manual_picker() {
                eprintln!("Error: {}", e);
            }
        }
        Some(Commands::I3) => {
            match env::var("BLOCK_BUTTON").ok().as_deref() {
                Some("1") => { let _ = open_paired_picker(); }
                Some("3") => { let _ = open_manual_picker(); }
                _ => {}
            }

            let status = run_cmd("wpctl", &["status"]).unwrap_or_default();
            let sinks = parse_sinks(&status);
            if let Some(active) = sinks.iter().find(|d| d.is_active) {
                print_i3(&active.name, "", "");
            } else {
                print_i3("-", "", "");
            }
        }
        None => {
            let status = run_cmd("wpctl", &["status"]).unwrap_or_default();
            let sinks = parse_sinks(&status);
            let sources = parse_sources(&status);

            if let Some(sink) = sinks.iter().find(|d| d.is_active) {
                println!("Current default sink: {} (id {})", sink.name, sink.id);
            } else {
                println!("No active sink found");
            }

            if let Some(source) = sources.iter().find(|d| d.is_active) {
                println!("Current default source: {} (id {})", source.name, source.id);
            } else {
                println!("No active source found");
            }
        }
    }
}

/// Open two sequential rofi pickers: first choose source (input), then sink (output).
/// Each picker is independent — cancelling either aborts the whole operation.
fn open_manual_picker() -> Result<(), String> {
    let status = run_cmd("wpctl", &["status"])?;
    let sinks = parse_sinks(&status);
    let sources = parse_sources(&status);

    if sources.is_empty() {
        return Err("No audio sources found".to_string());
    }
    if sinks.is_empty() {
        return Err("No audio sinks found".to_string());
    }

    let source_names: Vec<String> = sources.iter().map(|d| display_name(&d.name)).collect();
    let src_idx = match rofi_select(&source_names, "Input") {
        None => return Ok(()),
        Some(i) => i,
    };

    let sink_names: Vec<String> = sinks.iter().map(|d| display_name(&d.name)).collect();
    let sink_idx = match rofi_select(&sink_names, "Output") {
        None => return Ok(()),
        Some(i) => i,
    };

    run_cmd("wpctl", &["set-default", &sources[src_idx].id])?;
    run_cmd("wpctl", &["set-default", &sinks[sink_idx].id])?;
    Ok(())
}

/// Open a rofi picker listing available sinks; on selection set the chosen sink and its
/// paired source as the system defaults.
fn open_paired_picker() -> Result<(), String> {
    let status = run_cmd("wpctl", &["status"])?;
    let sinks = parse_sinks(&status);
    let sources = parse_sources(&status);
    let pairings = pair_sources(&sinks, &sources);

    if sinks.is_empty() {
        return Err("No audio sinks found".to_string());
    }

    let display_names: Vec<String> = sinks.iter().map(|d| display_name(&d.name)).collect();

    match rofi_select(&display_names, "Audio") {
        None => Ok(()),
        Some(idx) => {
            run_cmd("wpctl", &["set-default", &sinks[idx].id])?;
            if let Some(src_idx) = pairings[idx] {
                run_cmd("wpctl", &["set-default", &sources[src_idx].id])?;
            }
            Ok(())
        }
    }
}

/// Pipe `options` to `rofi -dmenu` and return the selected 0-based index, or None if
/// the user cancelled or rofi could not be launched.
fn rofi_select(options: &[String], prompt: &str) -> Option<usize> {
    let input = options.join("\n");

    let mut child = Command::new("rofi")
        .args(["-dmenu", "-i", "-p", prompt, "-format", "i"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .ok()?;

    {
        let mut stdin = child.stdin.take()?;
        let _ = stdin.write_all(input.as_bytes());
        // stdin dropped here → EOF sent to rofi
    }

    let output = child.wait_with_output().ok()?;
    if !output.status.success() {
        return None;
    }

    String::from_utf8_lossy(&output.stdout)
        .trim()
        .parse::<usize>()
        .ok()
}

/// Parse sinks from `wpctl status`, excluding ignored devices.
fn parse_sinks(status: &str) -> Vec<AudioDevice> {
    parse_devices_in_section(status, "Sinks", false)
        .into_iter()
        .filter(|d| !is_ignored(&d.name, IGNORED_SINKS))
        .collect()
}

/// Parse sources from `wpctl status`, excluding monitor loopbacks and ignored devices.
fn parse_sources(status: &str) -> Vec<AudioDevice> {
    parse_devices_in_section(status, "Sources", true)
        .into_iter()
        .filter(|d| !is_ignored(&d.name, IGNORED_SOURCES))
        .collect()
}

fn is_ignored(name: &str, patterns: &[&str]) -> bool {
    let lower = name.to_lowercase();
    patterns.iter().any(|p| lower.contains(&p.to_lowercase()))
}

/// Parse device entries from a named section of `wpctl status` output.
/// If `exclude_monitors` is true, entries whose name contains "Monitor of" are dropped.
fn parse_devices_in_section(
    status: &str,
    section: &str,
    exclude_monitors: bool,
) -> Vec<AudioDevice> {
    let mut devices = Vec::new();
    let mut in_section = false;
    let section_header = format!("{}:", section);

    for line in status.lines() {
        // Detect section start (e.g. " ├─ Sinks:")
        if line.contains(&section_header) {
            in_section = true;
            continue;
        }

        // Detect section end: any new box-drawing section header (e.g. " ├─ Sink endpoints:")
        if in_section && (line.contains("├─") || line.contains("└─")) {
            break;
        }

        if !in_section || !line.contains('.') {
            continue;
        }

        if let Some(name) = extract_name_from_line(line) {
            if exclude_monitors && name.contains("Monitor of") {
                continue;
            }
            if let Some(id) = extract_first_number(line) {
                devices.push(AudioDevice {
                    id,
                    name,
                    is_active: line.contains('*'),
                });
            }
        }
    }

    devices
}

/// For each sink, return the index of the best-matching source (greedy token similarity).
/// Sinks with no score-positive match are assigned leftover sources in list order (fallback).
fn pair_sources(sinks: &[AudioDevice], sources: &[AudioDevice]) -> Vec<Option<usize>> {
    let mut scores: Vec<(usize, usize, usize)> = sinks
        .iter()
        .enumerate()
        .flat_map(|(si, sink)| {
            sources.iter().enumerate().filter_map(move |(ri, source)| {
                let s = token_similarity(&sink.name, &source.name);
                if s > 0 { Some((si, ri, s)) } else { None }
            })
        })
        .collect();
    scores.sort_by(|a, b| b.2.cmp(&a.2));

    let mut result: Vec<Option<usize>> = vec![None; sinks.len()];
    let mut sink_used = vec![false; sinks.len()];
    let mut source_used = vec![false; sources.len()];

    // Phase 1: greedy high-score assignment
    for (si, ri, _) in &scores {
        if !sink_used[*si] && !source_used[*ri] {
            result[*si] = Some(*ri);
            sink_used[*si] = true;
            source_used[*ri] = true;
        }
    }

    // Phase 2: assign leftover sources to unmatched sinks in list order
    let leftover_sources: Vec<usize> = (0..sources.len()).filter(|&i| !source_used[i]).collect();
    let mut leftover_idx = 0;
    for (si, used) in sink_used.iter().enumerate() {
        if !used && leftover_idx < leftover_sources.len() {
            result[si] = Some(leftover_sources[leftover_idx]);
            leftover_idx += 1;
        }
    }

    result
}

/// Score two device names by longest common token prefix (≥4 chars), ignoring noise tokens.
fn token_similarity(a: &str, b: &str) -> usize {
    fn significant_tokens(s: &str) -> Vec<String> {
        s.split_whitespace()
            .filter(|t| {
                let tl = t.to_lowercase();
                tl.len() >= 4 && !SCORE_NOISE_TOKENS.iter().any(|&n| tl == n.to_lowercase())
            })
            .map(|t| t.to_lowercase())
            .collect()
    }

    let tokens_a = significant_tokens(a);
    let tokens_b = significant_tokens(b);

    tokens_a
        .iter()
        .flat_map(|ta| {
            tokens_b.iter().map(move |tb| {
                ta.chars()
                    .zip(tb.chars())
                    .take_while(|(ca, cb)| ca == cb)
                    .count()
            })
        })
        .filter(|&c| c >= 4)
        .max()
        .unwrap_or(0)
}

/// Strip hardware vendor prefixes for a clean display name.
fn display_name(name: &str) -> String {
    name.replace("sof-soundwire", "")
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
}

/// Run an external command and return its stdout, or an error string.
fn run_cmd(cmd: &str, args: &[&str]) -> Result<String, String> {
    let out = Command::new(cmd)
        .args(args)
        .output()
        .map_err(|e| e.to_string())?;
    if out.status.success() {
        Ok(String::from_utf8_lossy(&out.stdout).to_string())
    } else {
        Err(String::from_utf8_lossy(&out.stderr).to_string())
    }
}

/// Extract a device name from a `wpctl status` line (text between '.' and '[').
fn extract_name_from_line(line: &str) -> Option<String> {
    let dot_pos = line.find('.')?;
    let after = &line[dot_pos + 1..];
    let end = after.find('[').unwrap_or(after.len());
    let name = after[..end].trim();
    if name.is_empty() {
        None
    } else {
        Some(name.to_string())
    }
}

/// Extract the first contiguous digit sequence from a string.
fn extract_first_number(s: &str) -> Option<String> {
    let mut num = String::new();
    for c in s.chars() {
        if c.is_ascii_digit() {
            num.push(c);
        } else if !num.is_empty() {
            break;
        }
    }
    if num.is_empty() { None } else { Some(num) }
}

/// Print i3blocks-compatible three-line output (full, short, color).
fn print_i3(full: &str, short: &str, color: &str) {
    println!("{}", display_name(full));
    println!("{}", short);
    println!("{}", color);
}
