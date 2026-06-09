use serde_json::Value;
use std::collections::HashMap;
use std::env;
use std::fs;
use std::process::Command;

/// Invokes `swaymsg -t get_workspaces` and parses the JSON output into a vector of active workspace values.
pub fn fetch_workspaces() -> Result<Vec<Value>, String> {
    let output = Command::new("swaymsg")
        .args(&["-t", "get_workspaces"])
        .output()
        .map_err(|e| format!("failed to spawn swaymsg: {}", e))?;

    if !output.status.success() {
        return Err(format!(
            "swaymsg failed: exit code {:?}",
            output.status.code()
        ));
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let v: Value =
        serde_json::from_str(&stdout).map_err(|e| format!("failed to parse JSON: {}", e))?;

    v.as_array()
        .cloned()
        .ok_or_else(|| "swaymsg returned non-array JSON".into())
}

/// Finds the name of the currently focused workspace from the list of active workspaces.
pub fn find_current_workspace_name(workspaces: &[Value]) -> Result<String, String> {
    if let Some(ws) = workspaces
        .iter()
        .find(|ws| ws.get("focused").and_then(|b| b.as_bool()).unwrap_or(false))
    {
        if let Some(name) = ws.get("name").and_then(|n| n.as_str()) {
            return Ok(name.to_string());
        }
    }
    Err("no workspace name found".into())
}

/// Parses the leading numeric digits from a workspace name string into a 64-bit integer index.
pub fn workspace_number(name: &str) -> Option<i64> {
    let digits: String = name.chars().take_while(|c| c.is_ascii_digit()).collect();
    if digits.is_empty() {
        None
    } else {
        digits.parse().ok()
    }
}

/// Parses configuration file contents to map declared workspace coordinate numbers to their literal string definitions.
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

/// Searches standard XDG and HOME configuration paths to read and return the mapped contents of `variables.conf`.
#[cfg(not(test))]
fn load_variable_workspace_map() -> HashMap<i64, String> {
    let mut candidates = Vec::new();
    if let Ok(xdg) = env::var("XDG_CONFIG_HOME") {
        candidates.push(format!("{}/sway/config.d/variables.conf", xdg));
    }
    if let Ok(home) = env::var("HOME") {
        candidates.push(format!("{}/.config/sway/config.d/variables.conf", home));
    }
    for path in candidates {
        if let Ok(contents) = fs::read_to_string(&path) {
            return parse_variable_map(&contents);
        }
    }
    HashMap::new()
}

/// In tests, explicitly load from a localized temporary file to guarantee determinism.
#[cfg(test)]
fn load_variable_workspace_map() -> HashMap<i64, String> {
    if let Ok(contents) = fs::read_to_string("./test_variables.conf") {
        return parse_variable_map(&contents);
    }
    HashMap::new()
}

/// Resolves the absolute workspace name string given a target coordinate number, the current session state, and the configuration map.
fn get_workspace_name(
    target_num: i64,
    workspaces: &[Value],
    var_map: &HashMap<i64, String>,
) -> String {
    for ws in workspaces {
        if let Some(name) = ws.get("name").and_then(|n| n.as_str()) {
            if workspace_number(name) == Some(target_num) {
                return name.to_string();
            }
        }
    }

    if let Some(name) = var_map.get(&target_num) {
        return name.clone();
    }

    let base_num = (target_num / 10) * 10 + 1;
    let target_y = target_num % 10;

    if let Some(base_name) = var_map.get(&base_num) {
        let parts: Vec<&str> = base_name.split(':').collect();
        if parts.len() >= 2 {
            let icon = parts[1];
            return format!("{}:{}:{}", target_num, icon, target_y);
        }
    }

    target_num.to_string()
}

/// Computes the next vertical workspace name (up or down) within the boundaries of the current column grid.
pub fn compute_up_down(current: &str, down: bool, workspaces: &[Value]) -> String {
    let num = match workspace_number(current) {
        Some(n) => n,
        None => return current.to_string(),
    };

    let unit = (num % 10).abs();
    let base = num - unit;
    let new_unit = if down {
        std::cmp::min(unit + 1, 9)
    } else {
        if unit > 1 { unit - 1 } else { unit }
    };
    let target_num = base + new_unit;

    if target_num == num {
        return current.to_string();
    }

    let var_map = load_variable_workspace_map();
    get_workspace_name(target_num, workspaces, &var_map)
}

/// Computes the next horizontal workspace name (left or right) targeting the matching row index in the adjacent column.
pub fn compute_left_right(current: &str, left: bool, workspaces: &[Value]) -> String {
    let num = match workspace_number(current) {
        Some(n) => n,
        None => return current.to_string(),
    };

    let current_tens = (num / 10) * 10;
    let target_tens = if left {
        current_tens - 10
    } else {
        current_tens + 10
    };

    let mut unit = num % 10;
    if unit == 0 {
        unit = 1;
    }
    let target_num = target_tens + unit;

    if target_num < 1 {
        return current.to_string();
    }

    let var_map = load_variable_workspace_map();

    let base_target = target_tens + 1;
    let column_exists = var_map.contains_key(&base_target)
        || workspaces.iter().any(|ws| {
            ws.get("name")
                .and_then(|n| n.as_str())
                .and_then(workspace_number)
                .map(|nnum| (nnum / 10) * 10 == target_tens)
                .unwrap_or(false)
        });

    if !column_exists {
        return current.to_string();
    }

    get_workspace_name(target_num, workspaces, &var_map)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn make_ws(name: &str, focused: bool) -> Value {
        json!({ "name": name, "focused": focused })
    }

    /// Helper to inject a dummy variables.conf for tests requiring dynamic naming.
    fn setup_test_variables() {
        let contents = r#"
            set $ws11 "11:🌐:1"
            set $ws21 "21:💻:1"
            set $ws31 "31:💬:1"
        "#;
        let _ = fs::write("./test_variables.conf", contents);
    }

    /// Helper to cleanup the dummy test file.
    fn teardown_test_variables() {
        let _ = fs::remove_file("./test_variables.conf");
    }

    #[test]
    fn test_workspace_number() {
        assert_eq!(workspace_number("21:💻:1"), Some(21));
        assert_eq!(workspace_number("3foo"), Some(3));
        assert_eq!(workspace_number("no-digits"), None);
    }

    #[test]
    fn test_find_current_workspace_name() {
        let w = vec![make_ws("11:🌐:1", false), make_ws("22:💻:2", true)];
        assert_eq!(find_current_workspace_name(&w).unwrap(), "22:💻:2");
    }

    #[test]
    fn test_compute_up_down() {
        setup_test_variables();
        let w = vec![];

        // Boundaries and standard movements
        assert_eq!(compute_up_down("11:🌐:1", false, &w), "11:🌐:1");
        assert_eq!(compute_up_down("11:🌐:1", true, &w), "12:🌐:2");
        assert_eq!(compute_up_down("19:🌐:9", true, &w), "19:🌐:9");

        teardown_test_variables();
    }

    #[test]
    fn test_compute_left_right_basic() {
        setup_test_variables();
        let w = vec![
            make_ws("11:🌐:1", false),
            make_ws("21:💻:1", true),
            make_ws("31:💬:1", false),
        ];

        // Move left jumps to 11
        assert_eq!(compute_left_right("21:💻:1", true, &w), "11:🌐:1");
        // Move right jumps to 31
        assert_eq!(compute_left_right("21:💻:1", false, &w), "31:💬:1");

        teardown_test_variables();
    }

    #[test]
    fn test_compute_left_right_boundaries_and_fallback() {
        setup_test_variables();
        let w = vec![make_ws("31:💬:1", true)];

        // From 31, moving right should fail (stay 31) because 41 is not defined in the dummy file or session
        assert_eq!(compute_left_right("31:💬:1", false, &w), "31:💬:1");

        // Moving left from 11 should stay 11
        assert_eq!(compute_left_right("11:🌐:1", true, &w), "11:🌐:1");

        // Jump across column while keeping the Y index logic.
        // 22 doesn't exist yet, but moving right should construct 32 based on 31's icon.
        let w2 = vec![make_ws("22:💻:2", true)];
        assert_eq!(compute_left_right("22:💻:2", false, &w2), "32:💬:2");

        teardown_test_variables();
    }
}
