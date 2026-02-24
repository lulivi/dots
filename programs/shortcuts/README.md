Shortcuts
---------

Loads a TOML file at `~/.shortcuts`, augments entries with executable scripts
found in a local `home/bin` (repository) and `~/bin`, displays options using
`rofi` and runs the selected command via the shell (non-blocking).

Build & run:

    cargo build --release
    ./target/release/shortcuts
