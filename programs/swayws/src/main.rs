//! Sway workspace helpers (binary).
use clap::{Parser, Subcommand};
use std::io;
use swayws::{compute_left_right, compute_up_down, fetch_workspaces, find_current_workspace_name};

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

/// Runs the CLI application by parsing arguments and executing the corresponding workspace command.
fn run() -> Result<(), String> {
    let cli = Cli::parse();

    let workspaces = fetch_workspaces()?;
    let name = find_current_workspace_name(&workspaces)?;

    match cli.command.unwrap_or(Commands::Current) {
        Commands::Current => println!("{}", name),
        Commands::Up => println!("{}", compute_up_down(&name, false, &workspaces)),
        Commands::Down => println!("{}", compute_up_down(&name, true, &workspaces)),
        Commands::Left => println!("{}", compute_left_right(&name, true, &workspaces)),
        Commands::Right => println!("{}", compute_left_right(&name, false, &workspaces)),
    }

    Ok(())
}
