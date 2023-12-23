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
from typing import Dict, List, Union

from libqtile.config import Key, KeyChord
from libqtile.lazy import lazy
from libqtile.utils import send_notification
from settings import KEYBINDINGS_FILE


@lazy.function
def darken_until_mouse_movement(*args, **kwargs) -> None:
    """Turn off the screen until mouse move.

    Note that this only fully work for the laptop screen. The external screens will not be totally
    turned off.

    """
    BASE_DIR = Path("/sys/class/backlight/intel_backlight")
    MAX_BRIGHTNESS = BASE_DIR.joinpath("max_brightness")
    CURRENT_BRIGHTNESS = BASE_DIR.joinpath("brightness")
    CURRENT_BRIGHTNESS.write_text("0")
    subprocess.run(
        ["/home/luis/.screenlayout/brightness.py", "0.01"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    subprocess.run(
        ["cnee", "--record", "--mouse", "--events-to-record", "1"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    subprocess.run(
        ["/home/luis/.screenlayout/brightness.py", "1"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    CURRENT_BRIGHTNESS.write_text(MAX_BRIGHTNESS.read_text())


@lazy.function
def toggle_audio_device(*args, **kwargs) -> None:
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

        for index, line in enumerate(KEYBINDINGS_FILE.read_text().splitlines()):
            tk.Label(root, text=line, font=("Fira Code", 11)).grid(row=index, column=0, sticky="w")
        root.mainloop()

    t = Thread(target=_show_keybindings)
    t.start()


def save_keybindings(key_groups: Dict[str, List[Union[Key, KeyChord]]]) -> None:
    pass

