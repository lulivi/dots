#!/usr/bin/env python3.8
"""Manage dotfiles.

This tool creates symbolic links of your home configuration files (dotfiles).
This script can also delete those symbolic links and link them.

By default, the choosen operation (``--print``, ``--link`` and ``--delete``)
will obtain the selected files from a file called ``selected_files.py`` located
in this directory. It is possible to select every file listed in ``files.toml``
using ``--all`` argument, or only one using the argument ``--only``. Also you
can increase the printing verbosity by using ``--verbose`` argument. For
``--link`` and ``--delete`` arguments there is an extra flag, ``--force`` if
you want to skip some link checking before linking or deleting.

Some usage examples:

* Print selected files:
  ::

      python backstore.py -p

* Print all files:
  ::

      python blackstore.py -pa

* Link selected files:
  ::

      python backstore.py -l

* Delete selected files link:
  ::

      python backstore.py -d

"""
import argparse
import contextlib
import functools
import os
import subprocess
import sys

from argparse import Namespace
from enum import Enum
from pathlib import Path
from typing import List, NamedTuple

import toml

HOME_PATH: Path = Path.home()
AUTOMATION_PATH: Path = Path(__file__).resolve().parent
ALL_FILES_PATH: Path = (AUTOMATION_PATH / "files.toml").resolve()
SEL_FILES_PATH: Path = (AUTOMATION_PATH / "selected_files.txt").resolve()
REPO_HOME_PATH: Path = (AUTOMATION_PATH.parent / "home").resolve()


class colour(object):
    """Scape secuences of colours and attributes."""

    fg_black = "\x1b[30m"
    fg_red = "\x1b[31m"
    fg_green = "\x1b[32m"
    fg_yellow = "\x1b[33m"
    fg_blue = "\x1b[34m"
    fg_cyan = "\x1b[36m"

    bg_black = "\x1b[40m"
    bg_red = "\x1b[41m"
    bg_green = "\x1b[42m"
    bg_yellow = "\x1b[43m"
    bg_blue = "\x1b[44m"
    bg_cyan = "\x1b[46m"

    bold = "\x1b[1m"
    blink = "\x1b[5m"
    reset = "\x1b(B\x1b[m"


def apply_style(text: str, style: str) -> str:
    """Apply format from scape sequences.

    :param style: scape sequences union.
    :param text: text that will be styled.

    """
    return f"{style}{text}{colour.reset}"


def print_style(text: str, style: str) -> None:
    """Print the text after applying format.

    :param style: scape sequences union.
    :param text: text that will be styled.

    """
    print(apply_style(text, style))


class HomeFile(NamedTuple):
    """File representation.

    :ivar key: file identifier.
    :ivar relpath: relative path of the file.
    :ivar description: brief description of the file.
    :ivar packages: required packages related to the file.

    """

    key: str
    relpath: Path
    description: str = ""
    packages: List[str] = []


def print_selected_files(selected_files: List[HomeFile], verbose: bool = False) -> None:
    """Print selected files.

    :param selected_files: list of selected files.
    :param verbose: print info in verbose mode.

    """

    def color_file(file_relpath: Path) -> str:
        """Return a colored file path string.

        The color will tell the file type in the ``$HOME`` directory.

        :param file_relpath: home-relative file path.
        :returns: the colored file string.

        """
        link_name_path = HOME_PATH / (file_relpath)
        output_text = str(link_name_path)

        if link_name_path.is_symlink():
            if link_name_path.resolve() == REPO_HOME_PATH / (file_relpath):
                style = colour.fg_cyan
            else:
                style = colour.fg_yellow
                output_text = f"{output_text} (linked to wrong file)"
        elif link_name_path.exists():
            style = colour.fg_yellow
            output_text = f"{output_text} (file is not link)"
        else:
            style = colour.bg_red + colour.fg_yellow
            output_text = f"{output_text} (file does not exist)"

        return apply_style(output_text, style)

    def print_file(file: HomeFile, verbose: bool = False) -> None:
        """Print file with it appropiate format.

        :param file: file to print.
        :param verbose: whether to use verbosity in the print function.

        """
        key = apply_style(file.key, colour.bold)

        if verbose:
            print(
                f"{key}\n"
                f"├─ PATH: {color_file(file.relpath)}\n"
                f"├─ DESC: {file.description}\n"
                f"└─ PKGS: {' '.join(file.packages)}"
            )
        else:
            print(f"{key}: {color_file(file.relpath)}")

    list(map(functools.partial(print_file, verbose=verbose), selected_files))


