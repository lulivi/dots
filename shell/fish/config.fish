######################################
#           Alias source             #
######################################

fisher edc/bass; clear
bass source ~/.shell_utilities
#bass source ~/.profile

######################################
#         Path Manipulation          #
######################################

function fish_addpaths
    contains -- $argv $fish_user_paths
       or set -U fish_user_paths $argv $fish_user_paths
    echo "Updated PATH: $PATH"
end

function fish_removepath
    if set -l index (contains -i $argv[1] $PATH)
        set --erase --universal fish_user_paths[$index]
        echo "Updated PATH: $PATH"
    else
        echo "$argv[1] not found in PATH: $PATH"
    end
end

######################################
#               Wellcome             #
######################################

# Wellcome message
function fish_greeting
    set -l b (set_color blue)
    set -l r (set_color red)
    set -l p (set_color purple)
    set -l y (set_color yellow)
    set -l n (set_color normal)

    printf '%s\n' $r"                  "$b"    __           __   "$n
    printf '%s\n' $r"      <><         "$b"   /o \/        /o \/ "$n
    printf '%s\n' $r"<><      <><      "$b"   \__/\    __  \__/\ "$n
    printf '%s\n' $r" <><  <><    <><  "$b"           /o \/   __   "$n
    printf '%s\n' $r"   <><      <><   "$b"   __     _\__/\  /o \/ "$n
    printf '%s\n' $r" <><   <><        "$b"  /o \/  /o \/    \__/\ "$n
    printf '%s\n' $r"    <><           "$b"  \__/\  \__/\          "$n
    printf '%s\n' "                                                "
    printf '%s\n' "Wellcome to "$p"Fish"$n"-"$y"Shell$n, luvo!"
    printf '%s\n'
end

######################################
#                Prompt              #
######################################

