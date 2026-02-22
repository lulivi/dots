use clap::{Parser, Subcommand};
use std::env;
use std::process::Command;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand, Debug)]
enum Commands {
    /// Switch to the next available audio device
    Switch,
    /// Print i3blocks-compatible output (full, short, color)
    I3,
}

struct Device {
    label: &'static str,
    name: &'static str,
}

const DEVICES: [Device; 3] = [
    Device {
        label: "speaker",
        name: "sof-soundwire Speaker",
    },
    Device {
        label: "headphones",
        name: "sof-soundwire Headphones",
    },
    Device {
        label: "steelseries",
        name: "SteelSeries Arctis 7 Game",
    },
];

/// CLI entry point.
///
/// Behavior:
/// - Parses command-line arguments using `clap` and supports the `switch` and `i3` subcommands.
/// - Queries the current audio sink status via `wpctl` and detects which configured devices
///   are available (also probes `pactl` when present).
/// - Prints the list of configured/available devices on standard output by default.
///
/// Subcommands:
/// - `switch`: cycles to the next configured audio device and prints the result (or an
///   error message on stderr).
/// - `i3`: prints i3blocks-compatible three-line output (full, short, color). When invoked
///   from i3blocks a click sets the `BLOCK_BUTTON` environment variable; in that case the
///   program will attempt to switch to the next device, re-query status, and emit the
///   updated i3 output (switching is performed silently so the block output remains clean).
///
/// Notes:
/// - External commands used: `wpctl` (required) and `pactl` (optional for availability checks).
/// - Errors from commands are reported to stderr; the CLI prints compact user-facing output
///   so it can be used both interactively and from status bars.
fn main() {
    let cli = Cli::parse();
    let status = run_cmd("wpctl", &["status"]).unwrap_or_default();
    let available = available_devices(&status, &DEVICES);

    let mut current_node_id: Option<String> = None;
    let mut current_node_name: Option<String> = None;
    if let Ok(status2) = run_cmd("wpctl", &["status"]) {
        if let Some(active_line) = find_active_line(&status2) {
            let id = extract_first_number(active_line).unwrap_or_default();
            if let Some(name) = extract_name_from_line(active_line) {
                current_node_id = Some(id);
                current_node_name = Some(name);
            } else {
                current_node_id = Some(id);
            }
        }
    }

    match cli.command {
        Some(Commands::Switch) => {
            match switch_to_next(&status, &available, &DEVICES) {
                Ok(Some(name)) => println!("Switched default audio to {}", name),
                Ok(None) => println!("No available sinks found or no switch performed"),
                Err(e) => eprintln!("Error switching device: {}", e),
            }
            return;
        }
        Some(Commands::I3) => {
            if env::var("BLOCK_BUTTON")
                .ok()
                .filter(|s| !s.is_empty())
                .is_some()
            {
                let _ = switch_to_next(&status, &available, &DEVICES);
            }

            let status_after = run_cmd("wpctl", &["status"]).unwrap_or_default();

            if let Some(active_line) = find_active_line(&status_after) {
                if let Some(name) = extract_name_from_line(active_line) {
                    print_i3(&name, "", "");
                    return;
                }
            }

            if let Some(lbl) = find_current_label(&status_after, &DEVICES) {
                print_i3(lbl, "", "");
                return;
            }

            print_i3("-", "", "");
            return;
        }
        None => {}
    }

    if cli.command.is_none() {
        if let Some(id) = current_node_id {
            if let Some(name) = current_node_name {
                println!("Current default node: {} (id {})", name, id);
                return;
            } else {
                println!("Current default node id: {}", id);
                return;
            }
        }

        println!("Could not determine active audio output (ensure wpctl is available)");
    }
}

/// Choose the devices to use: prefer detected available devices, else fall back to all.
fn select_use_devices<'a>(available: &[&'a Device], all: &'a [Device]) -> Vec<&'a Device> {
    if !available.is_empty() {
        available.to_vec()
    } else {
        all.iter().collect()
    }
}

/// Determine the index of the current device within the provided list.
fn current_index<'a>(status: &str, use_devices: &[&'a Device]) -> Option<usize> {
    find_current_label(status, use_devices.iter().copied())
        .and_then(|lbl| use_devices.iter().position(|d| d.label == lbl))
}

/// Attempt to switch to the given candidate device. Returns the new active name on success.
fn attempt_switch(status: &str, candidate: &Device) -> Result<Option<String>, String> {
    let id = match find_node_id_for_name(status, candidate.name) {
        Some(i) => i,
        None => return Ok(None),
    };

    match run_cmd("wpctl", &["set-default", &id]) {
        Ok(_) => match run_cmd("wpctl", &["status"]) {
            Ok(new_status) => verify_after_set(&new_status, candidate, &id),
            Err(e) => Err(format!(
                "Set-default returned OK for {} (node {}), but could not verify with `wpctl status`: {}",
                candidate.label, id, e
            )),
        },
        Err(e) => Err(format!(
            "Failed to set default for '{}' (node {}): {}",
            candidate.name, id, e
        )),
    }
}