def link_selected_files(selected_files: List[HomeFile], force: bool = False) -> None:
    """Link selected files.

    :param selected_files: list of selected files.
    :param verbose: print info in verbose mode.

    """

    def skip_link(key: str, target_path: Path, link_name_path: Path) -> bool:
        """Check whether we should skip linking this current file.

        :param key: file key.
        :param target_path: file repo full path.
        :param link_name_path: file home full path.
        :returns: True if we should skip the linking of this file.

        """
        skip = False

        if link_name_path.is_symlink():
            if link_name_path.resolve() == target_path:
                print_style(
                    f"{key}: File `{str(link_name_path)}` is already linked.",
                    colour.fg_green,
                )
            else:
                print_style(
                    f"{key}: File `{str(link_name_path)}` "
                    f"is linked to `{str(link_name_path.resolve())}` "
                    f"instead of `{str(target_path)}`. Please remove it "
                    "manually or use --force.",
                    colour.fg_red,
                )
            skip = True
        elif link_name_path.exists():
            print_style(
                f"{key}: File `{str(link_name_path)}` exists and it is not a "
                "symbolic link. Please remove it manually or use --force "
                "argument.",
                colour.fg_red,
            )
            skip = True
        elif not link_name_path.parent.exists():
            link_name_path.parent.mkdir(parents=True, exist_ok=True)

        return skip

    def link_file(file: HomeFile, force: bool = False) -> None:
        """Create a link of the file.

        :param file: file to link.
        :param verbose: whether to use verbosity in the print function.

        """
        key = apply_style(file.key, colour.bold)
        target_path = REPO_HOME_PATH / (file.relpath)
        link_name_path = HOME_PATH / (file.relpath)

        if force:
            try:
                link_name_path.unlink()
            except FileNotFoundError:
                pass
        elif skip_link(key, target_path, link_name_path):
            return

        link_name_path.symlink_to(target_path, target_path.is_dir())
        print_style(
            f"{key}: File `{str(link_name_path)}` linked correctly.",
            colour.fg_green,
        )

    list(map(functools.partial(link_file, force=force), selected_files))


def delete_selected_links(
    selected_files: List[HomeFile], verbose: bool = False, force: bool = False
) -> None:
    """Delete selected files.

    :param selected_files: list of selected files.
    :param verbose: print info in verbose mode.
    :param force: whether to always delete the link or not.

    """

    def skip_link(key: str, target_path: Path, link_name_path: Path) -> bool:
        """Check whether we should skip deleting this current file link.

        :param key: file key.
        :param target_path: file repo full path.
        :param link_name_path: file home full path.
        :returns: True if we should skip the deleting of this file link.

        """
        skip = False

        if link_name_path.is_symlink():
            if link_name_path.resolve() != target_path:
                print_style(
                    f"{key}: File `{str(link_name_path)}` "
                    f"is linked to `{str(link_name_path.resolve())}` "
                    f"instead of `{str(target_path)}`. Please remove it "
                    "manually or use --force argument.",
                    colour.fg_red,
                )
                skip = True
        elif link_name_path.exists():
            print_style(
                f"{key}: File `{str(link_name_path)}` exists and it is not a "
                "symbolic link. Use --force to delete it.",
                colour.fg_red,
            )
            skip = True
        else:
            print_style(
                f"{key}: File `{str(link_name_path)}` does not exist.",
                colour.fg_yellow,
            )
            skip = True

        return skip

    def delete_link(file: HomeFile, force: bool = False) -> None:
        """Create a link of the file.

        :param file: file to link.
        :param verbose: whether to use verbosity in the print function.

        """
        key = apply_style(file.key, colour.bold)
        target_path = REPO_HOME_PATH / (file.relpath)
        link_name_path = HOME_PATH / (file.relpath)

        if not force and skip_link(key, target_path, link_name_path):
            return

        try:
            link_name_path.unlink()
        except FileNotFoundError:
            pass

        print_style(
            f"{key}: File `{str(link_name_path)}` deleted correctly.",
            colour.fg_green,
        )

    print_selected_files(selected_files, verbose)
    question = input("\nAre you sure you want to delete previous links? (yes/no): ")

    if question.strip().lower() != "yes":
        print("\nAborting symlinks deletion.")
        return

    list(map(functools.partial(delete_link, force=force), selected_files))


