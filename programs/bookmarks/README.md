Bookmarks
---------

Binary that reads a TOML bookmarks file at `~/.bookmarks`, shows a selection
menu using `rofi` (15 visible lines) and opens the chosen URL with `xdg-open`.

Build & run:

    cargo build --release
    ./target/release/bookmarks
