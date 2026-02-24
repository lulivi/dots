Light
-----

Reads backlight brightness from `/sys/class/backlight/*` and prints an
i3blocks-compatible three-line output (full, short, color) showing percentage
brightness.

Build & run:

    cargo build --release
    ./target/release/light
