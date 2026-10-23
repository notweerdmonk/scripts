#!/usr/bin/env bash

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
# For more information, please refer to <https://unlicense.org/>

# notweerdmonk 2026

# icebarg - bash argument parser

set -Eeuo pipefail

# Defaults for consuming scripts; they override these.
scriptname="${scriptname:-$(basename "${BASH_SOURCE[0]}")}"
scriptdesc="${scriptdesc:-}"

# Requirements for make_optsdesc:
#   Each option is defined as `name:arg[:desc]`, comma-separated.
#   - `arg` means the option takes a value.
#   - `noarg` means the option is a boolean flag.
#   - The text after the second colon is the human-readable description.
#   Example: type:arg:Type of key, key:arg:Key to store, json:noarg:Output as JSON

# Snippet: make_optstring
#   # Input format: "longname:arg,longname:noarg"
#   optstring_input="format:noarg,quality:arg,retries:arg,help:noarg"
#   optstring="$(make_optstring "$optstring_input")"
#   # -> -o -fq:rq:h -l format,quality,retries,help

# Examples:

#   # The consuming script sets these itself.
#   scriptname="mytool"
#   scriptdesc="Does a helpful thing"

#   source icebarg.bash

#   optstring_input="format:noarg,quality:arg,retries:arg,help:noarg"
#   optstring="$(make_optstring "$optstring_input")"

#   optdesc_input="format:noarg:Output format (mp3, flac, opus),quality:arg:Quality (0-11),retries:arg:Number of retries,help:noarg:Display this message"
#   eval "$(make_optsdesc $optdesc_input)"

#   if opts="$(parse_opts "$optstring" "$@")"; then
#     eval set -- "$opts"
#   else
#     [[ $# -eq 0 ]] && usage
#     exit 1
#   fi

#   # assign option values to variables.
#   [[ -n "$1" && ! "$1" =~ ^-{1,2}.*$ ]] && \
#     {
#       action="$1"
#       shift
#     }
#   while true; do
#     case "$1" in
#       -f|--format)
#         format="$2"
#         shift 2
#         ;;
#       -q|--quality)
#         quality="$2"
#         shift 2
#         ;;
#       -r|--retries)
#         retries="$2"
#         shift 2
#         ;;
#       -h|--help)
#         print_usage "$scriptname" "$scriptdesc" optdesc
#         exit
#         ;;
#       --)
#         shift
#         break
#         ;;
#       *)
#         break
#         ;;
#     esac
#   done

#   main "$@"

# Build the option string expected by GNU getopt.
# Input format: "longname:arg,longname:noarg"
make_optstring() {
  [[ $# -eq 0 ]] && return 0

  local short_opts=""
  local long_opts=""

  # Parse the comma-separated option definitions.
  IFS="," read -r -a args <<< "$@"
  for arg in "${args[@]}"
  do
    opt="${arg%%:*}"
    arg_required="${arg##*:}"

    # An option takes an argument unless marked "noarg" or left unspecified.
    [[ "$arg_required" == "noarg" || -z "$arg_required" ]] && \
      arg_required=0 || \
      arg_required=1

    [[ -n "$long_opts" ]] && long_opts+=","

    # Use the first letter of the long option as its short option.
    short_opts+="${opt:0:1}"
    long_opts+="${opt}"

    # A colon marks options that require an argument.
    [[ $arg_required -ne 0 ]] && \
      {
        short_opts+=":"
        long_opts+=":"
      }
  done

  echo "-o -$short_opts -l $long_opts"
}

# Build and declare an array of formatted option descriptions for the help text.
# Input format: "longname:arg:Description,longname:noarg:Description"
make_optsdesc() {
  [[ $# -eq 0 ]] && return 0

  declare -a optdesc
  local desc_col_indent=32

  # ANSI escape sequences used to bold option names in the usage output.
  local bold=$'\x1b[1m'
  local normal=$'\x1b[0m'

  IFS="," read -r -a args <<< "$@"
  for arg in "${args[@]}"
  do
    local opt="${arg%%:*}"
    local arg_required="${arg#*:}"
    arg_required="${arg_required%%:*}"
    local desc="${arg##*:}"

    local short_opt="${opt:0:1}"
    local long_opt="${opt}"

    # Display required arguments as =LONGNAME; omit this for flag options.
    [[ "$arg_required" == "noarg" || -z "$arg_required" ]] && \
      arg_required="" || \
      arg_required="=${long_opt^^}"

    local opts="-$short_opt, --$long_opt"

    # Set a tab-stop-aligned column for the option descriptions.
    local desc_col_width=$((${#opts} + ${#arg_required}))
    [[ $desc_col_width -ge $desc_col_indent ]] && \
      {
        desc_col_indent=$((($desc_col_width / 8) * 8))
        [[ $(($desc_col_width % 8)) -ge 0 ]] && \
          desc_col_indent=$(($desc_col_indent + 8))
      }

    # Format one option and its description, then add it to the array.
    local descline
    descline="$(
      printf -- "\t%s%s%s%s%*s%s" \
        "$bold" "$opts" "$normal" "$arg_required" \
        $(($desc_col_indent - $desc_col_width)) " " "$desc"
    )"

    optdesc+=("$descline")

    unset arg_required
  done

  # Emit a declaration that can be evaluated to create the array in the caller.
  declare -p optdesc
}

# Print the script's usage instructions and available options.
print_usage() {
  declare -n optdesc_name="$3"

  local bold=$'\x1b[1m'
  local normal=$'\x1b[0m'

  printf "%s - %s\n\n" "$1" "$2"
  printf "USAGE\n"
  printf "\t%s [OPTION]...\n\n" "$1"
  printf "OPTIONS\n"
  for desc in "${optdesc_name[@]}"
  do
    printf "%s\n" "$desc"
  done
  printf "\n"
}

# Parse the command-line options. On failure, show usage and return getopt's
# exit status.
parse_opts() {
  [[ $# -eq 0 ]] && return 255

  local optstring="$1"
  shift

  [[ $# -eq 0 ]] && return 255

  if opts=$(getopt $optstring -n "$scriptname" -- "$@")
  then
    echo "$opts"
  else
    status=$?
    [[ -v DEBUG && $DEBUG -ge 2 ]] && \
    printf "getopt failed (exit status %d)\n" "$status" >&2
    printf "\n" >&2
    print_usage "$scriptname" "$scriptdesc" optdesc >&2
    exit $status
  fi
}
