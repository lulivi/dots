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

Every wanted file definition will be located in [files.json](./files.json) with
the following format (in [JSON](https://www.json.org/json-en.html) language):

```json
{
    # The choosen key to identify the file
    "<key name>": {
        # The $HOME relative path of the file (i.e.: for /home/user/.vimrc would 
        # be "relpath": ".vimrc")
        "relpath": "<home relative file path>",
        # A brief description of the file
        "description": "<description>",
        # A list with the required packages by the file
        "packages": ["<package 1>", "<package 2>"]
    }
}
```

> For example:
> 
> ```json
> "bin-lock": {
>   "relpath": ".local/bin/lock.sh",
>   "description": "Lock screen with a pixelated screenshot of your desktop.",
>   "packages": [
>     "xorg-xdpyinfo",
>     "maim",
>     "imagemagick",
>     "i3lock"
>   ]
> },
> ```

## Selected files

The selected files will be located in a new `selected_files.txt` file with one
`key` by line:

```plain
<key 1>
<key 2>
...
```

> For example:
> 
> ```plain
> bin-lock
> pcmanfm
> ```