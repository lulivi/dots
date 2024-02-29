#!/usr/bin/env bash
# Source: https://github.com/qtile/qtile/blob/master/scripts/xephyr

source $HOME/apps/qtile_venv/bin/activate

HERE=$(dirname $(readlink -f $0))
SCREEN_SIZE=${SCREEN_SIZE:-1400x1000}
XDISPLAY=${XDISPLAY:-:1}
LOG_LEVEL=${LOG_LEVEL:-INFO}
LOG_PATH=${LOG_PATH:-/home/luis/.local/share/qtile/qtile.log}
if [[ -z $PYTHON ]]; then
    PYTHON=python
fi
APP=${APP:-$($PYTHON -c "from libqtile.utils import guess_terminal; print(guess_terminal())")}


Xephyr +extension RANDR -screen ${SCREEN_SIZE} ${XDISPLAY} -ac &
XEPHYR_PID=$!
(
  sleep 1
  env DISPLAY=${XDISPLAY} QTILE_XEPHYR=1 qtile start -l ${LOG_LEVEL} -p ${LOG_PATH} $@ &
  QTILE_PID=$!
  env DISPLAY=${XDISPLAY} &
  wait $QTILE_PID
  kill $XEPHYR_PID
)
