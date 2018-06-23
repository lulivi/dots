#!/usr/bin/env bash
# Copyright (c) 2018 Luis Liñán <luislivilla at gmail.com>
# Dependencies: git

# Directory from wich to check for repos
base_dir=${1:-$(pwd)};

# If the base_dir variable is not a directory, kill the program
if ! [[ -d $base_dir ]]; then
  printf '\n%sError: %s\n'\
    "$F_RED" "$RESET$S_BOLD$base_dir$RESET is not a directory"
  printf '\nUSAGE: sh %s [repositories_directory]\n\n' "$(basename $0)"
  exit
fi

# Colors and formating
RESET=$'\e[m';
S_BOLD=$(tput bold);
F_RED=$(tput setaf 1);
F_BLUE=$(tput setaf 4);

# Count for maximum repo name length
max_length=0;
# Array of repos
declare -a repo_status_order;
# Hash table of repos with it values
declare -A repo_status;
# Clean trees repositories
clean_repos_n=0;

# For each file/directory/symlink in the current directory
for dir in $base_dir/*; do
  # If the current item is a directory
  if [ -d $dir ]; then
    cd $dir || return;
    # Check the output of git status
    git_status="$(git status -s 2>&1)";
    # If the directory is a repo
    if ! [[ "$git_status" == *"Not a git repository"* ]]; then
      # Get the basename of the directory
      dir_name=$(basename $dir);
      # Get the changes of the directory
      lines_n=$(echo -e "$git_status" | sed '/^\s*$/d' | wc -l);
      case $lines_n in
        # If the working tree is clean
        0 )
          # Add the directory with the clean keyword
          repo_status["$dir_name"]=$(printf '%sCLEAN%s'\
            "$S_BOLD$F_BLUE" "$RESET");
          ((clean_repos_n++));
          ;;
        # If there are changes
        * )
          # Add the directory with the dirty keyword
          repo_status["$dir_name"]=$(printf '%sDIRTY%s - %s change(s)'\
            "$S_BOLD$F_RED" "$RESET" "$lines_n");
          ;;
      esac
      # Add the repo name to the ordered array
      repo_status_order+=("$dir_name")
      # Get the max repo name length
      if [ ${#dir_name} -gt $max_length ]; then
        max_length=${#dir_name};
      fi
    fi
    cd .. || return;
  fi
done

# Obtain the repos count
repos_n=${#repo_status_order[@]};

# Check if there are any repo in the current folder
if ! [ $repos_n -gt 0 ]; then
  printf 'There are no repos in %s\n' "$base_dir"
  exit
fi

# Dashed repo line length
repos_line_width=$(($max_length + 5));
# Dashed repo line creation
repos_line=$(printf '%*s' "$repos_line_width" | tr ' ' "-");
# Dashed info line length
info_line_width=$((${#repos_n} + 3));
# Dashed info line creation
info_line=$(printf '%*s' "$info_line_width" | tr ' ' "-");
# Last element of the array
n_minus_1=$(($repos_n - 1));
# Dirty repos count
dirty_repos_n=$(($repos_n - $clean_repos_n));

# Print some info
printf '%sInfo%s:
└── %s %s repositories found.
    ├── %s %s with clean working trees
    └── %s %s with changes\n\n'\
  "$S_BOLD" "$RESET"\
  "$repos_n" "${info_line:${#repos_n}}"\
  "$clean_repos_n" "${info_line:${#clean_repos_n}}"\
  "$dirty_repos_n" "${info_line:${#dirty_repos_n}}"
printf '%s\n' "$S_BOLD$base_dir$RESET"

# For each directory except the las tone
for dir in "${repo_status_order[@]:0:$n_minus_1}"; do
  # Print the info of the current directory
  printf '├── %s: %s %s\n' "${dir}" "${repos_line:${#dir}}" "${repo_status[$dir]}"
done

# Last repo
dir="${repo_status_order[$n_minus_1]}"
printf '└── %s: %s %s\n' "${dir}" "${repos_line:${#dir}}" "${repo_status[$dir]}"
