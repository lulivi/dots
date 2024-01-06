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
from typing import List

from libqtile import bar, widget
from libqtile.config import Screen
from libqtile.lazy import lazy
from libqtile.widget import base, tasklist
from libqtile.widget.base import _Widget


class ClossableTaskList(tasklist.TaskList):
    def __init__(self, **config) -> None:
        super().__init__(**config)
        self.add_callbacks({"Button2": self.close_window})

    def close_window(self):
        if self.clicked:
            self.clicked.kill()


class ReloadConfig(base._TextBox):
    def __init__(self, **config):
        super().__init__("[ Reload config ]", **config)
        self.add_callbacks({"Button1": lazy.reload_config()})


def _default_widgets() -> List[_Widget]:
    return [
        widget.CurrentLayoutIcon(),
        _custom_separator_widget,
        widget.GroupBox(highlight_method="line", inactive="#888888"),
        _custom_separator_widget,
        widget.Prompt(),
        widget.Spacer(),
        ClossableTaskList(margin=5, highlight_method="block"),
        widget.Spacer(),
    ]


widget_defaults = {
    "font": "sans",
    "fontsize": 12,
    "padding": 3,
}
extension_defaults = widget_defaults.copy()
_custom_separator_widget = widget.Sep(padding=5)
screens: List[Screen] = [
    Screen(
        bottom=bar.Bar(
            widgets=[
                *_default_widgets(),
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
                ReloadConfig(),
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

del _default_widgets
