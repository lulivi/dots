#!/usr/bin/env python3.8

import sys
from subprocess import check_output as run


def get_brightness(action, monitor):
    try:
        brightness = float(action)
        return brightness
    except ValueError:
        pass

    xrandr_verbose = run(["xrandr", "--current", "--verbose"], text=True).splitlines()
    for idx, line in enumerate(xrandr_verbose):
        if monitor in line:
            current_brightness = float(xrandr_verbose[idx+5].split()[-1])
            break

    if action == "+" and current_brightness < 1.0:
        return str(current_brightness + 0.1)

    if action == "-" and current_brightness > 0.0:
         return str(current_brightness - 0.1)

    print(f"Current brightness: {current_brightness}")
    return None


def main(args):
    monitors = list(
        map(
            lambda x: x.split()[-1],
            run(["xrandr", "--listactivemonitors"], text=True).strip().split("\n")[1:],
        )
    )
    chosen_brightness = get_brightness(args.pop(), monitors[0])
    
    if chosen_brightness:
        for monitor in monitors:
            run(["xrandr", "--output", monitor, "--brightness", str(chosen_brightness)])


if __name__ == "__main__":
    main(sys.argv)

