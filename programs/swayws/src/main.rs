//! Sway workspace helpers (binary).
//!
//! This binary delegates workspace computation logic to the library crate
//! so that it can be tested and reused.
use clap::{Parser, Subcommand};
use std::io;
use swayws::{
    compute_left_right, compute_target_workspace, fetch_workspaces, find_current_workspace_name,
};

#[derive(Parser)]
#[command(author, version, about)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    Current,
    Up,
    Down,
    Left,
    Right,
}

fn main() -> io::Result<()> {
    if let Err(e) = run() {
        eprintln!("{}", e);
        std::process::exit(1);
    }
    Ok(())
}

fn run() -> Result<(), String> {
    let cli = Cli::parse();

    let workspaces = fetch_workspaces()?;
    let name = find_current_workspace_name(&workspaces)?;

    match cli.command.unwrap_or(Commands::Current) {
        Commands::Current => println!("{}", name),
        Commands::Up => print!("{}", compute_target_workspace(&name, false)),
        Commands::Down => print!("{}", compute_target_workspace(&name, true)),
        Commands::Left => print!("{}", compute_left_right(&name, true, &workspaces)),
        Commands::Right => print!("{}", compute_left_right(&name, false, &workspaces)),
    }

    Ok(())
}
