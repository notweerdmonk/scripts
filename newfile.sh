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

function create_file(){
  local file=$(find ~/Templates/ -name "*.$1")
  if [ -z ${file} ]; then
    echo 'unrecognized format:' ${1} >> /dev/stderr
    echo 'availables templates:';
    for f in $(ls -p ~/Templates | grep -v /); do
      echo ${f}
    done
    return
  fi
  if [ -n "$2" ]; then
    cp ${file} "$PWD/$2.$1"
  else
    cp ${file} $PWD
  fi
}

function newfile(){
  if [ -n "$1" ]; then
    local ext_idx=`expr index "$1" '.'`
    local ext=${1:${ext_idx}}
    if [ ${ext_idx} -gt 0 ]; then
      local filename=${1:0:$((${ext_idx} - 1))}
    fi
    create_file ${ext} ${filename}
  fi
}

function _newfile_completion(){
  local cur prev wordlist filename
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  if [[ "${cur}" =~ ^[a-zA-Z0-9_]+\. ]]; then
    filename=${cur:0:`expr index "${cur}" '.'` - 1}
    for ext in $(ls -p ~/Templates | grep -v / | cut -f2 -d'.'); do
      wordlist="$wordlist ${filename}.${ext}"
    done;
  else
    wordlist=$(ls -1 ~/Templates -I ProjectTemplates | cut -f2 -d'.')
  fi
  COMPREPLY=($(compgen -W "${wordlist}" -- ${cur}))
}

complete -F _newfile_completion newfile
