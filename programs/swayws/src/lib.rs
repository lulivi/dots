use serde_json::Value;
use std::collections::HashMap;
use std::env;
use std::fs;
use std::process::Command;

/// Invoke `swaymsg -t get_workspaces` and parse the JSON output.
pub fn fetch_workspaces() -> Result<Vec<Value>, String> {
    let output = Command::new("swaymsg")
        .arg("-t")
        .arg("get_workspaces")
        .output()
        .map_err(|e| format!("failed to spawn swaymsg: {}", e))?;

    if !output.status.success() {
        return Err(format!(
            "swaymsg failed: exit code {:?}",
            output.status.code()
        ));
    }

    let stdout = String::from_utf8_lossy(&output.stdout);

    let v: Value = serde_json::from_str(&stdout)
        .map_err(|e| format!("failed to parse swaymsg JSON: {}", e))?;

    if let Some(arr) = v.as_array() {
        return Ok(arr.clone());
    }

    Err("swaymsg returned non-array JSON".into())
}

/// Find the current workspace name from a list of parsed `workspaces`.
pub fn find_current_workspace_name(workspaces: &[Value]) -> Result<String, String> {
    // prefer focused
    if let Some(ws) = workspaces
        .iter()
        .find(|ws| ws.get("focused").and_then(|b| b.as_bool()).unwrap_or(false))
    {
        if let Some(name) = ws.get("name").and_then(|n| n.as_str()) {
            return Ok(name.to_string());
        }
    }

    // fallback to first
    if let Some(first) = workspaces.get(0) {
        if let Some(name) = first.get("name").and_then(|n| n.as_str()) {
            return Ok(name.to_string());
        }
    }

    Err("no workspace name found".into())
}

/// Parse leading integer from a workspace name, e.g. "21: Code" -> 21.
pub fn workspace_number(name: &str) -> Option<i64> {
    let mut digits = String::new();
    for c in name.chars() {
        if c.is_ascii_digit() {
            digits.push(c);
        } else {
            break;
        }
    }
    if digits.is_empty() {
        None
    } else {
        digits.parse().ok()
    }
}

/// Compute the new workspace name by adjusting the unit (ones) digit.
pub fn compute_target_workspace(current: &str, down: bool) -> String {
    // parse leading integer from workspace name
    let mut digits = String::new();
    for c in current.chars() {
        if c.is_ascii_digit() {
            digits.push(c);
        } else {
            break;
        }
    }

    if digits.is_empty() {
        return current.to_string();
    }

    let num: i64 = digits.parse().unwrap_or(0);

    // Adjust the units (ones) digit instead of the tens digit.
    // Keep the higher-order digits (base) intact and only increment/decrement
    // the unit index. Do not let the unit fall below 1 or exceed 9.
    let unit = (num % 10).abs();
    let base = num - unit;

    let new_unit = if down {
        std::cmp::min(unit + 1, 9)
    } else {
        if unit > 1 { unit - 1 } else { unit }
    };

    let new_num = base + new_unit;

    let rest = &current[digits.len()..];
    format!("{}{}", new_num, rest)
}

/// Parse workspace definitions from a variables file content.
fn parse_variable_map(contents: &str) -> HashMap<i64, String> {
    let mut var_map = HashMap::new();
    for line in contents.lines() {
        if let Some(start) = line.find('"') {
            if let Some(end) = line[start + 1..].find('"') {
                let val = &line[start + 1..start + 1 + end];
                if let Some(n) = workspace_number(val) {
                    var_map.insert(n, val.to_string());
                }
            }
        }
    }
    var_map
}

/// Load `variables.conf`-style definitions into a map. Honor `SWAY_VARS` env var,
/// fallback to `./variables.conf`, then to `$HOME/.config/sway/config.d/variables.conf`.
fn load_variable_workspace_map() -> HashMap<i64, String> {
    if let Ok(path) = env::var("SWAY_VARS") {
        if let Ok(contents) = fs::read_to_string(path) {
            return parse_variable_map(&contents);
        }
    }

    if let Ok(contents) = fs::read_to_string("./variables.conf") {
        return parse_variable_map(&contents);
    }

    if let Ok(home) = env::var("HOME") {
        let default_path = format!("{}/.config/sway/config.d/variables.conf", home);
        if let Ok(contents) = fs::read_to_string(default_path) {
            return parse_variable_map(&contents);
        }
    }

    HashMap::new()
}

