#!/usr/bin/env python3.7
"""Manage dotfiles.

This module creates symbolic links of the configuration files in your home
directory structure. This script can also delete those symbolic links. You have
to define every file ``files.toml`` with the following format:

    [<id>]
    relpath = "<relative_path>"
    packages = ["<package1>", "<package2>"]

For example:

    [scripts-add_log_entry]
    relpath = "scripts/add_log_entry"

    [pcmanfm]
    relpath = ".config/pcmanfm/default/pcmanfm.conf"
    packages = ["pcmanfm"]

    [scripts-dec_to_hex]
    relpath = "scripts/dec_to_hex.sh"

Also you have to create the file ``selected_files.txt`` in where the selected
ids would be. If you want to select every relation in ``files.json``, just
write ``ALL`` in the file:

<id 1>
<id 2>
...

For example:

scripts-add_log_entry
pcmanfm

The printed files will follow this structure:

For normal mode:

    < ID >: <RELATIVE PATH>
    < ID >: <RELATIVE PATH>
    ...

For verbose mode:

< ID >
    ├─ PATH=<RELATIVE PATH>
    ├─ DESC=<DESCRIPTION>
    └─ PKGS=<PACKAGES>

< ID >
    ├─ PATH=<RELATIVE PATH>
    ├─ DESC=<DESCRIPTION>
    └─ PKGS=<PACKAGES>
...

Examples:
    Print selected files:
        python backstore.py -p

    Print all files:
        python blackstore.py

    Link selected files:
        python backstore.py -l

    Delete selected files link:
        python backstore.py -d
"""
import sys
import toml
import colored
import argparse
import functools

from typing import List, Dict, Tuple, NamedTuple
from pathlib import Path
from colored import stylize

HOME_PATH: Path = Path.home()
AUTOMATION_PATH: Path = Path(__file__).resolve().parent
ALL_FILES_PATH: Path = AUTOMATION_PATH.joinpath("files.toml").resolve()
SEL_FILES_PATH: Path = AUTOMATION_PATH.joinpath("selected_files.txt").resolve()
REPO_HOME_PATH: Path = AUTOMATION_PATH.parent.joinpath("home").resolve()


class HomeFile(NamedTuple):
    """File representation.

    :ivar key: file identifier.
    :ivar relpath: relative path of the file.
    :ivar description: brief description of the file.
    :ivar packages: required packages related to the file.
    :ivar selected: whether the file is selected for its print.
    """

    key: str
    relpath: Path
    description: str = ""
    packages: List[str] = []


def _color_file(file_relpath: Path) -> str:
    """Return a colored file path string.

    The color will tell the file type in the `$HOME` directory.

    :param file_relpath: home-relative file path.
    :returns: the colored file string.

    """
    link_name_path = HOME_PATH.joinpath(file_relpath)

    if link_name_path.is_symlink():
        if link_name_path.resolve() == REPO_HOME_PATH.joinpath(file_relpath):
            style = colored.fg("cyan")
        else:
            style = colored.fg("yellow")
    elif link_name_path.exists():
        style = colored.fg("yellow")
    else:
        style = colored.bg("red") + colored.fg("black")

    return stylize(str(link_name_path), style)


def print_selected_files(
    selected_files: List[HomeFile], verbose: bool = False
) -> None:
    """Print selected files.

    :param selected_files: list of selected files.
    :param verbose: print info in verbose mode.

    """

    def _print_file(file: HomeFile, verbose: bool = False) -> None:
        """Print file row with it appropiate format.

        :param file: file to print.
        :param verbose: whether to use verbosity in the print function.

        """
        if verbose:
            print(
                f"{file.key}\n"
                f"    ├─ PATH={_color_file(file.relpath)}\n"
                f"    ├─ DESC={file.description}\n"
                f"    └─ PKGS={file.packages}\n"
            )
        else:
            print(f"{file.key}: {_color_file(file.relpath)}")

    list(map(functools.partial(_print_file, verbose=verbose), selected_files,))
    print()


def _print_with_attr(text: str, attributes: str):
    print(stylize(text, attributes))


def link_selected_files(
    selected_files: List[HomeFile], verbose: bool = False, force: bool = False
) -> None:
    """Link selected files.

    :param selected_files: list of selected files.
    :param verbose: print info in verbose mode.

    """
    for selected_file in selected_files:
        target_path = REPO_HOME_PATH.joinpath(selected_file.relpath)
        link_name_path = HOME_PATH.joinpath(selected_file.relpath)

        if force:
            try:
                link_name_path.unlink()
            except FileNotFoundError:
                pass
        else:
            if link_name_path.is_symlink():
                if link_name_path.resolve() == target_path:
                    _print_with_attr(
                        f'{selected_file.key}: File "{str(link_name_path)}" '
                        "is already linked.",
                        colored.fg("yellow"),
                    )
                else:
                    _print_with_attr(
                        f'{selected_file.key}: File "{str(link_name_path)}" '
                        f'is linked to "{str(link_name_path.resolve())}" '
                        f'instead of "{str(target_path)}" Please remove it '
                        "manually.",
                        colored.fg("red"),
                    )
                continue
            elif link_name_path.exists():
                _print_with_attr(
                    f'{selected_file.key}: File "{str(link_name_path)}" '
                    "exists and it is not a symbolic link. Ignoring.",
                    colored.fg("red"),
                )
                continue
            elif not link_name_path.parent.exists():
                link_name_path.parent.mkdir(parents=True, exist_ok=True)

        link_name_path.symlink_to(target_path, target_path.is_dir())
        _print_with_attr(
            f'{selected_file.key}: File "{str(link_name_path)}" linked '
            "correctly.",
            colored.fg("green"),
        )

    print()


