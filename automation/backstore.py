#!/usr/bin/env python3.7
"""Manage dotfiles.

This module creates symbolic links of the configuration files in your home
directory structure. This script can also delete those symbolic links. You have
to define every file-link relations in ``files.json`` with the following
format:

{
    "<id>": {
        "srcfile": "<path in repository>",
        "symlink": "<path in home folder>"
    }
    ...
}

For example:

{
    "SCR022": {
        "srcfile": "scripts/xrandr_scrn_duplicated.sh",
        "symlink": ".screenlayout/xrandr_scrn_duplicated.sh"
    },
    "GIT001": {
        "srcfile": "git/.gitconfig",
        "symlink": ".gitconfig"
    }
}

Also you have to create the file ``selected_files.txt`` in where the selected
ids would be. If you want to select every relation in ``files.json``, just
write ``ALL`` in the file:

<id 1>
<id 2>
...

For example:

SCR003
SCR013
SCR020

Examples:
    Print selected files:
        python backstore.py -p

    Link selected files:
        python backstore.py -l

    Delete selected files link:
        python backstore.py -d
"""
import sys
import json
import argparse

from typing import List, Dict, Tuple
from pathlib import Path
from blessings import Terminal

TERM = Terminal()
HOME_PATH: Path = Path.home()
AUTOMATION_PATH: Path = Path(__file__).resolve().parent
ALL_FILES_PATH: Path = AUTOMATION_PATH.joinpath("files.json").resolve()
SEL_FILES_PATH: Path = AUTOMATION_PATH.joinpath("selected_files.txt").resolve()
REPO_PATH: Path = AUTOMATION_PATH.parent

FILE_STATUS = {
    # Exists
    True: {
        "?": TERM.yellow,
        # Regulr file
        "R": TERM.green,
        # Symlik
        "L": TERM.cyan,
        # Directory
        "D": TERM.magenta,
    },
    # Doesn't exist
    False: {"?": TERM.red},
}


def _get_file_status_string(
    file_path: Path, relative_to: Path, verbose: bool = False
) -> Tuple[str, str]:
    """Return file path string with color status.

    Args:
        file_path: Path from where check status.
        relative_to: Path relative-to in no verbose mode.
        verbose: Print info in verbose mode.

    Returns:
        Path string with status formating.
        Symbol with found status of the link.
    """
    file_found: bool = False
    file_found_symbol: str = f"{TERM.red}✖{TERM.normal}"
    file_type: str = "?"
    if file_path.exists():
        file_found = True
        file_found_symbol = f"{TERM.green}✔{TERM.normal}"
        if file_path.is_symlink():
            file_type = "L"
        elif file_path.is_file():
            file_type = "R"
        elif file_path.is_dir():
            file_type = "D"
    file_str = file_path if verbose else file_path.relative_to(relative_to)
    return (
        f"{FILE_STATUS[file_found][file_type]}{file_str}{TERM.normal}",
        file_found_symbol,
    )


def print_file_row(file_object: Dict[str, str], verbose: bool = False) -> None:
    """Print file row with it appropiate format.

    Args:
        file_object: Dictionary with id, source file path and link file path.
        verbose: Print info in verbose mode.
    """
    srcfile = REPO_PATH.joinpath(file_object["srcfile"])
    symlink = HOME_PATH.joinpath(file_object["symlink"])
    srcfile_status = _get_file_status_string(srcfile, REPO_PATH, verbose)[0]
    symlink_status, found = _get_file_status_string(
        symlink, HOME_PATH, verbose
    )
    if verbose:
        print(
            f"{found} {file_object['id']}\n    ├─ {srcfile_status}\n"
            f"    └─ {symlink_status}"
        )
    else:
        print(
            f"{found} {file_object['id']}: "
            f"{srcfile_status} -> {symlink_status}"
        )


def print_selected_files(
    selected_files_list: List[Dict[str, str]], verbose: bool = False
) -> None:
    """Print selected files.

    Args:
        selected_files_list: List of selected files.
        verbose: Print info in verbose mode.
    """
    if verbose:
        print("\n< ID >\n    ├ <SOURCE_PATH>\n    └─ <TARGET_PATH>\n")
    else:
        print("\n< ID >: <SOURCE_PATH> -> <TARGET_PATH>\n")
    for sel_file in selected_files_list:
        print_file_row(sel_file, verbose)

    print()


def link_selected_files(
    selected_files_list: List[Dict[str, str]], verbose: bool = False
) -> None:
    """Link selected files.

    Args:
        selected_files_list: List of selected files.
        verbose: Print info in verbose mode.
    """
    print()
    for selected_file in selected_files_list:
        srcfile = REPO_PATH.joinpath(selected_file["srcfile"])
        symlink = HOME_PATH.joinpath(selected_file["symlink"])
        if not symlink.parent.exists():
            symlink.parent.mkdir(parents=True)
        try:
            symlink.symlink_to(srcfile, srcfile.is_dir())
        except FileExistsError:
            print(
                f"{TERM.yellow + TERM.bold}-{TERM.normal} "
                f'File "{symlink.name}" is already a symlink.'
            )
        else:
            print(
                f"{TERM.green}✔{TERM.normal} "
                f'File "{srcfile.name}" linked correctly.'
            )


def delete_selected_files(
    selected_files_list: List[Dict[str, str]], verbose: bool = False
) -> None:
    """Delete selected files.

    Args:
        selected_files_list: List of selected files.
        verbose: Print info in verbose mode.
    """
    print_selected_files(selected_files_list, verbose)
    try:
        if (
            input("Are you sure to delete previous links? (yes/no): ")
            .strip()
            .lower()
            != "yes"
        ):
            raise KeyboardInterrupt
    except KeyboardInterrupt:
        print("Aborting symlinks deletion.")
        return
    print()
    for selected_file in selected_files_list:
        symlink = HOME_PATH.joinpath(selected_file["symlink"])
        try:
            symlink.unlink()
        except FileNotFoundError:
            print(f'File "{symlink.name}" not found.')
        else:
            print(f'File "{symlink.name}" deleted succesfully.')


def main():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    exclusive_group = parser.add_mutually_exclusive_group(required=True)
    exclusive_group.add_argument(
        "-p", "--print", action="store_true", help="print selected files"
    )
    exclusive_group.add_argument(
        "-l",
        "--link",
        action="store_true",
        help="link targets to their sources",
    )
    exclusive_group.add_argument(
        "-d", "--delete", action="store_true", help="delete local symlinks"
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="print info verbosely"
    )

    args = parser.parse_args()

    with SEL_FILES_PATH.open() as f:
        selected_ids_list = list(map(str.strip, f.read().splitlines()))

    with ALL_FILES_PATH.open() as f:
        files_json = json.load(f)
        selected_files_list = (
            [
                {"id": selected_id, **files}
                for selected_id, files in files_json.items()
            ]
            if selected_ids_list == ["ALL"]
            else [
                {"id": selected_id, **files_json[selected_id]}
                for selected_id in selected_ids_list
            ]
        )

    if not selected_files_list:
        sys.exit("There are no selected files.")

    verbose_status = "verbose" if args.verbose else "no verbose"
    if args.print:
        print(f"Listing selected files in {verbose_status} mode.")
        print_selected_files(selected_files_list, args.verbose)
    elif args.link:
        print(f"Linking selected files in {verbose_status} mode.")
        link_selected_files(selected_files_list, args.verbose)
    elif args.delete:
        print(f"Deleting selected links in {verbose_status} mode.")
        delete_selected_files(selected_files_list, args.verbose)


if __name__ == "__main__":
    main()
