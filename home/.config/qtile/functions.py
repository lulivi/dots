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
    pass

