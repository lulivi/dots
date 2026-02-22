use std::fs;
use std::io;
use std::path::Path;
use std::process::exit;

fn main() {
    if let Err(e) = run() {
        eprintln!("battery error: {}", e);
        exit(1);
    }
}

fn run() -> io::Result<()> {
    let battery_path = "/sys/class/power_supply/BAT0";
    let status = fs::read_to_string(Path::new(battery_path).join("status"))?
        .trim()
        .to_string();
    let capacity = fs::read_to_string(Path::new(battery_path).join("capacity"))?
        .trim()
        .to_string();

    let cap = capacity.parse::<i32>().unwrap_or(0);
    let status_short = match status.as_str() {
        "Charging" => "C",
        "Discharging" => "D",
        "Not charging" => "N",
        "Full" => "F",
        _ => "?",
    };
    let full = format!("{} {}%", status_short, capacity);
    let color = level_hex(cap);
    print_i3(&full, "", color);
    Ok(())
}

fn level_hex(p: i32) -> &'static str {
    if p < 34 {
        "#FF0000"
    } else if p < 67 {
        "#FFB400"
    } else {
        ""
    }
}

fn print_i3(full: &str, short: &str, color: &str) {
    println!("{}", full);
    println!("{}", short);
    println!("{}", color);
}
