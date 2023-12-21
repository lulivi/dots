#!/opt/tools/python/3.9/python3
# Copyright (c) 2010 Aldo Cortesi
# Copyright (c) 2010, 2014 dequis
# Copyright (c) 2012 Randall Ma
# Copyright (c) 2012-2014 Tycho Andersen
# Copyright (c) 2012 Craig Barnes
# Copyright (c) 2013 horsik
# Copyright (c) 2013 Tao Sauvage
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
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
from typing import Callable, List

from keys import groups, keys, mouse  # NOQA
from libqtile import bar, hook, layout, widget
from libqtile.config import Match, Screen
from libqtile.layout.base import Layout
from libqtile.widget.base import _Widget

# Layouts
layouts_defaults = {
    "border_width": 2,
    "margin": 10,
    "border_focus": "#0000ff",
    "border_normal": "#000000",
    "border_on_single": True,
}
layouts: List[Layout] = [
    layout.Columns(**layouts_defaults),
    layout.Tile(**layouts_defaults),
    layout.Max(**layouts_defaults),
]

# Widgets and bars
widget_defaults = {
    "font": "sans",
    "fontsize": 12,
    "padding": 3,
}
extension_defaults = widget_defaults.copy()
_custom_separator_widget = widget.Sep(padding=5)
_default_widgets: Callable[[], List[_Widget]] = lambda: [
    widget.CurrentLayoutIcon(),
    _custom_separator_widget,
    widget.GroupBox(highlight_method="line", inactive="#888888"),
    _custom_separator_widget,
    widget.Prompt(),
    widget.Spacer(),
    widget.TaskList(),
    widget.Spacer(),
]
screens: List[Screen] = [
    Screen(
        bottom=bar.Bar(
            widgets=[
                *_default_widgets(),
                _custom_separator_widget,
                widget.TextBox("Custom config :happy:", name="default"),
                _custom_separator_widget,
                widget.Systray(),
                _custom_separator_widget,
                widget.Volume(fmt="🔊 {}"),
                _custom_separator_widget,
                widget.Backlight(
                    change_command=None,
                    backlight_name="intel_backlight",
                    fmt="💡 {}",
                ),
                _custom_separator_widget,
                widget.Wlan(
                    interface="wlp0s20f3",
                    format="🛜 {essid} {percent:2.0%}",
                ),
                _custom_separator_widget,
                widget.Battery(format="🔋 {percent:2.0%} {char}", show_short_text=False),
                _custom_separator_widget,
                widget.Clock(
                    fmt="📅 {}",
                    format="%y/%m/%d",
                    timezone="Europe/Madrid",
                ),
                widget.Clock(
                    fmt="ES {}",
                    format="%H:%M",
                    timezone="Europe/Madrid",
                ),
                widget.Clock(
                    fmt="CA {}",
                    format="%H:%M",
                    timezone="America/Los_Angeles",
                ),
                _custom_separator_widget,
                widget.QuickExit(default_text="[ Log out ]"),
            ],
            size=20,
            background="#00000055",
        ),
    ),
    Screen(
        bottom=bar.Bar(
            widgets=_default_widgets(),
            size=20,
        ),
    ),
]

# Other general config
dgroups_key_binder = None
dgroups_app_rules: list = []
follow_mouse_focus: bool = True
bring_front_click: bool = False
cursor_warp: bool = False
floating_layout: Layout = layout.Floating(
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="pinentry"),  # GPG key password entry
        Match(wm_class="Arandr"),
        Match(wm_class="Pop"),
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True
wmname = "LG3D"


@hook.subscribe.startup_once
def run_once():
    def _kill_and_run_executable(command: str) -> None:
        subprocess.run(f"pkill {command}")
        executable = shutil.which(command)

        if executable is not None:
            subprocess.Popen(executable)

    _kill_and_run_executable("dunst")
    _kill_and_run_executable("picom")


@hook.subscribe.startup
def run_allways():
    subprocess.Popen(str(Path.home().joinpath(".fehbg")))
    subprocess.Popen("notify-send 'Wellcome!'")
