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
