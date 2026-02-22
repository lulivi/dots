#!/usr/bin/env python3
"""Manage dotfiles.

This tool creates symbolic links of your home configuration files (dotfiles).
This script can also delete those symbolic links and link them.

By default, the chosen operation (``--print``, ``--link`` and ``--delete``)
will obtain the selected files from a file called ``selected_files.txt`` located
in this directory. It is possible to select every file listed in ``files.toml``
using ``--all`` argument, or only one using the argument ``--only``. For
``--link`` and ``--delete`` arguments there is an extra flag, ``--force`` if
you want to skip some link checking before linking or deleting.

Some usage examples:

* Print selected files:
  ::

      python backstore.py -p

* Print all files:
  ::

      python backstore.py -pa

* Link selected files:
  ::

      python backstore.py -l

* Delete selected files link:
  ::

      python backstore.py -d

"""

import argparse
import subprocess
import sys
import tomllib

from argparse import Namespace
from pathlib import Path
from typing import List, NamedTuple, Set

HOME_PATH: Path = Path.home()
AUTOMATION_PATH: Path = Path(__file__).resolve().parent
ALL_FILES_PATH: Path = AUTOMATION_PATH.joinpath("files.toml").resolve()
SEL_FILES_PATH: Path = AUTOMATION_PATH.joinpath("selected_files.txt").resolve()
REPO_HOME_PATH: Path = AUTOMATION_PATH.parent.joinpath("home").resolve()
PROGRAMS_PATH: Path = AUTOMATION_PATH.parent.joinpath("programs").resolve()
BIN_PATH: Path = HOME_PATH.joinpath("bin").resolve()


class Color:
    """ANSI escape sequences for terminal colours and attributes."""

    fg_red = "\x1b[31m"
    fg_green = "\x1b[32m"
    fg_yellow = "\x1b[33m"
    fg_cyan = "\x1b[36m"
    bold = "\x1b[1m"
    reset = "\x1b(B\x1b[m"


def apply_style(text: str, style: str) -> str:
    """Return *text* wrapped in the given ANSI *style* escape sequence."""
    return f"{style}{text}{Color.reset}"


def print_style(text: str, style: str) -> None:
    """Print *text* with the given ANSI *style* escape sequence."""
    print(apply_style(text, style), flush=True)


