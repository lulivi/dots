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
import shutil
import subprocess

from pathlib import Path
from typing import List

from functions import save_keybindings
from keys import key_groups
from libqtile import hook
from libqtile.backend.base.window import WindowType
from libqtile.utils import send_notification


@hook.subscribe.startup_once
def when_startup_once():
    def _kill_and_run_executable(command: str, *args: List[str]) -> None:
        subprocess.run(["pkill", command])
        executable = shutil.which(command)

        if executable is not None:
            subprocess.Popen([executable, *args])

    _kill_and_run_executable("dunst")
    _kill_and_run_executable("compton")
    _kill_and_run_executable("xscreensaver", "-no-splash")


@hook.subscribe.startup
def when_startup():
    subprocess.Popen([str(Path.home().joinpath(".fehbg"))])
    save_keybindings(key_groups)
    send_notification("Wellcome, Luis!", "Enjoy c:")


@hook.subscribe.screen_change
def when_screen_change(*args, **kwargs):
    subprocess.Popen([str(Path.home().joinpath(".fehbg"))])


@hook.subscribe.client_name_updated
def when_client_name_is_changed(client: WindowType):
    if client.name == "ncspot":
        client.togroup("Music", switch_group=True)


@hook.subscribe.client_managed
def when_client_is_managed(client: WindowType):
    if client.get_wm_class() == "Pop":
        client.enable_floating()
        client.keep_above(True)
        client.move_to_top()
        return


@hook.subscribe.enter_chord
def enter_chord(chord_name):
    send_notification("qtile", f"Started {chord_name!r} key chord.")


@hook.subscribe.leave_chord
def leave_chord():
    send_notification("qtile", "Key chord exited")

