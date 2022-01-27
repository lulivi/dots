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
    // The $HOME relative path of the file (i.e.: for /home/<user>/.vimrc would
    // be ".vimrc")
    "<home relative file path>": {
        // A brief description of the file
        "description": "<description>",
        // A list with the required packages by the file
        "packages": ["<package 1>", "<package 2>"]
    }
}
```

> For example:
>
> ```json
> ".local/bin/lock.sh": {
>   "description": "Lock screen with a pixelated screenshot of your desktop.",
>   "packages": [
>     "xorg-xdpyinfo",
>     "maim",
>     "imagemagick",
>     "i3lock"
>   ]
> },
> ".config/pcmanfm/default/pcmanfm.conf": {
>   "description": "LXDE file manager.",
>   "packages": [
>     "pcmanfm"
>   ]
> },
> ```

## Selected files

The selected files will be located in a new `selected_files.txt` file with one
`home relative file path` by line:

```plain
<path 1>
<path 2>
...
```

> For example:
>
> ```plain
> .local/bin/lock.sh
> .config/pcmanfm/default/pcmanfm.conf
> ```