class HomeFile(NamedTuple):
    """Represents a tracked configuration file or program.

    :ivar relpath: repository-relative path (e.g. ``.config/foo`` or ``programs/bar``).
    :ivar description: brief human-readable description.
    :ivar packages: distro packages required by this file.

    """

    relpath: Path
    description: str = ""
    packages: Set[str] = set()

    @property
    def is_program(self) -> bool:
        """Return True when this entry represents a ``programs/`` executable."""
        return str(self.relpath).startswith("programs/")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "action",
        choices=["print", "link", "delete"],
        help="Action to perform: print, link or delete",
    )
    parser.add_argument(
        "-f", "--force", action="store_true", help="force linking and deleting symlinks"
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

    # pass a simple boolean to control whether existence checks are skipped
    selected_files = load_files_list(args, delete=(args.action == "delete"))

    if not selected_files:
        sys.exit("ERROR: There aren't selected files.")

    # dispatch table for actions
    actions = {
        "print": lambda: print_selected_files(selected_files),
        "link": lambda: link_selected_files(selected_files, args.force),
        "delete": lambda: delete_selected_links(selected_files, args.force),
    }

    handler = actions.get(args.action)
    if handler:
        print()
        handler()
        print()


# ---------------------------------------------------------------------------
# File-list loading
# ---------------------------------------------------------------------------


def load_files_list(args: Namespace, delete: bool = False) -> List[HomeFile]:
    """Return sorted list of :class:`HomeFile` objects based on CLI *args*.

    :param args: parsed CLI arguments (used for --all/--only)
    :param delete: when True, skip repository existence checks (used for delete action)
    """
    all_files = _load_all_files_metadata()
    keys = _expand_selected_keys(args, all_files)
    files = _build_homefile_list(keys, all_files)
    if not delete:
        _check_files_exist(files)
    return sorted(files, key=lambda f: str(f.relpath))


def _load_all_files_metadata() -> dict:
    """Parse and return the ``files.toml`` manifest."""
    with ALL_FILES_PATH.open("rb") as f:
        try:
            metadata = tomllib.load(f)
            for entry in metadata.values():
                if "packages" in entry:
                    entry["packages"] = set(entry["packages"])
            return metadata
        except tomllib.TOMLDecodeError as error:
            sys.exit(f"ERROR: Problem decoding `{ALL_FILES_PATH}`.\nTOMLDecodeError: {error}")


def _expand_selected_keys(args: Namespace, all_files: dict) -> List[str]:
    """Return the ordered list of file keys determined by CLI flags."""
    if args.all:
        return list(all_files)
    if args.only:
        return [args.only]
    all_keys = list(all_files)
    keys: List[str] = []
    for entry in _read_selected_entries():
        keys.extend(_expand_entry(entry, all_keys))
    return keys


def _read_selected_entries() -> List[str]:
    with SEL_FILES_PATH.open() as f:
        return [line.strip() for line in f if line.strip()]


def _expand_entry(entry: str, all_keys: List[str]) -> List[str]:
    if entry in all_keys:
        return [entry]
    expanded = [k for k in all_keys if k.startswith(entry)]
    if expanded:
        return expanded
    if entry.startswith("programs/"):
        return [entry]
    print(f"WARNING: `{entry}` does not match any key in `{ALL_FILES_PATH}`.")
    return []


def _build_homefile_list(keys: List[str], all_files: dict) -> List[HomeFile]:
    """Construct :class:`HomeFile` objects for each key."""
    files: List[HomeFile] = []
    for key in keys:
        if key.startswith("programs/"):
            files.append(HomeFile(Path(key), description="Program executable"))
        else:
            try:
                files.append(HomeFile(key, **all_files[key]))
            except KeyError:
                sys.exit(f"ERROR: `{key}` was not found in `{ALL_FILES_PATH}`")
            except TypeError as error:
                sys.exit(f"ERROR parsing `{key}`: {error}.")
    return files


def _check_files_exist(files: List[HomeFile]) -> None:
    """Exit with an error if any repo file is missing."""
    try:
        for file in files:
            base = AUTOMATION_PATH.parent if file.is_program else REPO_HOME_PATH
            base.joinpath(file.relpath).resolve(strict=True)
    except FileNotFoundError as error:
        sys.exit(f"ERROR: `{error.filename}` from selected files does not exist.")


# ---------------------------------------------------------------------------
# Display
# ---------------------------------------------------------------------------


def print_selected_files(selected_files: List[HomeFile]) -> None:
    """Print each selected file with its link status colour-coded."""
    print("Listing selected files.\n")
    for file in selected_files:
        _print_file(file)


def _print_file(file: HomeFile) -> None:
    color_fn = _color_program if file.is_program else _color_dotfile
    print(f"{color_fn(file.relpath)}: {file.description}")
    if file.packages:
        print(f"└─ PKGS: {' '.join(file.packages)}")


def _color_dotfile(file_relpath: Path) -> str:
    link_name_path = HOME_PATH.joinpath(file_relpath)
    output_text = str(link_name_path)
    if link_name_path.is_symlink():
        if link_name_path.resolve() == REPO_HOME_PATH.joinpath(file_relpath):
            style = Color.fg_cyan
        else:
            style = Color.fg_yellow
            output_text = f"{output_text} (linked to wrong file)"
    elif link_name_path.exists():
        style = Color.fg_yellow
        output_text = f"{output_text} (file is not link)"
    else:
        style = Color.fg_red
        output_text = f"{output_text} (file does not exist)"
    return apply_style(output_text, style)


def _color_program(file_relpath: Path) -> str:
    name = file_relpath.name
    bin_link = BIN_PATH.joinpath(name)
    exec_path = AUTOMATION_PATH.parent.joinpath(file_relpath, "target", "release", name)
    output_text = str(bin_link)
    if bin_link.is_symlink():
        if bin_link.resolve() == exec_path:
            style = Color.fg_cyan
        else:
            style = Color.fg_yellow
            output_text = f"{output_text} (linked to wrong executable)"
    elif bin_link.exists():
        style = Color.fg_yellow
        output_text = f"{output_text} (file is not link)"
    else:
        style = Color.fg_red
        output_text = f"{output_text} (executable does not exist)"
    return apply_style(output_text, style)


# ---------------------------------------------------------------------------
# Linking
# ---------------------------------------------------------------------------


def link_selected_files(selected_files: List[HomeFile], force: bool = False) -> None:
    """Create symlinks for all *selected_files*.

    :param selected_files: list of files to link.
    :param force: when True, replace existing links without prompting.
    """
    print("Linking selected files.\n")
    installed = _get_installed_packages()
    for file in selected_files:
        if file.is_program:
            program_dir = AUTOMATION_PATH.parent.joinpath(file.relpath).resolve()
            if program_dir.is_dir():
                _link_program(program_dir, force=force)
            else:
                print_style(f"programs/{program_dir.name}: Directory not found.", Color.fg_red)
        else:
            _link_dotfile(file, installed, force=force)


def _get_installed_packages() -> Set[str]:
    result = subprocess.run(
        ["apt", "list", "--installed"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        universal_newlines=True,
    )
    return {line.split("/", 1)[0] for line in result.stdout.splitlines()}


def _link_dotfile(file: HomeFile, installed: Set[str], force: bool = False) -> None:
    key = apply_style(str(file.relpath), Color.bold)
    target_path = REPO_HOME_PATH.joinpath(file.relpath)
    link_path = HOME_PATH.joinpath(file.relpath)

    missing = _missing_dependencies(file.packages, installed)
    if missing:
        print_style(f"{key}: Missing dependencies: {missing}", Color.fg_yellow)

    if force:
        link_path.unlink(missing_ok=True)
    elif _should_skip_link(key, target_path, link_path):
        return

    link_path.symlink_to(target_path, target_path.is_dir())
    print_style(f"{key}: `{link_path}` linked correctly.", Color.fg_green)


def _missing_dependencies(packages: Set[str], installed: Set[str]) -> Set[str]:
    return packages - installed


def _should_skip_link(key: str, target_path: Path, link_path: Path) -> bool:
    """Return True (and emit a message) when *link_path* should not be created."""
    if link_path.is_symlink():
        if link_path.resolve() == target_path:
            print_style(f"{key}: `{link_path}` is already linked.", Color.fg_green)
        else:
            print_style(
                f"{key}: `{link_path}` is linked to `{link_path.resolve()}` "
                f"instead of `{target_path}`. Remove it manually or use --force.",
                Color.fg_red,
            )
        return True
    if link_path.exists():
        print_style(
            f"{key}: `{link_path}` exists and is not a symbolic link. "
            "Remove it manually or use --force.",
            Color.fg_red,
        )
        return True
    link_path.parent.mkdir(parents=True, exist_ok=True)
    return False


def _link_program(program_dir: Path, force: bool = False) -> None:
    """Link a compiled Cargo executable from *program_dir* to ``~/bin``; build if needed."""
    name = program_dir.name
    exec_path = program_dir.joinpath("target", "release", name)
    bin_link = BIN_PATH.joinpath(name)
    key = apply_style(f"programs/{name}", Color.bold)

    try:
        print_style(f"{key}: Updating/Creating executable...", Color.fg_yellow)
        subprocess.run(["cargo", "build", "--release"], cwd=program_dir, check=True)
    except subprocess.CalledProcessError as error:
        print_style(f"{key}: Build failed: {error}", Color.fg_red)
        return

    if not exec_path.exists():
        print_style(f"{key}: Executable still missing after build.", Color.fg_red)
        return

    if force:
        bin_link.unlink(missing_ok=True)
    elif bin_link.is_symlink():
        if bin_link.resolve() == exec_path:
            print_style(f"{key}: `{bin_link}` is already linked.", Color.fg_green)
        else:
            print_style(
                f"{key}: `{bin_link}` is linked to `{bin_link.resolve()}` "
                f"instead of `{exec_path}`. Remove manually or use --force.",
                Color.fg_red,
            )
        return
    elif bin_link.exists():
        print_style(
            f"{key}: `{bin_link}` exists and is not a symlink. Remove manually or use --force.",
            Color.fg_red,
        )
        return
    else:
        bin_link.parent.mkdir(parents=True, exist_ok=True)

    bin_link.symlink_to(exec_path)
    print_style(f"{key}: `{bin_link}` linked correctly.", Color.fg_green)


# ---------------------------------------------------------------------------
# Deletion
# ---------------------------------------------------------------------------


def delete_selected_links(selected_files: List[HomeFile], force: bool = False) -> None:
    """Remove symlinks for all *selected_files* after user confirmation.

    :param selected_files: list of files whose links should be removed.
    :param force: when True, remove links without checking their target.
    """
    print("Deleting selected links.\n")
    print_selected_files(selected_files)
    answer = input("\nAre you sure you want to delete previous links? (yes/no): ")
    if answer.strip().lower() != "yes":
        print("\nAborting symlinks deletion.")
        return
    for file in selected_files:
        if file.is_program:
            program_dir = AUTOMATION_PATH.parent.joinpath(file.relpath).resolve()
            if program_dir.is_dir():
                _delete_program(program_dir, force=force)
            else:
                print_style(f"programs/{program_dir.name}: Directory not found.", Color.fg_red)
        else:
            _delete_dotfile(file, force=force)


def _delete_dotfile(file: HomeFile, force: bool = False) -> None:
    key = apply_style(str(file.relpath), Color.bold)
    target_path = REPO_HOME_PATH.joinpath(file.relpath)
    link_path = HOME_PATH.joinpath(file.relpath)
    if not force and _should_skip_delete(key, target_path, link_path):
        return
    link_path.unlink(missing_ok=True)
    print_style(f"{key}: `{link_path}` deleted correctly.", Color.fg_green)


def _should_skip_delete(key: str, target_path: Path, link_path: Path) -> bool:
    """Return True (and emit a message) when *link_path* should not be removed."""
    if link_path.is_symlink():
        if link_path.resolve() != target_path:
            print_style(
                f"{key}: `{link_path}` is linked to `{link_path.resolve()}` "
                f"instead of `{target_path}`. Remove manually or use --force.",
                Color.fg_red,
            )
            return True
        return False
    if link_path.exists():
        print_style(
            f"{key}: `{link_path}` exists and is not a symbolic link. Use --force to delete.",
            Color.fg_red,
        )
    else:
        print_style(f"{key}: `{link_path}` does not exist.", Color.fg_yellow)
    return True


def _delete_program(program_dir: Path, force: bool = False) -> None:
    name = program_dir.name
    bin_link = BIN_PATH.joinpath(name)
    key = apply_style(f"programs/{name}", Color.bold)
    if force or bin_link.is_symlink():
        try:
            bin_link.unlink()
            print_style(f"{key}: `{bin_link}` deleted correctly.", Color.fg_green)
        except FileNotFoundError:
            print_style(f"{key}: `{bin_link}` not found.", Color.fg_yellow)
    elif bin_link.exists():
        print_style(
            f"{key}: `{bin_link}` exists and is not a symlink. Use --force to delete.",
            Color.fg_red,
        )
    else:
        print_style(f"{key}: `{bin_link}` does not exist.", Color.fg_yellow)


if __name__ == "__main__":
    main()