function fish_prompt
    if not set -q __GIT_PROMPT_DIR
        set __GIT_PROMPT_DIR ~/.bash-git-prompt
    end

    # Colors
    # Reset
    set ResC (set_color normal)  # Text Reset

    # Regular Colors
    set Red (set_color red)                 # Red
    set Yellow (set_color yellow)           # Yellow
    set Blue (set_color cyan)               # Blue
    set Grey (set_color brblack)
    set PaleGreen (set_color 55895a)

    # Bold
    set BGreen (set_color -o green)         # Green

    # High Intensty
    set IBlack (set_color -o black)         # Black

    # Bold High Intensty
    set Magenta (set_color -o purple)       # Purple

    # Default values for the appearance of the prompt. Configure at will.
    set B_S "["
    set B_E "]"
    set GIT_PROMPT_SEP "."
    set GIT_PROMPT_SEPARATOR "|"
    set GIT_PROMPT_BRANCH $Magenta""
    set GIT_PROMPT_STAGED $Yellow"A"
    set GIT_PROMPT_CONFLICTS $Red"x"
    set GIT_PROMPT_CHANGED $Blue"M"
    set GIT_PROMPT_REMOTE " "
    set GIT_PROMPT_UNTRACKED $Grey"?"
    set GIT_PROMPT_STASHED "Stashed"
    set GIT_PROMPT_CLEAN $BGreen"Clean"

    # Various variables you might want for your PS1 prompt instead
    set Time (date +%R)
    set PathShort (prompt_pwd)
    set CurrentTTY (tty | sed 's/\/dev\///' | sed 's/\/.*//')

    set USER_PART "$B_S$Yellow$USER$ResC@$Red"(prompt_hostname)"$ResC$B_E"
    set TIME_PART "$B_S$PaleGreen$Time$ResC$B_E"

    set PROMPT_START "$TIME_PART $USER_PART $B_S$Yellow$PathShort$ResC$B_E"

    switch "$CurrentTTY"
        case pts
            set Pchar '>'
        case '*'
            set Pchar '>'
    end

    switch "$USER"
        case root
            set PROMPT_END " \n$Red$Pchar$ResC "
        case '*'
            set PROMPT_END " \n$Blue$Pchar$ResC "
    end

    set -e __CURRENT_GIT_STATUS
    set gitstatus "$__GIT_PROMPT_DIR/gitstatus.py"

    set _GIT_STATUS (python $gitstatus)
    set __CURRENT_GIT_STATUS $_GIT_STATUS

    set __CURRENT_GIT_STATUS_PARAM_COUNT (count $__CURRENT_GIT_STATUS)

    if not test "0" -eq $__CURRENT_GIT_STATUS_PARAM_COUNT
        set GIT_BRANCH $__CURRENT_GIT_STATUS[1]
        set GIT_REMOTE "$__CURRENT_GIT_STATUS[2]"
        if contains "." "$GIT_REMOTE"
            set -e GIT_REMOTE
        end
        set GIT_STAGED $__CURRENT_GIT_STATUS[3]
        set GIT_CONFLICTS $__CURRENT_GIT_STATUS[4]
        set GIT_CHANGED $__CURRENT_GIT_STATUS[5]
        set GIT_UNTRACKED $__CURRENT_GIT_STATUS[6]
        set GIT_STASHED $__CURRENT_GIT_STATUS[7]
        set GIT_CLEAN $__CURRENT_GIT_STATUS[8]
    end

    if test -n "$__CURRENT_GIT_STATUS"
        set STATUS " $B_S$GIT_PROMPT_BRANCH$GIT_BRANCH$ResC"

        if set -q GIT_REMOTE
            set STATUS "$STATUS$GIT_PROMPT_REMOTE$GIT_REMOTE$ResC"
        end

        set STATUS "$STATUS$GIT_PROMPT_SEPARATOR"

        set GIT_PROMPT_FIRST "1"

        if [ "$GIT_CLEAN" = "1" ]
                set STATUS "$STATUS$GIT_PROMPT_CLEAN"
        end

        if [ $GIT_STAGED != "0" ]
            set GIT_PROMPT_FIRST "0"
            set STATUS "$STATUS$GIT_PROMPT_STAGED$GIT_STAGED$ResC"
        end

        if [ $GIT_CONFLICTS != "0" ]
            if [ $GIT_PROMPT_FIRST = "0" ]
                set STATUS "$STATUS$GIT_PROMPT_SEP"
            else
                set GIT_PROMPT_FIRST "0"
            end
            set STATUS "$STATUS$GIT_PROMPT_CONFLICTS$GIT_CONFLICTS$ResC"
        end

        if [ $GIT_CHANGED != "0" ]
            if [ $GIT_PROMPT_FIRST = "0" ]
                set STATUS "$STATUS$GIT_PROMPT_SEP"
            else
                set GIT_PROMPT_FIRST "0"
            end
            set STATUS "$STATUS$GIT_PROMPT_CHANGED$GIT_CHANGED$ResC"
        end

        if [ "$GIT_UNTRACKED" != "0" ]
            if [ $GIT_PROMPT_FIRST = "0" ]
                set STATUS "$STATUS$GIT_PROMPT_SEP"
            else
                set GIT_PROMPT_FIRST "0"
            end
            set STATUS "$STATUS$GIT_PROMPT_UNTRACKED$GIT_UNTRACKED$ResC"
        end

        if [ "$GIT_STASHED" != "0" ]
            if [ $GIT_PROMPT_FIRST = "0" ]
                set STATUS "$STATUS$GIT_PROMPT_SEP"
            else
                set GIT_PROMPT_FIRST "0"
            end
            set STATUS "$STATUS$GIT_PROMPT_STASHED$GIT_STASHED$ResC"
        end

        set STATUS "$STATUS$ResC$B_E"

        set PS1 "$PROMPT_START$STATUS$PROMPT_END"
    else
        set PS1 "$PROMPT_START$PROMPT_END"
    end

    echo -e $PS1
end
