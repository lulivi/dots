# File definition and selection

The [backstore](./backstore.py) script will link files from this repository
[home](../home/) directory to your `$HOME`. Each of your home dotfiles will be
asociated to a `key`, for you to be able to select wich ones you want to link.

## backstore tool

To know more about `backstore` tool, run the following command from the
repository root directory:

```bash
python automation/backstore.py --help
```

## File definition

Every wanted file definition will be located in [files.toml](./files.toml) with
the following format (in [TOML](https://github.com/toml-lang/toml) language):

```toml
# The choosen key to identify the file
[<key name>]
# The $HOME relative path of the file (i.e.: for /home/user/.vimrc would 
# be relpath = ".vimrc")
relpath = "<home relative file path>"
# A brief description of the file
description = "<description>"
# A list with the required packages by the file
packages = ["<package 1>", "<package 2>"]
```

> For example:
> 
> ```toml
> [bin-lock]
> relpath = ".bin/lock.sh"
> description = "Lock screen with a pixelated screenshot of your desktop."
> packages = ["xorg-xdpyinfo", "gawk", "maim", "imagemagick", "i3lock"]
> ```

## Selected files

The selected files will be located in a new `selected_files.txt` file with one
`key` by line:

```
<key 1>
<key 2>
...
```

> For example:
> 
> ```
> bin-lock
> pcmanfm
> ```