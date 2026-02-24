Network
-------

Uses `nmcli` to query Wi‑Fi state and prints i3blocks-compatible output for the
currently connected network (SSID and signal percentage). Requires NetworkManager
(`nmcli`) to be available.

Build & run:

    cargo build --release
    ./target/release/network
