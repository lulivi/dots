#!/usr/bin/env bash
# Copyright (c) 2018 Luis Liñán
###############################################################################
##
## Usage
##
##     ./<script_name> [options]
##
## Description
##
##     <script_name> is a tool to create symbolic links of your configuration
##     files in your home directory structure. This script can also delete
##     those symbolic links for you.
##
## Options
##
##     -h                Display this message.
##     -f <file_list>    Select file list. Check filelist.back for format help
##                       (DEFAULT: filelist.back).
##     -l                List current files selected for backup/restore.
##     -q                Do everything quietly (with minimal number of
##                       messages).
##     -r                Delete local symlinks.
##
###############################################################################

readonly SCRIPT_NAME="$(basename "$0")"
readonly BASE_DIR="$(realpath "$(dirname "$0")")"

usage() {
    [[ -n "$1" ]] && printf '\n%s\n' "$1"
    grep -e '^##[^#]*$' "$BASE_DIR/$SCRIPT_NAME"  | \
        sed -e "s/^##[[:space:]]\{0,1\}//g" \
            -e "s/<script_name>/${SCRIPT_NAME}/g"
    exit 2
} 2>/dev/null

# Import functions and global variables as colors
source "$BASE_DIR/bk_utils.sh"

# Script mode
mode="DEPLOY"

# File from which get the backup/restore files
dot_file_list="$BASE_DIR/filelist.back"

while getopts "hf:lqsr" args; do
    case "$args" in
        (h) # Display help
            usage 2>&1;;
        (f) # Select backup/restore file
            if ! [ -f "$OPTARG" ]; then
                usage "Backup/restore file not found."
            fi
            dot_file_list="$OPTARG"
            ;;
        (l) # List selected files
            mode="LIST"
            ;;
        (q) # Quiet mode
            quiet=t
            ;;
        (s) # Sort output
            ;;
        (r) # Symlinks remove mode
            mode="REMOVE"
            ;;
        (--)
            shift; break
            ;;
        (-*)
            usage "$1: unknown option"
            ;;
        (*)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

printf 'Running the script in %s mode\n' "$mode"

#
# Variables
#
# Script mode
readonly mode

# Quiet run
readonly quiet

# Files to backup/restore
readonly dot_file_list

# Read the file list
read_dot_file_list

# Perform the script current action
case "$mode" in
    "LIST") # List current files selected to deployment
        for idx in "${!repo_paths[@]}"; do
            list_file "${repo_paths[$idx]}" \
                       "${repo_stats[$idx]}" \
                       "${home_paths[$idx]}" \
                       "${home_stats[$idx]}"
        done
        ;;
    "DEPLOY") # Deploy selected files
        for idx in "${!repo_paths[@]}"; do
            deploy_file "${repo_paths[$idx]}" \
                        "${repo_stats[$idx]}" \
                        "${home_paths[$idx]}" \
                        "${home_stats[$idx]}"
        done
        ;;
    "REMOVE") # Remove deployed symlinks
        for idx in "${!repo_paths[@]}"; do
            remove_link "${repo_paths[idx]}" \
                        "${home_paths[idx]}"
        done
        ;;
    *) # Unknown mode
        err_msg "Unknown mode."
        usage
        ;;
esac

printf 'Done!\n'

