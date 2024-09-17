use clap::Parser;
use serde_json::{Number, Value};
use std::{
    env,
    io::{self, BufRead, BufReader, Write},
    process::{Child, ChildStdout, Command, Stdio},
};

/// Simple program to greet a person
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Name of the monitor
    monitor: Option<String>,
}

static WIN_NAME_MAX_LEN: usize = 35;

fn main() {
    let args: Args = Args::parse();

    let monitor_string: &str = &match args.monitor {
        Some(provided_monitor) => provided_monitor,
        None => env::var("POLYBAR_MONITOR").unwrap_or_else(|_| {
            eprintln!("Error: POLYBAR_MONITOR variable not provided");
            std::process::exit(1)
        }),
    };

    let underline_colour: String= env::var("UNDERLINE_COLOUR").unwrap_or_else(|_| {
        eprintln!("Error: COLOR_FG variable not provided");
        std::process::exit(1)
    });
    let update_cmd: Child = Command::new("bspc")
        .args(["subscribe", "report"])
        .stdout(Stdio::piped())
        .spawn()
        .expect("Failed to start bspc subscribe command");

    let stdout_buffer: BufReader<ChildStdout> =
        BufReader::new(update_cmd.stdout.expect("failed to capture stdout"));

    stdout_buffer
        .lines()
        .filter_map(|s| s.ok())
        .for_each(|_| print_desktop_clients(monitor_string, &underline_colour));
}

fn print_desktop_clients(monitor_string: &str, underline_colour: &String) {
    let bspwm_state_cmd: Child = Command::new("bspc")
        .args(["wm", "--dump-state"])
        .stdout(Stdio::piped())
        .spawn()
        .expect("Failed to start bspc command");
    let bspwm_state: String = String::from_utf8(
        bspwm_state_cmd
            .wait_with_output()
            .expect("Failed to wait on sed")
            .stdout,
    )
    .unwrap();

    let state: Value = serde_json::from_str(&bspwm_state).expect("JSON was not well-formatted");

    let selected_monitor: &Value = state["monitors"]
        .as_array()
        .unwrap()
        .iter()
        .find(|monitor| monitor.as_object().unwrap()["name"] == monitor_string)
        .unwrap();

    let selected_desktop: &Value = selected_monitor["desktops"]
        .as_array()
        .unwrap()
        .iter()
        .find(|desktop| desktop.as_object().unwrap()["id"] == selected_monitor["focusedDesktopId"])
        .unwrap();

    let mut visible_clients: Vec<(Number, String)> = Vec::new();

    find_desktop_clients(&selected_desktop["root"], &mut visible_clients);

    let mut client_formats: Vec<String> = Vec::new();

    let mut string_prefix: String;
    let mut string_suffix: String;
    for (client_id, client_string) in visible_clients {
        string_prefix = String::from("");
        string_suffix = String::from("");
        if &client_id == selected_desktop["focusedNodeId"].as_number().unwrap() {
            string_prefix = format!(
                "%{{u{}}}",
                underline_colour
            );
            string_suffix = String::from(r"%{-u}");
        }
        client_formats.push(format!(
            "{}{}{}",
            string_prefix, client_string, string_suffix
        ));
    }

    println!("{:}", client_formats.join(" "));
    io::stdout().flush().expect("Unable to flush stdout");
}

fn find_desktop_clients(node: &Value, found_clients: &mut Vec<(Number, String)>) -> () {
    if node["client"].as_object().is_some() {
        found_clients.push(format_client_name(node));
        return;
    }

    if node["firstChild"].as_object().is_some() {
        find_desktop_clients(&node["firstChild"], found_clients);
    }

    if node["secondChild"].as_object().is_some() {
        find_desktop_clients(&node["secondChild"], found_clients);
    }
}

fn format_client_name(node: &Value) -> (Number, String) {
    let mut raw_client_name: String = format!(
        "{} :: {}",
        node["client"].as_object().unwrap()["className"]
            .as_str()
            .unwrap()
            .to_owned(),
        get_client_name(&node["id"])
    );

    let raw_client_name_len: usize = raw_client_name.len();

    raw_client_name.truncate(WIN_NAME_MAX_LEN);

    if raw_client_name_len > raw_client_name.len() {
        raw_client_name.truncate(WIN_NAME_MAX_LEN - 3);
        raw_client_name.push_str("...");
    }

    return (
        node["id"].as_number().unwrap().clone(),
        format!("[ {: ^32} ]", raw_client_name),
    );
}

fn get_client_name(client_id: &Value) -> String {
    let xprop_cmd: Child = Command::new("xprop")
        .args([
            "-id",
            client_id.as_number().unwrap().to_string().as_str(),
            "WM_NAME",
        ])
        .stdout(Stdio::piped())
        .spawn()
        .expect("Failed to start xprop command");

    return String::from_utf8(
        xprop_cmd
            .wait_with_output()
            .expect("Failed to wait on sed")
            .stdout,
    )
    .unwrap()
    .split("=")
    .last()
    .unwrap()
    .trim()
    .replace("\"", "");
}
