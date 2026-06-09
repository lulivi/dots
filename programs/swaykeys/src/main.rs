/// Entry point.
///
/// Reads Sway keybindings and prints each `bindsym`/`bindcode` mapping found.
/// Behavior:
/// - If `--config` is a file, that file is read as plain text.
/// - If `--config` is a directory, the program reads `keys.conf` inside that
///   directory as plain text (no `include` processing).
/// - `set` variables are parsed and expanded when used in binding commands.
///
/// Errors are written to stderr and cause a non-zero exit code.
use clap::Parser;
use shell_words;
use shellexpand;
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;
use std::process;

#[derive(Parser)]
#[command(name = "swaykeys")]
struct Args {
    /// Path to sway config (defaults to ~/.config/sway/config)
    #[arg(short, long)]
    config: Option<String>,
}

fn main() {
    let args = Args::parse();
    let cfg = args
        .config
        .unwrap_or_else(|| "~/.config/sway/config.d/keys.conf".to_string());
    let cfg_path_raw = PathBuf::from(shellexpand::tilde(&cfg).to_string());
    let cfg_path = match cfg_path_raw.canonicalize() {
        Ok(p) => p,
        Err(e) => {
            eprintln!(
                "Failed to canonicalize config path {}: {}",
                cfg_path_raw.display(),
                e
            );
            process::exit(1);
        }
    };

    let lines = match read_config_lines(&cfg_path) {
        Ok(l) => l,
        Err(e) => {
            eprintln!("{}", e);
            process::exit(1);
        }
    };

    let vars = collect_set_vars(&lines);
    let annotated = annotate_modes(&lines);
    process_bindings(&annotated, &vars);
}

fn read_config_lines(cfg_path: &PathBuf) -> Result<Vec<(PathBuf, usize, String)>, String> {
    if cfg_path.is_dir() {
        let key_file = cfg_path.join("keys.conf");
        if !key_file.exists() || !key_file.is_file() {
            return Err(format!(
                "Config directory {} does not contain keys.conf",
                cfg_path.display()
            ));
        }
        let s = fs::read_to_string(&key_file)
            .map_err(|e| format!("Error reading {}: {}", key_file.display(), e))?;
        Ok(s.lines()
            .enumerate()
            .map(|(i, l)| (key_file.clone(), i + 1, l.to_string()))
            .collect())
    } else if cfg_path.is_file() {
        let s = fs::read_to_string(cfg_path)
            .map_err(|e| format!("Error reading {}: {}", cfg_path.display(), e))?;
        Ok(s.lines()
            .enumerate()
            .map(|(i, l)| (cfg_path.clone(), i + 1, l.to_string()))
            .collect())
    } else {
        Err(format!(
            "Config path {} is not a file or directory",
            cfg_path.display()
        ))
    }
}

fn collect_set_vars(lines: &[(PathBuf, usize, String)]) -> HashMap<String, String> {
    let mut vars = HashMap::new();
    for (_path, _lineno, line) in lines.iter() {
        let trimmed = line.trim_start();
        if trimmed.is_empty() || trimmed.starts_with('#') {
            continue;
        }
        if let Ok(tokens) = shell_words::split(trimmed) {
            if tokens.len() >= 3 && tokens[0] == "set" {
                let raw_name = &tokens[1];
                let name = strip_var_name(raw_name);
                let value = tokens[2..].join(" ");
                vars.insert(name, value);
            }
        }
    }
    vars
}

fn annotate_modes(
    lines: &[(PathBuf, usize, String)],
) -> Vec<(PathBuf, usize, String, Option<String>, Option<String>)> {
    // returns (path, lineno, line, current_mode, current_block)
    let mut annotated: Vec<(PathBuf, usize, String, Option<String>, Option<String>)> = Vec::new();
    let mut mode_stack: Vec<(String, isize)> = Vec::new();
    let mut block_stack: Vec<(String, isize)> = Vec::new();
    let mut pending_mode: Option<String> = None;
    let mut pending_block: Option<String> = None;

    for (path, lineno, line) in lines.iter() {
        let trimmed = line.trim_start();
        if !trimmed.is_empty() && !trimmed.starts_with('#') {
            if let Ok(tokens) = shell_words::split(trimmed) {
                if tokens.len() >= 2 && tokens[0] == "mode" {
                    let name = strip_var_name(&tokens[1]);
                    pending_mode = Some(name);
                }
                if tokens.len() >= 1 && (tokens[0] == "bindsym" || tokens[0] == "bindcode") {
                    let name = tokens[0].clone();
                    pending_block = Some(name);
                }
            }
        }

        let opens = line.matches('{').count() as isize;
        let closes = line.matches('}').count() as isize;

        if let Some(name) = pending_mode.take() {
            if opens > closes {
                mode_stack.push((name.clone(), opens - closes));
                // when opening a mode, annotate this line with the mode
                let current_block = block_stack.last().map(|(n, _)| n.clone());
                annotated.push((
                    path.clone(),
                    *lineno,
                    line.clone(),
                    Some(name),
                    current_block,
                ));
            } else {
                let current_block = block_stack.last().map(|(n, _)| n.clone());
                annotated.push((
                    path.clone(),
                    *lineno,
                    line.clone(),
                    Some(name),
                    current_block,
                ));
                let mut rem_closes = closes.saturating_sub(opens);
                while rem_closes > 0 && !mode_stack.is_empty() {
                    if let Some(top) = mode_stack.last_mut() {
                        top.1 -= 1;
                        if top.1 <= 0 {
                            mode_stack.pop();
                        }
                    }
                    rem_closes -= 1;
                }
            }
        } else if let Some(name) = pending_block.take() {
            // similar handling for bindsym/bindcode blocks
            if opens > closes {
                block_stack.push((name.clone(), opens - closes));
                let current_mode = mode_stack.last().map(|(n, _)| n.clone());
                annotated.push((
                    path.clone(),
                    *lineno,
                    line.clone(),
                    current_mode,
                    Some(name),
                ));
            } else {
                let current_mode = mode_stack.last().map(|(n, _)| n.clone());
                annotated.push((
                    path.clone(),
                    *lineno,
                    line.clone(),
                    current_mode,
                    Some(name),
                ));
                let mut rem_closes = closes.saturating_sub(opens);
                while rem_closes > 0 && !block_stack.is_empty() {
                    if let Some(top) = block_stack.last_mut() {
                        top.1 -= 1;
                        if top.1 <= 0 {
                            block_stack.pop();
                        }
                    }
                    rem_closes -= 1;
                }
            }
        } else {
            let current_mode = mode_stack.last().map(|(n, _)| n.clone());
            let current_block = block_stack.last().map(|(n, _)| n.clone());
            annotated.push((
                path.clone(),
                *lineno,
                line.clone(),
                current_mode,
                current_block,
            ));

            if opens > 0 {
                if let Some(top) = mode_stack.last_mut() {
                    top.1 += opens;
                }
                if let Some(top) = block_stack.last_mut() {
                    top.1 += opens;
                }
            }

            let mut rem_closes = closes;
            while rem_closes > 0 && !block_stack.is_empty() {
                if let Some(top) = block_stack.last_mut() {
                    top.1 -= 1;
                    if top.1 <= 0 {
                        block_stack.pop();
                    }
                }
                rem_closes -= 1;
            }
            let mut rem_closes_mode = closes;
            while rem_closes_mode > 0 && !mode_stack.is_empty() {
                if let Some(top) = mode_stack.last_mut() {
                    top.1 -= 1;
                    if top.1 <= 0 {
                        mode_stack.pop();
                    }
                }
                rem_closes_mode -= 1;
            }
        }
    }

    annotated
}

