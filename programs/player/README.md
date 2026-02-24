Player
------

CLI utility to inspect and switch configured audio output devices. Supports
`switch` and `i3` subcommands; `i3` emits i3blocks-compatible output and can be
used from a status bar. Relies on `wpctl` (WirePlumber) and optionally `pactl`.

Examples:

    cargo build --release
    ./target/release/player switch
    ./target/release/player i3
