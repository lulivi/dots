use std::fs;
use std::io;
use std::path::Path;
use std::process::exit;

fn main() {
    if let Err(e) = run() {
        eprintln!("light error: {}", e);
        exit(1);
    }
}

fn run() -> io::Result<()> {
    let base = Path::new("/sys/class/backlight");
    let mut entry = None;
    for p in fs::read_dir(base)? {
        let p = p?;
        if p.path().is_dir() {
            entry = Some(p.path());
            break;
        }
    }

    let path = match entry {
        Some(p) => p,
        None => {
            print_i3("-", "", "#FFFFFF");
            return Ok(());
        }
    };

    let bright_s = fs::read_to_string(path.join("brightness"))?;
    let max_s = fs::read_to_string(path.join("max_brightness"))?;
    let bright = bright_s.trim().parse::<i32>().unwrap_or(0);
    let max = max_s.trim().parse::<i32>().unwrap_or(1);
    let pct = if max > 0 { (bright * 100) / max } else { 0 };

    let full = format!("{}%", pct);
    // let color = level_hex(pct);
    // print_i3(&full, "", color);
    print_i3(&full, "", "");
    Ok(())
}

// fn level_hex(p: i32) -> &'static str {
//     if p < 34 {
//         "#FF0000"
//     } else if p < 67 {
//         "#FFB400"
//     } else {
//         "#00FF00"
//     }
// }

fn print_i3(full: &str, short: &str, color: &str) {
    println!("{}", full);
    println!("{}", short);
    println!("{}", color);
}
