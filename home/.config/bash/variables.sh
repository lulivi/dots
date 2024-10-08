################################################################################
#                     T E R M I N A L   V A R I A B L E S                      #
################################################################################

export HISTSIZE=10000
export EDITOR='nvim'
export TERM='xterm-256color'
export XDG_CONFIG_HOME="$HOME/.config"
export SXHKD_SHELL='/usr/bin/sh'
if [ "$(command -v bat)" ]; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi
export UID="$UID" 2>/dev/null