/// Compute the workspace to the left or right (jump to adjacent base).
///
/// Behavior:
/// - Extract the leading numeric prefix from `current`; the target is the
///   adjacent tens column's base workspace (unit == 1), e.g. from `35` ->
///   `21` when moving left, or `13` -> `21` when moving right.
/// - Prefer an existing workspace name returned by `swaymsg` (from
///   `workspaces`); if none exists, fall back to a definition from
///   `variables.conf` loaded via `load_variable_workspace_map()`.
/// - If the target column is invalid (target < 1) or neither source has a
///   name for the target, return `current` (no move).
///
/// Arguments: `current` (workspace name), `left` (direction),
/// `workspaces` (parsed `swaymsg` JSON array).
pub fn compute_left_right(current: &str, left: bool, workspaces: &[Value]) -> String {
    // Simplified behaviour: jump to the previous/next "base" workspace
    // (unit == 1) in the adjacent tens column. Prefer a definition from
    // variables.conf, then any existing workspace with that number. If
    // neither exists, stay on the current workspace.
    let mut digits = String::new();
    for c in current.chars() {
        if c.is_ascii_digit() {
            digits.push(c);
        } else {
            break;
        }
    }

    if digits.is_empty() {
        return current.to_string();
    }

    let num: i64 = digits.parse().unwrap_or(0);
    let current_tens = (num / 10) * 10;
    let target_tens = if left {
        current_tens - 10
    } else {
        current_tens + 10
    };
    let target_num = target_tens + 1; // base workspace uses unit == 1, e.g. 21

    if target_num < 1 {
        return current.to_string();
    }

    let mut map = std::collections::HashMap::new();
    for ws in workspaces {
        if let Some(name) = ws.get("name").and_then(|n| n.as_str()) {
            if let Some(nnum) = workspace_number(name) {
                map.insert(nnum, name.to_string());
            }
        }
    }

    let var_map = load_variable_workspace_map();

    if let Some(name) = map.get(&target_num) {
        return name.clone();
    }
    if let Some(name) = var_map.get(&target_num) {
        return name.clone();
    }

    current.to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn make_ws(name: &str, focused: bool) -> Value {
        json!({ "name": name, "focused": focused })
    }

    #[test]
    fn test_workspace_number() {
        assert_eq!(workspace_number("21: Code"), Some(21));
        assert_eq!(workspace_number("3foo"), Some(3));
        assert_eq!(workspace_number("no-digits"), None);
    }

    #[test]
    fn test_compute_target_workspace_up_down() {
        assert_eq!(
            compute_target_workspace("21: Code", /*down=*/ false),
            "21: Code"
        );
        assert_eq!(
            compute_target_workspace("21: Code", /*down=*/ true),
            "22: Code"
        );
        assert_eq!(
            compute_target_workspace("29: Foo", /*down=*/ true),
            "29: Foo"
        );
    }

    #[test]
    fn test_find_current_workspace_name() {
        let w = vec![make_ws("11: A", false), make_ws("22: B", true)];
        assert_eq!(find_current_workspace_name(&w).unwrap(), "22: B");
    }

    #[test]
    fn test_compute_left_right_basic() {
        // workspaces: 11,21,31,41
        let w = vec![
            make_ws("11: a", false),
            make_ws("21: b", true),
            make_ws("31: c", false),
            make_ws("41: d", false),
        ];

        assert_eq!(compute_left_right("21: b", true, &w), "11: a");
        assert_eq!(compute_left_right("21: b", false, &w), "31: c");
    }

    #[test]
    fn test_compute_left_right_boundaries_and_fallback() {
        // no 51 exists
        let w = vec![make_ws("41: d", true)];
        // from 41, right should keep 41 because there is no 51 column
        assert_eq!(compute_left_right("41: d", false, &w), "41: d");

        // unit==1 and left should search 11..14; if none found, stay at current (boundary)
        assert_eq!(compute_left_right("11: a", true, &w), "11: a");

        // when the target base workspace exists, we should move there
        let w2 = vec![make_ws("31: c", false)];
        assert_eq!(compute_left_right("24: y", false, &w2), "31: c");
    }

    #[test]
    fn test_compute_left_right_jump_examples() {
        // if we're in 35 and move left, jump to 21 when it exists
        let w = vec![make_ws("21: b", false), make_ws("35: x", true)];
        assert_eq!(compute_left_right("35: x", true, &w), "21: b");

        // if we're in 13 and move right, jump to 21 when it exists
        let w2 = vec![make_ws("21: b", false)];
        assert_eq!(compute_left_right("13: a", false, &w2), "21: b");
    }
}
