#!/usr/bin/env bash
# fromhex and tohex obtained from https://unix.stackexchange.com/a/269085
#------------------------------------------------------------------------------
##
## Usage: ${SCRIPT_NAME} [OPTIONS]
##
## Options:
##
##   -h                   Display this message.
##   -a <dec|hex>         Print: <decimal> =~ <hexadecimal>
##   -d <hex>             Print: <decimal>
##   -x <dec>             Print: <hexadecimal>
##   -f <dec|hex>         Print the foreground color scape sequence
##   -b <dec|hex>         Print the background color scape sequence
##
## Notes:
##
##   Each option is exclusive with the other ones.
##
#------------------------------------------------------------------------------

SCRIPT_NAME="$(basename ${0})"
SCRIPT_PATH="$(dirname ${0})"

usage() {
    [[ -n "$1" ]] && printf '\nError: %s\n' "$1"
    grep -e "^##" $SCRIPT_PATH/$SCRIPT_NAME | \
        sed -e "s/^## \{0,1\}//g" \
            -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"
    exit 2
} 2>/dev/null

fromhex(){
    hex=${1#"#"}
    r=$(printf '0x%0.2s' "$hex")
    g=$(printf '0x%0.2s' ${hex#??})
    b=$(printf '0x%0.2s' ${hex#????})
    dec_value="$(((r<75?0:(r-35)/40)*6*6 +
        (g<75?0:(g-35)/40)*6   +
        (b<75?0:(b-35)/40)     + 16 ))"
    printf '%s' "$dec_value"
}

tohex(){
    dec=$(($1%256))   ### input must be a number in range 0-255.
    if [ "$dec" -lt "16" ]; then
        bas=$(( dec%16 ))
        mul=128
        [ "$bas" -eq "7" ] && mul=192
        [ "$bas" -eq "8" ] && bas=7
        [ "$bas" -gt "8" ] && mul=255
        a="$((  (bas&1)    *mul ))"
        b="$(( ((bas&2)>>1)*mul ))"
        c="$(( ((bas&4)>>2)*mul ))"
        hex_value=$(printf '#%02x%02x%02x%s' "$a" "$b" "$c")
    elif [ "$dec" -gt 15 ] && [ "$dec" -lt 232 ]; then
        b=$(( (dec-16)%6  )); b=$(( b==0?0: b*40 + 55 ))
        g=$(( (dec-16)/6%6)); g=$(( g==0?0: g*40 + 55 ))
        r=$(( (dec-16)/36 )); r=$(( r==0?0: r*40 + 55 ))
        hex_value=$(printf '#%02x%02x%02x%s' "$r" "$g" "$b")
    else
        gray=$(( (dec-232)*10+8 ))
        hex_value=$(printf '#%02x%02x%02x%s' "$gray" "$gray" "$gray")
    fi
    printf '%s' "$hex_value"
}


# Check if there is no args
[[ $# -eq 0 ]] && {
    usage "Not enought args."
}

rd="^[0-9]{1,3}$"
rh="^\#?[0-9a-fA-F]{6}$"

while getopts "a:d:x:f:b:h" FLAG; do
    case $FLAG in
        (a|f|b)
            if [[ "$OPTARG" =~ $rd ]]; then
                dec="$OPTARG"
                hex=$(tohex "$dec")
            elif [[ "$OPTARG" =~ $rh ]]; then
                hex="$OPTARG"
                dec=$(fromhex "$hex")
            else
                usage "Unknown argument."
            fi
            case $FLAG in
                a)  # Print: <decimal> =~ <hexadecimal>
                    printf 'The aprox conversion is: %s -> %s\n' "$dec" "$hex"
                    ;;
                f)  # Print the foreground color scape sequence
                    printf '%s' "$(tput setaf $dec)"
                    ;;
                b)  # Print the background color scape sequence
                    printf '%s' "$(tput setab $dec)"
            esac
            break;;
        (d) # Print: <decimal>
            [[ "$OPTARG" =~ $rh ]] && {
                printf '%s' $(fromhex "$OPTARG")
            } || {
                usage "Wrong argument."
            }
            break;;
        (x) # Print: <hexadecimal>
            [[ "$OPTARG" =~ $rd ]] && {
                printf '%s' $(tohex "$OPTARG")
            } || {
                usage "Wrong argument."
            }
            break;;
        (h) # Show help
            usage
            break;;
        (--)# Next option
            shift
            break;;
        (-*)# Unknown option
            usage "$1: unknown option";;
        (*) break;;
    esac
done

shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
