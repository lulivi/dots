#!/usr/bin/env python3
"""Manage dotfiles.

This tool creates symbolic links of your home configuration files (dotfiles).
This script can also delete those symbolic links and link them.

By default, the choosen operation (``--print``, ``--link`` and ``--delete``)
will obtain the selected files from a file called ``selected_files.py`` located
in this directory. It is possible to select every file listed in ``files.json``
using ``--all`` argument, or only one using the argument ``--only``. For
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
import json
import os
import subprocess
import sys

from argparse import Namespace
from enum import Enum
from pathlib import Path
from typing import List, NamedTuple, Set

HOME_PATH: Path = Path.home()
AUTOMATION_PATH: Path = Path(__file__).resolve().parent
ALL_FILES_PATH: Path = (AUTOMATION_PATH / "files.json").resolve()
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
    print(apply_style(text, style), flush=True)


class HomeFile(NamedTuple):
    """File representation.

    :ivar key: file identifier.
    :ivar relpath: relative path of the file.
    :ivar description: brief description of the file.
    :ivar packages: required packages related to the file.

    """

    relpath: Path
    description: str = ""
    packages: Set[str] = set()


def print_selected_files(selected_files: List[HomeFile]) -> None:
    """Print selected files.

    :param selected_files: list of selected files.

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
            style = colour.fg_red
            output_text = f"{output_text} (file does not exist)"

        return apply_style(output_text, style)

    def print_file(file: HomeFile) -> None:
        """Print file with it appropiate format.

        :param file: file to print.

        """
        print(f"{color_file(file.relpath)}: {file.description}")
        if file.packages:
            print(f"└─ PKGS: {' '.join(file.packages)}")

    list(map(print_file, selected_files))


def link_selected_files(
    selected_files: List[HomeFile], force: bool = False, install: bool = False
) -> None:
    """Link selected files.

    :param selected_files: list of selected files.
    :param force: whether to always delete the link or not.

    """

    def get_installed_packages() -> List[str]:
        """Obtain the list of installed APT packages.

        :returns: The installed packages with the APT package manager.

        """
        return set(
            map(
                lambda package: package.split("/", 1)[0],
                subprocess.run(
                    ["apt", "list", "--installed"],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.DEVNULL,
                    universal_newlines=True,
                ).stdout.splitlines(),
            )
        )

    def not_installed_dependencies(dependencies: List[str], installed_packages: Set[str]) -> bool:
        return set(dependencies) - installed_packages

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

    def link_file(file: HomeFile, installed_packages: List[str], force: bool = False) -> None:
        """Create a link of the file.

        :param file: file to link.
        :param force: whether to always delete the link or not.

        """
        key = apply_style(file.relpath, colour.bold)
        target_path = REPO_HOME_PATH / (file.relpath)
        link_name_path = HOME_PATH / (file.relpath)

        not_installed_package_deps = not_installed_dependencies(file.packages, installed_packages)
        if not_installed_package_deps:
            print_style(
                f"{key}: Missing some dependencies for the selected file: {not_installed_package_deps}",
                colour.fg_yellow,
            )

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

    list(
        map(
            functools.partial(
                link_file,
                installed_packages=get_installed_packages(),
                force=force,
            ),
            selected_files,
        )
    )


def delete_selected_links(selected_files: List[HomeFile], force: bool = False) -> None:
    """Delete selected files.

    :param selected_files: list of selected files.
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

        """
        key = apply_style(file.relpath, colour.bold)
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

    print_selected_files(selected_files)
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
            all_files = json.load(f)
        except json.JSONDecodeError:
            sys.exit(f"ERROR: Problem decoding `{str(ALL_FILES_PATH)}` file")

    # Obtain selected keys
    if args.all:
        selected_files = list(all_files)
    elif args.only:
        selected_files = [args.only]
    else:
        with SEL_FILES_PATH.open() as f:
            selected_files = list(map(str.strip, f.read().splitlines()))

    chosen_files: List[HomeFile] = []

    # Create a list of selected files
    for file_path in selected_files:
        try:
            chosen_files.append(HomeFile(file_path, **all_files[file_path]))
        except KeyError:
            sys.exit(f"ERROR: `{file_path}` was not found in `{str(ALL_FILES_PATH)}` file")
        except TypeError as error:
            sys.exit(f"ERROR parsing `{file_path}`: {str(error)}.")

    # Check if every selected file exists in the repository if we are not
    # deleting
    if not args.delete:
        try:
            list(
                map(
                    lambda file: (REPO_HOME_PATH / file.relpath).resolve(strict=True),
                    chosen_files,
                )
            )
        except FileNotFoundError as error:
            sys.exit(f"ERROR: File `{error.filename}` from selected files does not exist.")

    return sorted(chosen_files, key=lambda file: file.relpath)


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

    if args.print:
        print(f"Listing selected files.\n")
        print_selected_files(selected_files)
    elif args.link:
        print(f"Linking selected files.\n")
        link_selected_files(selected_files, args.force)
    elif args.delete:
        print(f"Deleting selected links.\n")
        delete_selected_links(selected_files, args.force)


if __name__ == "__main__":
    main()
