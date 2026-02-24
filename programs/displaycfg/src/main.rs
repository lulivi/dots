//! Display output detector for sway
//!
//! Queries `swaymsg -t get_outputs` and prints a short token describing the
//! current display configuration. If an external ViewSonic monitor
//! (`ViewSonic Corporation VA2719-2K ...`) is present the program prints
//! `home`. If only the internal LG panel (`eDP-1 'LG Display ...`) is
//! present the program prints `laptop`.
use std::process::Command;
use serde_json::Value;

/// Entry point.
///
/// Runs `swaymsg -t get_outputs`, parses the JSON output, and prints either
/// `home` or `laptop` according to the detected outputs. Errors (failed
/// command invocation or invalid JSON) are reported on stderr and cause a
/// non-zero exit code.
fn main() {
    let out = Command::new("swaymsg")
        .args(["-t", "get_outputs"]) 
        .output()
        .expect("failed to spawn swaymsg");

    if !out.status.success() {
        eprintln!("swaymsg failed");
        std::process::exit(1);
    }

    let s = String::from_utf8_lossy(&out.stdout);
    let v: Value = match serde_json::from_str(&s) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("failed to parse swaymsg output: {}", e);
            std::process::exit(1);
        }
    };

    let arr = match v.as_array() {
        Some(a) => a,
        None => {
            eprintln!("unexpected swaymsg output");
            std::process::exit(1);
        }
    };

    let mut descrs: Vec<String> = Vec::new();
    for item in arr {
        let name = item.get("name").and_then(|v| v.as_str()).unwrap_or("");
        let make = item.get("make").and_then(|v| v.as_str()).unwrap_or("");
        let model = item.get("model").and_then(|v| v.as_str()).unwrap_or("");
        let descr = format!("{} {} {}", name, make, model);
        descrs.push(descr);
    }

    // If any output matches the ViewSonic model, print "home"
    for d in &descrs {
        if d.contains("ViewSonic Corporation") && d.contains("VA2719-2K") {
            print!("home");
            return;
        }
    }

    // If only the internal LG panel appears, print "laptop"
    if descrs.len() == 1 {
        let d = &descrs[0];
        if d.contains("eDP-1") && d.contains("LG Display") {
            print!("laptop");
            return;
        }
    }
}
