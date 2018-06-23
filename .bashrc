#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'

PS1='[\u@\h \W]\$ '

[ -f $HOME/.shell_utilities ] && . $HOME/.shell_utilities

# xrdb merge ~/.Xresources
