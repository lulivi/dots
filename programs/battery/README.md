Battery
-------

Reads battery status from `/sys/class/power_supply/BAT0` and emits i3blocks-
compatible three-line output (full, short, color). Intended for use in status
bars.

Build & run:

    cargo build --release
    ./target/release/battery