def delete_selected_links(
    selected_files: List[HomeFile], verbose: bool = False, force: bool = False
) -> None:
    """Delete selected files.

    :param selected_files: list of selected files.
    :param verbose: print info in verbose mode.
    :param force: whether to always delete the link or not.

    """
    print_selected_files(selected_files, verbose)

    question = (
        input("Are you sure you want to delete previous links? (yes/no): ")
        .strip()
        .lower()
    )

    if question != "yes":
        print("Aborting symlinks deletion.")
        return

    print()

    for selected_file in selected_files:
        target_path = REPO_HOME_PATH.joinpath(selected_file.relpath)
        link_name_path = HOME_PATH.joinpath(selected_file.relpath)

        if not force:
            if link_name_path.is_symlink():
                if link_name_path.resolve() != target_path:
                    _print_with_attr(
                        f'{selected_file.key}: File "{str(link_name_path)}" '
                        f'is linked to "{str(link_name_path.resolve())}" '
                        f'instead of "{str(target_path)}" Please remove it '
                        "manually",
                        colored.fg("red"),
                    )
                    continue
            elif link_name_path.exists():
                _print_with_attr(
                    f'{selected_file.key}: File "{str(link_name_path)}" '
                    "exists and it is not a symbolic link. Ignoring.",
                    colored.fg("red"),
                )
                continue
            else:
                _print_with_attr(
                    f'{selected_file.key}: File "{str(link_name_path)}" '
                    "does not exist.",
                    colored.fg("yellow"),
                )
                continue

        try:
            link_name_path.unlink()
        except FileNotFoundError:
            pass
        _print_with_attr(
            f'{selected_file.key}: File "{str(link_name_path)}" deleted '
            "correctly.",
            colored.fg("green"),
        )

    print()


def load_files_list(load_all: bool = False) -> List[HomeFile]:
    """Load selected files.

    :param load_all: whether to select all files located in ``ALL_FILES_PATH``.

    """
    with ALL_FILES_PATH.open() as f:
        try:
            all_files = toml.load(f)
        except toml.TomlDecodeError:
            sys.exit(f'ERROR: Problem decoding "{str(ALL_FILES_PATH)}" file')

    if load_all:
        selected_keys = list(all_files)
    else:
        with SEL_FILES_PATH.open() as f:
            selected_keys = list(map(str.strip, f.read().splitlines()))

    selected_files: List[HomeFile] = []

    for key in selected_keys:
        try:
            selected_files.append(HomeFile(key, **all_files[key]))
        except KeyError:
            sys.exit(
                f'ERROR: "{key}" identifier was not found in '
                f'"{str(ALL_FILES_PATH)}" file'
            )
        except TypeError:
            sys.exit(
                f'ERROR: "{key}" file does not have the "relpath" attribute.'
            )

    # Check if every selected file exists
    try:
        list(
            map(
                lambda file: REPO_HOME_PATH.joinpath(file.relpath).resolve(
                    strict=True
                ),
                selected_files,
            )
        )
    except FileNotFoundError as error:
        sys.exit(
            f'ERROR: File "{error.filename}" from selected files does not exist.'
        )

    return sorted(selected_files, key=lambda file: file.key)


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
        "-l", "--link", action="store_true", help="link selected files",
    )
    exclusive_group.add_argument(
        "-d",
        "--delete",
        action="store_true",
        help="delete selected local symlinks",
    )
    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="force linking and deleting symlinks",
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="print in verbose mode"
    )
    parser.add_argument(
        "-a", "--all", action="store_true", help="perform action for all files"
    )

    args = parser.parse_args()
    selected_files = load_files_list(args.all)

    if not selected_files:
        sys.exit("ERROR: There aren't selected files.")

    verbose_status = "verbose" if args.verbose else "quiet"

    if args.print:
        print(f"Listing selected files in {verbose_status} mode.\n")
        print_selected_files(selected_files, args.verbose)
    elif args.link:
        print(f"Linking selected files in {verbose_status} mode.\n")
        link_selected_files(selected_files, args.verbose, args.force)
    elif args.delete:
        print(f"Deleting selected links in {verbose_status} mode.\n")
        delete_selected_links(selected_files, args.verbose, args.force)


if __name__ == "__main__":
    main()
