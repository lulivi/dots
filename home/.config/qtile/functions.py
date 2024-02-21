# vim:fileencoding=utf-8:foldmethod=marker
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

import subprocess
import tkinter as tk

from dataclasses import dataclass
from pathlib import Path
from threading import Thread
from typing import Dict, List, Tuple, Union

from libqtile.config import Key, KeyChord
from libqtile.core.manager import Qtile
from libqtile.lazy import lazy
from libqtile.utils import send_notification as qtile_notification
from settings import BIN_DIR, KEYBINDINGS_FILE, LOCAL_BIN_DIR, SCREEN_LAYOUT_DIR


def send_notification(title: str, message: str = "") -> None:
    qtile_notification(title=title, message=message)


def quiet_run(*args: str, print_stdout: bool = False) -> str:
    return subprocess.run(
        list(args),
        stdout=subprocess.PIPE,
        encoding="utf-8",
    ).stdout


def run_script(script_path: Path) -> None:
    stdout = quiet_run(str(script_path))
    if stdout:
        send_notification(script_path.name, stdout)


@lazy.function
def run_local_bin_script(_: Qtile, script_name: str) -> None:
    run_script(LOCAL_BIN_DIR.joinpath(script_name))


@lazy.function
def run_bin_script(_: Qtile, script_name: str) -> None:
    run_script(BIN_DIR.joinpath(script_name))


@lazy.function
def testing(_: Qtile) -> None:
    send_notification("Testiiiing")


@lazy.function
def darken_until_mouse_movement(qtile: Qtile) -> None:
    """Turn off the screen until mouse move."""
    quiet_run(str(SCREEN_LAYOUT_DIR.joinpath("screens_off.sh")))
    quiet_run("cnee", "--record", "--mouse", "--keyboard", "--events-to-record", "1")
    quiet_run(str(LOCAL_BIN_DIR.joinpath("reconfigure_screens")))


@lazy.function
def toggle_audio_device(_: Qtile) -> None:
    """Swap the devices from Headphones to Speakers and vice versa."""
    amixer_speaker_info = subprocess.run(
        ["amixer", "get", "Speaker"], stdout=subprocess.PIPE, text=True
    ).stdout
    current_speaker = "Speaker"
    next_speaker = "Headphone"

    if "[on]" not in amixer_speaker_info:
        current_speaker, next_speaker = next_speaker, current_speaker

    send_notification("Changing audio device", f"Selecting {next_speaker}")
    subprocess.run(["amixer", "set", current_speaker, "mute"], stdout=subprocess.DEVNULL)
    subprocess.run(["amixer", "set", next_speaker, "unmute"], stdout=subprocess.DEVNULL)
    subprocess.run(["amixer", "set", "Master", "unmute"], stdout=subprocess.DEVNULL)


@lazy.function
def show_keybindings(_) -> None:
    def _show_keybindings():
        root = tk.Tk()
        inner_frame = tk.Frame(root)
        inner_frame.pack(padx=20, pady=20)

        for index, line in enumerate(KEYBINDINGS_FILE.read_text().splitlines()):
            tk.Label(inner_frame, text=line, font=("Fira Code", 11)).grid(
                row=index, column=0, sticky="w"
            )

        root.mainloop()

    t = Thread(target=_show_keybindings)
    t.start()


def save_keybindings(key_groups: Dict[str, List[Union[Key, KeyChord]]]) -> None:
    @dataclass
    class FlattenKey:
        bindings: List[str]
        description: str

        @property
        def str_binding(self) -> str:
            return f"<{'> + <'.join(self.bindings)}>".replace("mod4", "Win").replace("mod1", "Alt")

    def key_binding_string(key: Union[Key, KeyChord]) -> str:
        key_binding = ""
        if key.modifiers:
            key_binding = f"{' + '.join(key.modifiers)} + "
        return f"{key_binding}{key.key}"

    def flatten_key(key: Union[KeyChord, Key], key_prefix: str = "") -> List[FlattenKey]:
        if isinstance(key, Key):
            bindings = []
            if key.key == "Escape":
                return []
            if key_prefix:
                bindings.append(key_prefix)
            bindings.append(key_binding_string(key))
            return [FlattenKey(bindings, key.desc)]

        flattened_keys = []
        parent_key_prefix = key_binding_string(key)
        for subkey in key.submappings:
            flattened_keys.extend(flatten_key(subkey, parent_key_prefix))

        return flattened_keys

    def flatten_keys(keys: List[Union[KeyChord, Key]]) -> List[FlattenKey]:
        flattened_keys = []
        for key in keys:
            flattened_keys.extend(flatten_key(key))
        return flattened_keys

    bindings: List[str] = []
    descriptions: List[str] = []
    flattened_key_groups: List[Tuple[str, List[FlattenKey]]] = [
        (group_name, flatten_keys(keys)) for group_name, keys in key_groups.items()
    ]
    for group_name, flattened_keys in flattened_key_groups:
        bindings.append("")
        bindings.append(group_name)
        descriptions.append("")
        descriptions.append("")
        for key in flattened_keys:
            bindings.append(key.str_binding)
            descriptions.append(key.description)

    max_len = max(map(len, bindings))

    def print_key(binding, description):
        current_key = binding
        if description:
            current_key = f"{current_key}  {'-'* (max_len - len(binding) + 2)} {description}"
        return current_key

    keys_strs = [
        print_key(binding, description)
        for binding, description in zip(bindings[1:], descriptions[1:])
    ]
    half_list = len(keys_strs) // 2
    left_part, right_part = keys_strs[:half_list], keys_strs[half_list:]
    max_len = max(map(len, left_part))
    final_keys_strs = [
        f"{left:<{max_len + 5}}{right}" for left, right in zip(left_part, right_part)
    ]
    KEYBINDINGS_FILE.write_text("\n".join(final_keys_strs))