def load_files_list(args: Namespace) -> List[HomeFile]:
    """Load selected files.

    :param load_all: whether to select all files located in
        :data:`ALL_FILES_PATH`.

    """
    # Load all files metadata
    with ALL_FILES_PATH.open() as f:
        try:
            all_files = toml.load(f)
        except toml.TomlDecodeError:
            sys.exit(f"ERROR: Problem decoding `{str(ALL_FILES_PATH)}` file")

    # Obtain selected keys
    if args.all:
        selected_keys = list(all_files)
    elif args.only:
        selected_keys = [args.only]
    else:
        with SEL_FILES_PATH.open() as f:
            selected_keys = list(map(str.strip, f.read().splitlines()))

    selected_files: List[HomeFile] = []

    # Create a list of selected files
    for key in selected_keys:
        try:
            selected_files.append(HomeFile(key, **all_files[key]))
        except KeyError:
            sys.exit(f"ERROR: `{key}` identifier was not found in `{str(ALL_FILES_PATH)}` file")
        except TypeError as error:
            sys.exit(f"ERROR parsing `{key}`: {str(error)}.")

    # Check if every selected file exists in the repository if we are not
    # deleting
    if not args.delete:
        try:
            list(
                map(
                    lambda file: (REPO_HOME_PATH / file.relpath).resolve(strict=True),
                    selected_files,
                )
            )
        except FileNotFoundError as error:
            sys.exit(f"ERROR: File `{error.filename}` from selected files does not exist.")

    return sorted(selected_files, key=lambda file: file.key)


def main():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    actions_group = parser.add_mutually_exclusive_group(required=True)
    actions_group.add_argument("-p", "--print", action="store_true", help="print selected files")
    actions_group.add_argument("-l", "--link", action="store_true", help="link selected files")
    actions_group.add_argument(
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
    parser.add_argument("-v", "--verbose", action="store_true", help="print in verbose mode")
    number_group = parser.add_mutually_exclusive_group(required=False)
    number_group.add_argument(
        "-a", "--all", action="store_true", help="perform action for all files"
    )
    number_group.add_argument(
        "-o",
        "--only",
        action="store",
        metavar="key",
        help="perform action only for a selected key",
    )

    args = parser.parse_args()
    selected_files = load_files_list(args)

    if not selected_files:
        sys.exit("ERROR: There aren't selected files.")

    verbose_status = "verbose" if args.verbose else "quiet"

    if args.print:
        print(f"Listing selected files in {verbose_status} mode.\n")
        print_selected_files(selected_files, args.verbose)
    elif args.link:
        print(f"Linking selected files in {verbose_status} mode.\n")
        link_selected_files(selected_files, args.force)
    elif args.delete:
        print(f"Deleting selected links in {verbose_status} mode.\n")
        delete_selected_links(selected_files, args.verbose, args.force)

    print()


if __name__ == "__main__":
    main()
