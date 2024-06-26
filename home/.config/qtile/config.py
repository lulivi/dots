#!/opt/tools/python/3.9/python3
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

# Pip dependencies:
# - qtile[widgets] (or the git version .[widgets])
# - cffi, cairocffi, xcffib
# - mypy (qtile check)
# - iwlib (wifi widget)
# - psutil (multiple widget)
# python -m pip install cffi cairocffi xcffib mypy iwlib psutil <path_to_qtile_git>[widgets]
# APT dependencies:
# - libpangocairo-1.0-0, libiw-dev, python3-tk
# sudo apt install libpangocairo-1.0-0, libiw-dev, python3-tk

from typing import Union

import hooks

from groups import groups
from keys import keys, mouse
from layouts import floating_layout, layouts
from screens import screens

dgroups_key_binder = None
dgroups_app_rules: list = []
follow_mouse_focus: bool = True
bring_front_click: Union[str, bool] = "floating_only"
cursor_warp: bool = False
auto_fullscreen = True
focus_on_window_activation = "focus"
reconfigure_screens = True
auto_minimize = True
wmname = "LG3D"
