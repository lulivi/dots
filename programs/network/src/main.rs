use std::io;
use std::process::{Command, exit};

fn main() {
    // verify dependency
    if let Err(e) = Command::new("nmcli").arg("--version").output() {
        eprintln!("nmcli not found: {}", e);
        eprintln!("Install NetworkManager (nmcli) to use this tool.");
        exit(1);
    }

    if let Err(e) = run() {
        eprintln!("network error: {}", e);
        exit(1);
    }
}

fn run() -> io::Result<()> {
    let out = run_nmcli(&["-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi"])?;

    for line in out.lines() {
        let mut parts = line.splitn(3, ':');
        let active = parts.next().unwrap_or("");
        let ssid = parts.next().unwrap_or("");
        let signal = parts.next().unwrap_or("");
        if active == "yes" {
            if let Ok(sig) = signal.parse::<i32>() {
                let full = format!("{} {}%", ssid, sig);
                let color = level_hex(sig);
                print_i3(&full, "", color);
            } else {
                print_i3(ssid, "", "#FFFFFF");
            }
            return Ok(());
        }
    }

    print_i3("-", "", "#FFFFFF");
    Ok(())
}

fn run_nmcli(args: &[&str]) -> Result<String, io::Error> {
    let out = Command::new("nmcli").args(args).output()?;
    Ok(String::from_utf8_lossy(&out.stdout).to_string())
}

fn level_hex(p: i32) -> &'static str {
    if p < 34 { "#FF0000" } else { "" }
}

fn print_i3(full: &str, short: &str, color: &str) {
    println!("{}", full);
    println!("{}", short);
    println!("{}", color);
}
