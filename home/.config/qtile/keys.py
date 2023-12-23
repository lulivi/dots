# vim:fileencoding=utf-8:ft=conf:foldmethod=marker
# Copyright (c) 2023 Luis Liñán
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
import itertools

from pathlib import Path
from typing import Dict, List, Union

from functions import darken_until_mouse_movement, show_keybindings, toggle_audio_device
from groups import groups
from libqtile.config import Drag, Key, KeyChord, Mouse
from libqtile.lazy import lazy
from settings import HOME_DIR

terminal = "kitty"

_WIN_KEY = "mod4"
_ALT_KEY = "mod1"
_SHIFT_KEY = "shift"
_CTRL_KEY = "control"
_SPACE_KEY = "space"
_PRINT_KEY = "Print"
_RET_KEY = "Return"

key_groups: Dict[str, List[Union[Key, KeyChord]]] = {
    "Windows": [
        Key([_WIN_KEY, _ALT_KEY], "h", lazy.layout.left(), desc="Move focus to left"),
        Key([_WIN_KEY, _ALT_KEY], "l", lazy.layout.right(), desc="Move focus to right"),
        Key([_WIN_KEY, _ALT_KEY], "j", lazy.layout.down(), desc="Move focus down"),
        Key([_WIN_KEY, _ALT_KEY], "k", lazy.layout.up(), desc="Move focus up"),
        # Move windows between left/right columns or move up/down in current stack.
        # Moving out of range in Columns layout will create new column.
        Key(
            [_WIN_KEY, _SHIFT_KEY],
            "h",
            lazy.layout.shuffle_left(),
            desc="Move window to the left",
        ),
        Key(
            [_WIN_KEY, _SHIFT_KEY],
            "l",
            lazy.layout.shuffle_right(),
            desc="Move window to the right",
        ),
        Key([_WIN_KEY, _SHIFT_KEY], "j", lazy.layout.shuffle_down(), desc="Move window down"),
        Key([_WIN_KEY, _SHIFT_KEY], "k", lazy.layout.shuffle_up(), desc="Move window up"),
        # Grow windows. If current window is on the edge of screen and direction
        # will be to screen edge - window would shrink.
        Key([_WIN_KEY, _CTRL_KEY], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
        Key(
            [_WIN_KEY, _CTRL_KEY],
            "l",
            lazy.layout.grow_right(),
            desc="Grow window to the right",
        ),
        Key([_WIN_KEY, _CTRL_KEY], "j", lazy.layout.grow_down(), desc="Grow window down"),
        Key([_WIN_KEY, _CTRL_KEY], "k", lazy.layout.grow_up(), desc="Grow window up"),
        Key([_WIN_KEY], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
        Key([_ALT_KEY], "Tab", lazy.group.next_window(), desc="Focus next window in group"),
        Key([_WIN_KEY], "w", lazy.window.kill(), desc="Kill focused window"),
        Key(
            [_ALT_KEY],
            _SPACE_KEY,
            lazy.window.toggle_floating(),
            desc="Toggle window floating mode",
        ),
    ],
    "Layouts": [
        # Toggle between split and unsplit sides of stack.
        # Split = all windows displayed
        # Unsplit = 1 window displayed, like Max layout, but still with
        # multiple stack panes
        Key(
            [_WIN_KEY, _SHIFT_KEY],
            _RET_KEY,
            lazy.layout.toggle_split(),
            desc="Toggle between split and unsplit sides of stack",
        ),
        # Toggle between different layouts as defined below
        Key([_WIN_KEY], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    ],
    "Qtile": [
        Key([_WIN_KEY, _CTRL_KEY], "r", lazy.reload_config(), desc="Reload the config"),
        Key([_WIN_KEY], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
        Key([_WIN_KEY], "k", show_keybindings, desc="Show Qtile keybindings"),
    ],
    "Apps": [
        Key(
            [_WIN_KEY],
            "s",
            toggle_audio_device,
            desc="Change output audio device",
        ),
        Key(
            [_WIN_KEY],
            "t",
            lazy.spawn(str(HOME_DIR.joinpath("git", "qtile", "scripts", "xephyr"))),
        ),
        Key(
            [_WIN_KEY, _SHIFT_KEY],
            _SPACE_KEY,
            lazy.spawn(str(HOME_DIR.joinpath(".local", "bin", "bookmarks"))),
            desc="Show link bookmarks",
        ),
        KeyChord(
            [_WIN_KEY],
            "l",
            [
                Key(
                    [],
                    "p",
                    lazy.spawn(str(HOME_DIR.joinpath(".local", "bin", "lock.sh"))),
                    desc="Lock the screen pixelating it",
                ),
                Key(
                    [],
                    "x",
                    lazy.spawn("xscreensaver-command -lock"),
                    desc="Lock the screen with xscreensaver",
                ),
                Key(
                    [],
                    "d",
                    darken_until_mouse_movement,
                    desc="Darken the screen until mouse movement",
                ),
            ],
        ),
        KeyChord(
            [_WIN_KEY],
            "o",
            [
                Key(
                    [],
                    "d",
                    lazy.spawn(f'code {HOME_DIR.joinpath("git", "dots")}'),
                    desc="Open dots",
                )
            ],
        ),
        Key(
            [],
            _PRINT_KEY,
            lazy.spawn(str(HOME_DIR.joinpath(".local", "bin", "screenshot"))),
            desc="Take a screenshot",
        ),
        Key(
            [_SHIFT_KEY],
            _PRINT_KEY,
            lazy.spawn(f'{HOME_DIR.joinpath(".local", "bin", "screenshot")} screen'),
            desc="Take a screenshot of the full screen",
        ),
        Key([_WIN_KEY], "e", lazy.spawn("thunar"), desc="Open the file manager"),
        Key([_WIN_KEY], _RET_KEY, lazy.spawn(terminal), desc="Launch terminal"),
        Key(
            [_WIN_KEY],
            _SPACE_KEY,
            lazy.spawn("/usr/bin/rofi -modi combi -combi-modi window,drun,run -show"),
            desc="Open rofi",
        ),
    ],
}

for index, group in enumerate(groups):
    index_key: str = str(index + 1)
    key_groups["Windows"].extend(
        [
            # Alt + index of group = switch to group
            Key(
                [_WIN_KEY],
                index_key,
                lazy.group[group.name].toscreen(),
                desc=f"Switch to group {group.name}",
            ),
            # Win + shift + index of group = move focused window to group
            Key(
                [_WIN_KEY, _SHIFT_KEY],
                index_key,
                lazy.window.togroup(group.name, switch_group=False),
                desc=f"Move focused window to group {group.name}",
            ),
        ]
    )

keys: List[Union[Key, KeyChord]] = list(itertools.chain(*key_groups.values()))

# Drag floating layouts.
mouse: List[Mouse] = [
    Drag([_WIN_KEY], "1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([_WIN_KEY], "3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
]
