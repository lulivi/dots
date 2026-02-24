Display detector
----------------

Small binary that queries `swaymsg -t get_outputs` and prints a short token
identifying the current display setup. Prints `home` when an external
ViewSonic VA2719-2K monitor is present, `laptop` when only the internal
LG panel is active.

Build & run:

    cargo build --release
    ./target/release/displaycfg