/// Verify the status after attempting a switch; return the active name if it matches.
fn verify_after_set(
    new_status: &str,
    candidate: &Device,
    id: &str,
) -> Result<Option<String>, String> {
    if let Some(active_line) = find_active_line(new_status) {
        let curr_id = extract_first_number(active_line).unwrap_or_default();
        if curr_id == id {
            if let Some(name) = extract_name_from_line(active_line) {
                return Ok(Some(name));
            }
            return Ok(Some(candidate.label.to_string()));
        }

        if let Some(active_name) = extract_name_from_line(active_line) {
            if active_name.eq_ignore_ascii_case(candidate.name) {
                return Ok(Some(active_name));
            } else {
                return Ok(None);
            }
        } else {
            return Ok(None);
        }
    }

    Ok(None)
}

/// Cycle to the next configured device, returning the new active name on success.
fn switch_to_next(
    status: &str,
    available: &[&Device],
    all: &[Device],
) -> Result<Option<String>, String> {
    let use_devices = select_use_devices(available, all);

    if use_devices.is_empty() {
        return Ok(None);
    }

    let start_idx = match current_index(status, &use_devices) {
        Some(idx) => (idx + 1) % use_devices.len(),
        None => 0,
    };

    for i in 0..use_devices.len() {
        let candidate = use_devices[(start_idx + i) % use_devices.len()];
        if let Some(name) = attempt_switch(status, candidate)? {
            return Ok(Some(name));
        }
    }

    Ok(None)
}

/// Detect which of the configured devices are currently available.
fn available_devices<'a>(status: &str, devices: &'a [Device]) -> Vec<&'a Device> {
    fn get_pactl_sinks() -> Result<String, String> {
        run_cmd("pactl", &["list", "sinks"])
    }

    fn is_headphones_available(pactl_output: &str) -> Option<bool> {
        for line_lower in pactl_output.lines() {
            if line_lower.contains("[out] headphones:") {
                if line_lower.contains("not available") {
                    return Some(false);
                }
                if line_lower.contains("available") {
                    return Some(true);
                }
            }
        }
        None
    }

    let pactl_output = get_pactl_sinks().ok();

    devices
        .iter()
        .filter(|d| {
            if d.label == "speaker" {
                return true;
            }

            if let Some(ref pactl_text) = pactl_output {
                let pactl_lower = pactl_text.to_lowercase();

                if d.label == "headphones" {
                    return is_headphones_available(&pactl_lower).unwrap_or(false);
                }

                if d.label == "steelseries" {
                    return pactl_lower.contains("arctis 7 game");
                }
            }

            find_node_id_for_name(status, d.name).is_some()
        })
        .collect()
}

/// Run an external command and return its stdout or an error string.
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

/// Extract a sink name from a line of `wpctl status` output.
fn extract_name_from_line(line: &str) -> Option<String> {
    if let Some(dot_pos) = line.find('.') {
        let after = &line[dot_pos + 1..];
        let end = after.find('[').unwrap_or(after.len());
        let name = after[..end].trim();
        if !name.is_empty() {
            return Some(name.to_string());
        }
    }
    None
}

/// Map a sink name (from status) to a configured device label, if possible.
fn find_current_label<'a, D>(status: &str, devices: D) -> Option<&'a str>
where
    D: IntoIterator<Item = &'a Device>,
{
    let devs: Vec<&Device> = devices.into_iter().collect();

    if let Some(active) = find_active_line(status) {
        if let Some(name) = extract_name_from_line(active) {
            let lname = name.to_lowercase();
            for dev in &devs {
                if lname == dev.name.to_lowercase() {
                    return Some(dev.label);
                }
            }
        }
    }

    for line in status.lines() {
        if let Some(name) = extract_name_from_line(line) {
            let lname = name.to_lowercase();
            for dev in &devs {
                if lname == dev.name.to_lowercase() {
                    return Some(dev.label);
                }
            }
        }
    }

    None
}

/// Find the line marked active in `wpctl status` output.
fn find_active_line<'a>(status: &'a str) -> Option<&'a str> {
    status.lines().find(|l| l.contains('*'))
}

/// Return the node id (as string) for a sink matching `target_name`.
fn find_node_id_for_name(status: &str, target_name: &str) -> Option<String> {
    for line in status.lines() {
        if let Some(name) = extract_name_from_line(line) {
            if name.eq_ignore_ascii_case(target_name) {
                if let Some(n) = extract_first_number(line) {
                    return Some(n);
                }
            }
        }
    }
    None
}

/// Extract the first contiguous number found in a string.
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

/// Print i3blocks-compatible output, with some cleaning of known device name patterns.
fn print_i3(full: &str, short: &str, color: &str) {
    let cleaned = full
        .replace("sof-soundwire", "")
        .replace("Arctis 7 Game", "")
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ");
    println!("{}", cleaned);
    println!("{}", short);
    println!("{}", color);
}
