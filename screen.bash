# This is free and unencumbered software released into the public domain.
# 
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
# 
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
# 
# For more information, please refer to <https://unlicense.org>
# Adhere to strict mode another day

# screen.bash
# v0.1.1
# notweerdmonk
# Terminal rendering and keyboard input utilities

# Escape sequnces
ESC=$'\e'
CSI="${ESC}["
OSC="${ESC}]"

###############################################################################
# 1. CURSOR MOVEMENT
###############################################################################

cursor_up()         { printf "${CSI}%dA" "${1:-1}"; }
cursor_down()       { printf "${CSI}%dB" "${1:-1}"; }
cursor_right()      { printf "${CSI}%dC" "${1:-1}"; }
cursor_left()       { printf "${CSI}%dD" "${1:-1}"; }

cursor_move()       { printf "${CSI}%d;%dH" "$1" "$2"; } # row col

cursor_home()       { printf "${CSI}H"; }

cursor_save()       { printf "${ESC}7"; }      # or CSI s
cursor_restore()    { printf "${ESC}8"; }      # or CSI u

cursor_hide()       { printf "${CSI}?25l"; }
cursor_show()       { printf "${CSI}?25h"; }

cursor_position() {
    local input="${1:-/dev/tty}"
    local output="${2:-/dev/tty}"

    printf "${CSI}6n" > "$output"
    IFS='[;' read -sdR _ row col < "$input"

    printf "%s %s\n" "$row" "$col"
}

###############################################################################
# 2. CLEARING SCREEN PORTIONS
###############################################################################

clear_screen()      { printf "${CSI}2J"; }
clear_line()        { printf "${CSI}2K"; }
clear_eol()         { printf "${CSI}K"; }
clear_bol()         { printf "${CSI}1K"; }
clear_down()        { printf "${CSI}J"; }
clear_up()          { printf "${CSI}1J"; }

###############################################################################
# 3. PRINT AT COORDINATES
###############################################################################

print_at() {
    local row=$1
    local col=$2
    shift 2
    printf "${CSI}%d;%dH%s" "$row" "$col" "$*"
}

printf_at() {
    local row=$1
    local col=$2
    local fmt=$3
    shift 3
    printf "${CSI}%d;%dH" "$row" "$col"
    printf "$fmt" "$@"
}

###############################################################################
# 4. KEYBOARD HANDLING
###############################################################################

read_key() {
    local input="${1:-/dev/tty}"

    local key

    while IFS= read -rsn1 char
    do
        key+="$char"
        if [[ "${key:0:1}" != $'\e' ]]; then
            break
        elif [[ ${#key} -eq 3 ]]; then
            break
        fi
    done < "$input"

    [[ "$key" == $'\n' || "$key" == $'\r' || -z "$key" ]] && \
        printf "enter" || \
        {
            [[ "$key" == $'\x20' ]] && printf "space" || \
            printf '%s' "$key"
        }
}

declare -gA key_functions

register_key() {
    [[ -z "$1" || -z "$2" ]] && return 255
    key_functions["$1"]="$2"
}

key_dispatch() {
    local input="${1:-/dev/tty}"

    local k
    k=$(read_key "$input")

    [[ -v DEBUG && -n "$DEBUG" ]] && set -f
    [[ -v DEBUG && -n "$DEBUG" ]] && [[ -v key_functions["$k"] ]] && echo -e "$k\t${key_functions["$k"]}" >> keys.out
    [[ -v DEBUG && -n "$DEBUG" ]] && set +f

    case "$k" in
        $'\e[A') ${key_functions[key_up]} ;;
        $'\e[B') ${key_functions[key_down]} ;;
        $'\e[C') ${key_functions[key_right]} ;;
        $'\e[D') ${key_functions[key_left]} ;;
        $'\e[Z') ${key_functions[key_stab]} ;;
        $'\t') ${key_functions[key_tab]} ;;

        "enter") ${key_functions[key_enter]} ;;
        "space") ${key_functions[key_space]} ;;

        "q") ${key_functions[key_quit]} ;;

        *) [[ -v key_functions["$k"] && -n "${key_functions["$k"]}" ]] && \
                {
                    ${key_functions["$k"]} || :
                } || \
                ${key_functions["*"]}
           ;;
    esac
}