fn process_bindings(
    annotated: &[(PathBuf, usize, String, Option<String>, Option<String>)],
    vars: &HashMap<String, String>,
) {
    for (path, lineno, line, mode_opt, block_opt) in annotated.iter() {
        let trimmed = line.trim_start();
        if trimmed.is_empty() || trimmed.starts_with('#') {
            continue;
        }

        if let Ok(tokens) = shell_words::split(trimmed) {
            if tokens.is_empty() {
                continue;
            }
            let verb = tokens[0].as_str();

            // Skip lines that open a bindsym/bindcode block (e.g. "bindsym {" or "bindsym --release {")
            if (verb == "bindsym" || verb == "bindcode") && line.contains('{') {
                continue;
            }

            if verb == "bindsym" || verb == "bindcode" {
                let mut i = 1usize;
                while i < tokens.len() && tokens[i].starts_with('-') {
                    i += 1;
                }
                if i < tokens.len() {
                    let key_raw = &tokens[i];
                    let command_raw = if i + 1 < tokens.len() {
                        tokens[i + 1..].join(" ")
                    } else {
                        String::new()
                    };
                    let key = expand_vars(key_raw, vars);
                    let command = expand_vars(&command_raw, vars);
                    let mode_suffix = if let Some(m) = mode_opt.as_ref() {
                        format!(" [mode: {}]", m)
                    } else {
                        String::new()
                    };
                    println!(
                        "{} -> {} ({}:{}){}",
                        key,
                        command,
                        path.display(),
                        lineno,
                        mode_suffix
                    );
                }
            } else if let Some(block) = block_opt.as_ref() {
                // Inside a bindsym/bindcode block: first token is the key
                if block == "bindsym" || block == "bindcode" {
                    let mut i = 0usize;
                    while i < tokens.len() && tokens[i].starts_with('-') {
                        i += 1;
                    }
                    if i < tokens.len() {
                        let key_raw = &tokens[i];
                        let command_raw = if i + 1 < tokens.len() {
                            tokens[i + 1..].join(" ")
                        } else {
                            String::new()
                        };
                        let key = expand_vars(key_raw, vars);
                        let command = expand_vars(&command_raw, vars);
                        let mode_suffix = if let Some(m) = mode_opt.as_ref() {
                            format!(" [mode: {}]", m)
                        } else {
                            String::new()
                        };
                        println!(
                            "{} -> {} ({}:{}){}",
                            key,
                            command,
                            path.display(),
                            lineno,
                            mode_suffix
                        );
                    }
                }
            }
        }
    }
}

/// Strip `$` or `${}` from a variable name.
fn strip_var_name(s: &str) -> String {
    let mut t = s.to_string();
    if t.starts_with('$') {
        t = t[1..].to_string();
    }
    if t.starts_with('{') && t.ends_with('}') {
        t = t[1..t.len() - 1].to_string();
    }
    t
}

/// Expand variables in `s` using the `vars` map.
/// Performs up to 10 iterative replacements to allow nested expansions.
fn expand_vars(s: &str, vars: &HashMap<String, String>) -> String {
    if vars.is_empty() {
        return s.to_string();
    }
    let mut out = s.to_string();
    for _ in 0..10 {
        let prev = out.clone();
        for (k, v) in vars {
            let pat1 = format!("${}", k);
            let pat2 = format!("${{{}}}", k);
            out = out.replace(&pat2, v);
            out = out.replace(&pat1, v);
        }
        if out == prev {
            break;
        }
    }
    out
}
