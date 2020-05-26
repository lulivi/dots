################################################################################
#                       T E R M I N A L   A L I A S E S                        #
################################################################################

# Systemd
alias please='sudo $(history -p !!)'
alias restart_nm="systemctl restart NetworkManager.service"
alias reload_bspwm="~/.config/bspwm/bspwmrc 2>&1 1>/dev/null"

## Misc
alias t="tmux"
alias dgit="GIT_PAGER='less' git"
alias q="exit"
alias r="reset"
alias weather="curl wttr.in/~Granada"
alias today="date +%d/%m/%y"
alias graphic_card_in_use="glxinfo|egrep \"OpenGL vendor|OpenGL renderer*\""
alias center_tmux="tmux split-window -h \; split-window -h \; swap-pane -s 1 -t 2 \; resize-pane -t1 -x 75 \; resize-pane -t3 -x 75 \; select-pane -t 2"
alias walr="wal -R -o ~/.config/wal/reload_services.sh"

# Entertainment
alias matrix="cmatrix -b -a -u 2 -C yellow"
alias tubes="pipes -p 20 -s 15 -r 0 -R"

# Basic utilities enchancement
alias grep='grep --color=auto'
alias ls='ls --color=auto --human-readable'
alias tree='tree --dirsfirst -C'
alias dmesg='dmesg --color=auto --reltime --human --nopager --decode'
alias free='free -mht'
alias pacman='pacman --color=auto'
alias yay='yay --color=auto'

## Playerctl
alias pp="playerctl play-pause; exit"
alias nxt="playerctl next; exit"
alias prv="playerctl previous; exit"
alias stp="playerctl stop; exit"
