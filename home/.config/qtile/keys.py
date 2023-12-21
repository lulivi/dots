from pathlib import Path
from typing import List

from libqtile.config import EzClick, EzDrag, EzKey, Group, Key, Match, Mouse
from libqtile.lazy import lazy

terminal = "kitty"
home = Path.home()


# M - mod4 (Win key)
# A - mod1 (Left Alt key)
# S - shift
# C - control
# a, b, c, d - normal letters
# <space>, <Print> - special keys
keys: List[Key] = [
    EzKey("M-A-h", lazy.layout.left(), desc="Move focus to left"),
    EzKey("M-A-l", lazy.layout.right(), desc="Move focus to right"),
    EzKey("M-A-j", lazy.layout.down(), desc="Move focus down"),
    EzKey("M-A-k", lazy.layout.up(), desc="Move focus up"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    EzKey("M-S-h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    EzKey("M-S-l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    EzKey("M-S-j", lazy.layout.shuffle_down(), desc="Move window down"),
    EzKey("M-S-k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    EzKey("M-C-h", lazy.layout.grow_left(), desc="Grow window to the left"),
    EzKey("M-C-l", lazy.layout.grow_right(), desc="Grow window to the right"),
    EzKey("M-C-j", lazy.layout.grow_down(), desc="Grow window down"),
    EzKey("M-C-k", lazy.layout.grow_up(), desc="Grow window up"),
    EzKey("M-n", lazy.layout.normalize(), desc="Reset all window sizes"),
    EzKey("A-<Tab>", lazy.group.next_window(), desc="Focus next window in group"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    EzKey(
        "M-S-<Return>",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    # Toggle between different layouts as defined below
    EzKey("M-<Tab>", lazy.next_layout(), desc="Toggle between layouts"),
    EzKey("M-w", lazy.window.kill(), desc="Kill focused window"),
    EzKey("M-C-r", lazy.reload_config(), desc="Reload the config"),
    EzKey("M-r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    EzKey("A-<space>", lazy.window.toggle_floating()),
    # Custom apps
    EzKey(
        "M-s",
        lazy.spawn(f"{home}/bin/toggle_audio_device"),
        desc="Change output audio device",
    ),
    EzKey(
        "M-S-<space>",
        lazy.spawn(f"{home}/.local/bin/bookmarks"),
        desc="Show link bookmarks",
    ),
    EzKey("M-l", lazy.spawn(f"{home}/.local/bin/lock.sh"), desc="Lock the screen"),
    EzKey(
        "M-S-l", lazy.spawn("xscreensaver-command -lock"), desc="Lock the screen with xscreensaver"
    ),
    EzKey("<Print>", lazy.spawn(f"{home}/.local/bin/screenshot"), desc="Take a screenshot"),
    EzKey(
        "S-<Print>",
        lazy.spawn(f"{home}/.local/bin/screenshot screen"),
        desc="Take a screenshot of the full screen",
    ),
    EzKey("M-e", lazy.spawn("thunar"), desc="Open the file manager"),
    EzKey("M-<Return>", lazy.spawn(terminal), desc="Launch terminal"),
    EzKey(
        "M-<space>",
        lazy.spawn("/usr/bin/rofi -modi combi -combi-modi window,drun,run -show"),
        desc="Open rofi",
    ),
]

groups: List[Group] = [
    Group(**group_info)
    for group_info in (
        {"name": "Shell"},
        {"name": "WWW", "matches": [Match(wm_class="Navigator")]},
        {"name": "Code", "matches": [Match(wm_class="Code")]},
        {
            "name": "Chat",
            "matches": [
                Match(wm_class="Slack"),
                Match(wm_class="TelegramDesktop"),
                Match(wm_class="Pop"),
            ],
        },
        {"name": "x"},
        {"name": "y"},
        {"name": "z"},
    )
]

for index, group in enumerate(groups):
    index_key = index + 1
    keys.extend(
        [
            # Alt + letter of group = switch to group
            EzKey(
                f"M-{index_key}",
                lazy.group[group.name].toscreen(),
                desc=f"Switch to group {group.name}",
            ),
            # Win + shift + letter of group = switch to & move focused window to group
            EzKey(
                f"M-S-{index_key}",
                lazy.window.togroup(group.name, switch_group=False),
                desc=f"Switch to & move focused window to group {group.name}",
            ),
        ]
    )

# Drag floating layouts.
mouse: List[Mouse] = [
    EzDrag("M-1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    EzDrag("M-3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
]