prompt() {
    local var=$1
    local text=$2

    local input="${3:-/dev/tty}"

    read -rp "$text" "$var" < "$input"
}

###############################################################################
# 5. COLORS / HIGHLIGHT / BELL
###############################################################################

reset_style()       { printf "${CSI}0m"; }

bold()              { printf "${CSI}1m"; }
dim()               { printf "${CSI}2m"; }
italic()            { printf "${CSI}3m"; }
underline()         { printf "${CSI}4m"; }
reverse()           { printf "${CSI}7m"; }

fg()                { printf "${CSI}38;5;%sm" "$1"; }
bg()                { printf "${CSI}48;5;%sm" "$1"; }

rgb_fg()            { printf "${CSI}38;2;%d;%d;%dm" "$1" "$2" "$3"; }
rgb_bg()            { printf "${CSI}48;2;%d;%d;%dm" "$1" "$2" "$3"; }

bell()              { printf '\a'; }

highlight() {
    reverse
    printf "%s" "$*"
    reset_style
}

set_style() {
    local codes=()
    local truecolor=0
    local colors256=0

    # --- detect capabilities ---
    if [[ "$COLORTERM" =~ (truecolor|24bit) ]]; then
      truecolor=1
    fi

    if command -v tput >/dev/null 2>&1; then
        local ncolors
        ncolors=$(tput colors 2>/dev/null)
        if [[ "$ncolors" -ge 256 ]]; then
            colors256=1
        fi
    fi

    for arg in "$@"; do
        arg="${arg,,}"  # lowercase

        case "$arg" in
            reset) codes=(0) ;;

            # styles
            bold) codes+=("1") ;;
            dim) codes+=("2") ;;
            italic) codes+=("3") ;;
            underline) codes+=("4") ;;
            blink) codes+=("5") ;;
            reverse) codes+=("7") ;;
            hidden) codes+=("8") ;;
            strikethrough) codes+=("9") ;;

            # style resets (do not affect colors)
            no_bold|bold_off) codes+=("22") ;;
            no_italic|italic_off) codes+=("23") ;;
            no_underline|underline_off) codes+=("24") ;;
            no_blink|blink_off) codes+=("25") ;;
            no_reverse|reverse_off) codes+=("27") ;;
            no_hidden|hidden_off) codes+=("28") ;;
            no_strikethrough|strikethrough_off) codes+=("29") ;;

            # standard fg
            black) codes+=("30") ;;
            red) codes+=("31") ;;
            green) codes+=("32") ;;
            yellow) codes+=("33") ;;
            blue) codes+=("34") ;;
            magenta) codes+=("35") ;;
            cyan) codes+=("36") ;;
            white) codes+=("37") ;;

            # bright fg
            bright_black) codes+=("90") ;;
            bright_red) codes+=("91") ;;
            bright_green) codes+=("92") ;;
            bright_yellow) codes+=("93") ;;
            bright_blue) codes+=("94") ;;
            bright_magenta) codes+=("95") ;;
            bright_cyan) codes+=("96") ;;
            bright_white) codes+=("97") ;;

            # standard bg
            bg_black) codes+=("40") ;;
            bg_red) codes+=("41") ;;
            bg_green) codes+=("42") ;;
            bg_yellow) codes+=("43") ;;
            bg_blue) codes+=("44") ;;
            bg_magenta) codes+=("45") ;;
            bg_cyan) codes+=("46") ;;
            bg_white) codes+=("47") ;;

            # bright bg
            bg_bright_black) codes+=("100") ;;
            bg_bright_red) codes+=("101") ;;
            bg_bright_green) codes+=("102") ;;
            bg_bright_yellow) codes+=("103") ;;
            bg_bright_blue) codes+=("104") ;;
            bg_bright_magenta) codes+=("105") ;;
            bg_bright_cyan) codes+=("106") ;;
            bg_bright_white) codes+=("107") ;;

            # --- 256 color foreground: color_123 ---
            color_*)
            if (( colors256 )); then
                local n="${arg#color_}"
                [[ "$n" =~ ^[0-9]+$ && "$n" -le 255 ]] && codes+=("38;5;$n")
            fi
            ;;

            # --- 256 color background: bg_color_123 ---
            bg_color_*)
            if (( colors256 )); then
                local n="${arg#bg_color_}"
                [[ "$n" =~ ^[0-9]+$ && "$n" -le 255 ]] && codes+=("48;5;$n")
            fi
            ;;

            # --- truecolor foreground: #RRGGBB ---
            \#??????)
                if (( truecolor ));
                then
                    local hex="${arg#\#}"
                    local r=$((16#${hex:0:2}))
                    local g=$((16#${hex:2:2}))
                    local b=$((16#${hex:4:2}))
                    codes+=("38;2;$r;$g;$b")
                fi
                ;;

            # --- truecolor background: bg_#RRGGBB ---
            bg_\#??????)
                if (( truecolor )); then
                    local hex="${arg#bg_\#}"
                    local r=$((16#${hex:0:2}))
                    local g=$((16#${hex:2:2}))
                    local b=$((16#${hex:4:2}))
                    codes+=("48;2;$r;$g;$b")
                fi
                ;;

            *)
                echo "Unknown style: $arg" >&2
                ;;
        esac

    done

    # reset overrides everything
    if [[ " ${codes[*]} " =~ " 0 " ]]; then
        printf '\033[0m'
        return
    fi

    if ((${#codes[@]} > 0)); then
        printf '\033[%sm' "$(IFS=';'; echo "${codes[*]}")"
    fi
}

###############################################################################
# 6. SCREEN SELECTION BUFFER
###############################################################################
#
# ANSI cannot read characters already displayed on the terminal.
#
# Maintain a virtual screen buffer yourself.
#

declare -ga SCREEN

screen_resize() {
    local num_rows=$1
    for ((i=0; i<num_rows; i++)); do
        SCREEN[$i]=""
    done
}

screen_put() {
    local row=$1
    local col=$2
    local str="$3"
    [[ $col -gt 1 ]] && ((col--)) && str="$(printf "%.0s " $(seq 1 $col))""$str"
    SCREEN[$row]="$str"
}

screen_get() {
    printf '%s\n' "${SCREEN[$1]}"
}

screen_render() {
    local row=1
    local col=1
    [[ -n $1 ]] && row=$1 && shift
    [[ -n $1 ]] && col=$1 && shift
    for item in "${SCREEN[@]}"; do
        print_at "$row" "$col" "$item"
        ((row++))
    done
}

selection_start=0
selection_end=0
selection_buffer=""

selection_copy() {
    selection_buffer=""

    local i

    for ((i=selection_start;i<=selection_end;i++)); do
        selection_buffer+="${SCREEN[$i]}"$'\n'
    done
}

selection_paste() {
    print_at "$1" "$2" "$selection_buffer"
}

###############################################################################
# 7. PRINT FILE / ARRAY / VARIABLE
###############################################################################

print_newline() {
    printf "\n"
}

prints() {
    printf "%s" "$1"
}

printsln() {
    printf "%s\n" "$1"
}

print_array_fmt() {
  declare -n array_name="$1"
  local sep="$2"
  local prev_e

  for e in "${array_name[@]}" "---"
  do
      [[ -n "$prev_e" ]] && \
          printf "%s" "$prev_e" && \
          [[ ! "$e" =~ ^---$ ]] && \
          printf "%s" "$sep"
      prev_e="$e"
  done
}

print_array() {
    local input="${2:-/dev/tty}"
    local output="${3:-/dev/tty}"

    print_array_at $(cursor_position "$input" "$output") "$1"
}

print_array_at() {
    local row=$1
    local col=$2
    shift 2

    declare -n array_name="$1"

    local item

    for item in "${array_name[@]}"; do
        print_at "$row" "$col" "$item"
        ((row++))
    done
}

print_var_at() {
    local row=$1
    local col=$2
    local text=$3

    print_at "$row" "$col" "$text"
}

print_file_at() {
    local row=$1
    local col=$2
    local file=$3

    local line

    while IFS= read -r line; do
        print_at "$row" "$col" "$line"
        ((row++))
    done < "$file"
}

###############################################################################
# 8. BASIC FORMATTING
###############################################################################

repeat_char() {
    printf "%*s" "$2" "" | tr ' ' "$1"
}

indent() {
    printf "%*s%s" "$1" "" "$2"
}

pad_right() {
    printf "%-*s" "$2" "$1"
}

pad_left() {
    printf "%*s" "$2" "$1"
}

center() {
    local width=$1
    local text=$2

    printf "%*s%s" $(((width-${#text})/2)) "" "$text"
}

align_right() {

    local width=$1
    local text=$2

    printf "%*s" "$width" "$text"
}

margin_left() {
    local margin=$1
    shift
    printf "%*s%s" "$margin" "" "$*"
}

###############################################################################
# 9. BOX DRAWING
###############################################################################

BOX_HEAVY_HOZ="━"
BOX_HEAVY_VER="┃"
BOX_HEAVY_UL="┏"
BOX_HEAVY_LL="┗"
BOX_HEAVY_UR="┓"
BOX_HEAVY_LR="┛"

print_hline() {
    printf "%.0s$BOX_HEAVY_HOZ" $(seq 1 $1)
}
print_vline() {
    local h=1
    [[ -n $1 ]] && h=$1
    for ((i=0; i<h; ++i)); do
        echo -n $BOX_HEAVY_VER
    done
}

print_ul() {
    echo -n $BOX_HEAVY_UL
}

print_ur() {
    echo -n $BOX_HEAVY_UR
}

print_ll() {
    echo -n $BOX_HEAVY_LL
}

print_lr() {
    echo -n $BOX_HEAVY_LR
}

print_box() {
    local row=1
    local col=1
    [[ "$1" =~ ^[[:digit:]]+$ ]] && row=$1 && shift
    [[ "$1" =~ ^[[:digit:]]+$ ]] && col=$1 && shift
    local str="$1"
    local strlen=${#str}
    local boxw=$((strlen + 2))

    cursor_move $row $col

    print_ul
    print_hline $boxw
    print_ur
    printf "\n"
    ((row++))
    cursor_move $row $col
    print_vline
    pad_left ' ' 1
    printf "$str"
    pad_right ' ' 1
    print_vline
    printf "\n"
    ((row++))
    cursor_move $row $col
    print_ll
    print_hline $boxw
    print_lr
}

###############################################################################
# 10. ARRAY SEARCH AND MANIPULATION
###############################################################################

assoc_array_find() {
    declare -n array_name="$1"
    local element="$2"
    local array_len=${#array_name[@]}
    local match_result=("${array_name[@]/"$element"/}")

    for i in "${!match_result[@]}"; do
        [[ -z "${match_result[$i]}" ]] && unset 'match_result[i]'
    done

    [[ ${#match_result[@]} -eq $array_len ]] && \
        return 1 || return 0
}

indexed_array_find() {
    declare -n array_name="$1"
    local element="$2"
    local array_len=${#array_name[@]}
    declare -a match_result
    local match_result=("${array_name[@]/"$element"/}")
    for i in ${!match_result[@]}
    do
        [[ -z "${match_result[$i]}" ]] && unset match_result[$i]
    done
    [[ ${#match_result[@]} -eq $array_len ]] && \
        return 1 || return 0
}

remove_assoc_array_item() {
    declare -n array_name="$1"
    local element="$2"
    local key

    for key in "${!array_name[@]}"; do
        if [[ "${array_name[$key]}" == "$element" ]]; then
            unset "array_name[$key]"
            break
        fi
    done

    return 0
}

remove_indexed_array_item() {
    declare -n array_name="$1"
    local element="$2"
    local array_len=${#array_name[@]}
    declare -a match_result
    #local match_result=("${array_name[@]/"$element"/}")
    #for i in ${!match_result[@]}
    for i in ${!array_name[@]}
    do
        #[[ -z "${match_result[$i]}" ]] && unset match_result[$i]
        [[ -n "${array_name[$i]}" && ${array_name[$i]} == "$element" ]] && \
            unset array_name[$i] && break
    done
    #[[ ${#match_result[@]} -ne $array_len ]] && \
    #    array_name=("${match_result[@]}")

    return 0
}

###############################################################################
# Utility
###############################################################################

term_size() {
    printf "%s %s\n" "$(tput lines)" "$(tput cols)"
}

reserve_space() {
    local lines=$((${1:-10}))

    __RESERVED_LINES=$lines

    # remember where the widget begins
    printf '\e7'

    # scroll terminal down
    printf '%*s' "$lines" '' | tr ' ' '\n'

    # return to widget origin
    #printf '\e8'

    # remember where the widget begins
    #printf '\e7'
}

release_space() {
    # remember where the widget begins
    #printf '\e7'

    for ((i=0;i<$((__RESERVED_LINES));i++)); do
        printf '\e[2K\e[1A'
    done && \
    printf '\e[2K' && \

    # return to widget origin
    printf '\e8'
}

insert_lines() {
    local n=${1:-1}
    printf '\e[%dL' "$n"
}

delete_lines() {
    local n=${1:-1}
    printf '\e[%dM' "$n"
}

scroll_down() {
    local n=${1:-1}
    printf '\e[%dT' "$n"
}

scroll_up() {
    local n=${1:-1}
    printf '\e[%dS' "$n"
}

viewport_begin() {
    local top=$1
    local bottom=$2

    printf '\e[%d;%dr' "$top" "$bottom"
    printf '\e[%d;1H' "$top"
}

viewport_end() {
    printf '\e[r'
}

push_screen() {
    local lines=$1

    for ((i=0;i<lines;i++)); do
        printf '\n'
    done && \

    printf '\e[%dA' "$lines"
}

pop_screen() {
    local lines=$1

    for ((i=0;i<lines;i++)); do
        printf '\e[2K\e[1A'
    done && \
    printf '\e[2K'
}

screen_enter() {
    printf '\e[?1049h'   # switch to alternate screen
    printf '\e[?25l'     # hide cursor
    printf '\e[2J\e[H'   # clear and home
}

screen_leave() {
    printf '\e[2J'
    printf '\e[?25h'     # show cursor
    printf '\e[?1049l'   # restore original screen
}


###############################

# Demonstration

function is_sourced {
    [[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0
    # Courtesy: mklement0 via Stack Overflow
    # https://stackoverflow.com/a/28776166
    # https://stackoverflow.com/users/45375/mklement0
    case ${0##*/} in bash|-bash) return 0;; esac
    return 1  # NOT sourced.
}

demo() {

    screen_enter

    # Header
    cursor_move 1 1
    #printf "Example Full-Screen Menu\n"
    #printf "========================\n\n"
    print_box 1 15 "Example Full-Screen Menu"

    # List
    items=(
        "Apple"
        "Banana"
        "Cherry"
        "Dragonfruit"
        "Elderberry"
        "Mango"
        "Guava"
    )

    row=5
    col=24
    for item in "${items[@]}"; do
        cursor_move $row $col
        printf "• %s" "$item"
        ((row++))
    done

    # Determine terminal size
    rows=$(tput lines)

    # Prompt on bottom line
    cursor_move "$rows" 1
    clear_line
    printf "Choose a fruit: "

    # Cursor is visible while typing
    printf '\e[?25h'
    read -r answer
    printf '\e[?25l'

    screen_leave

    $(indexed_array_find items "$answer") && \
      echo "You choose: $answer" || \
      echo "$answer not in ${items[*]}"
}

is_sourced || demo
