function projects() {
  local projects_dir=${HOME}/Projects
  local templates_dir=${HOME}/Templates/ProjectTemplates
  local ide project num_projects width re
  if [ -d ${projects_dir} ]; then
    num_projects=$(ls -1 ${projects_dir} | wc -l)
    if [[ ${num_projects} == "0" ]]; then
      echo No Available Projects!
      return
    fi

    re='^'
    width=0
    n=${num_projects}
    while [ ${n} -gt 0 ]
    do
      n=$[$n/10]
      width=$[$width+1]
      re=$re'[0-9]?'
    done
    re=$re'$' 

    local OPTIND
    while getopts ":hi:n:t:e:" arg $@; do
      case $arg in
        h )
          echo "Usage:"
          echo "    prj -h              Display this message"
          echo "    prj                 List available projects"
          echo "    prj [project]       Open project"
          echo "    prj -i [number]     Open project with number"
          echo "    prj -n [name]       Create new project"
          echo "    prj -t [template]   Use template"
          echo "    prj -e [editor]     Use given editor"
          return
          ;;
        i ) 
          if [ -n $OPTARG ]; then
            if [[ $OPTARG =~ ${re} ]]; then
              project=$OPTARG
            fi
          fi
          ;;
        n )
          if [[ ! -d ${projects_dir}/${OPTARG} ]]; then
            project=${OPTARG}
            mkdir ${projects_dir}/${project}
          else
            echo ${OPTARG} exists
            return
          fi
          ;;
        t )
          if [[ -f ${templates_dir}/${OPTARG}.tar.gz ]]; then
            if [ -z ${project} ]; then
              project="new_"${OPTARG}"_project_"$(date +%m_%d_%y_%H_%M)
              mkdir ${projects_dir}/${project}
            fi
            tar -xzf ${templates_dir}/${OPTARG}.tar.gz -C ${projects_dir}/${project}
          fi
          ;;
        e )
          if [ -n $OPTARG ]; then
            ide=$OPTARG
          fi
          ;;
        \? )
          echo Invalid option: ${OPTARG} 1>&2
          return
          ;;
        : )
          echo Invalid option: $OPTARG requires an argument 1>&2
          return
          ;;
      esac
    done

    if [ -z ${project} ]; then
      local arguments=($@)
      if [[ -n ${arguments[${OPTIND} - 1]} ]]; then
        project=${arguments[${OPTIND} - 1]}
      else
        echo Available projects:
        ls -1 ${projects_dir} | nl -w${width} -s" " | more

        echo
        echo Open project: 
        read project
      fi
    fi

    if [[ ${project} == "q" ]]; then
      return
    elif [[ ${project} =~ ${re} ]]; then
      if [[ ${project} -gt ${num_projects} ]] || [[ ${project} -lt 1 ]]; then
        echo Invalid index!
        return
      fi
      project=$(ls -1 ${projects_dir} | sed -n "${project}p")
    fi

    if [ -d ${projects_dir}/${project} ]; then
      cd ${projects_dir}/${project}
      if [ -n "${ide}" ]; then
        $ide ${projects_dir}/${project}
      fi
    else
      echo ${project} does not exist!
    fi
  fi
}

alias prj="projects"

function _projects() {
  local projects_dir=${HOME}/Projects
  local templates_dir=${HOME}/Templates/ProjectTemplates
  local cur prev
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}

  if [[ ${cur} == - ]]; then
    COMPREPLY=($(compgen -W "-h -i -n -t -e" -- ${cur}))
  else
    case ${prev} in
      -t)
        COMPREPLY=($(compgen -W "$(ls -1 ${templates_dir} | cut -d'.' -f1)" -- ${cur}))
        ;;
      -e)
        COMPREPLY=($(compgen -W "emacs vim gvim nano ed" -- ${cur}))
        ;;
      prj)
        ;&
      projects)
        COMPREPLY=($(compgen -W "$(ls -1 ${projects_dir})" -- ${cur}))
        ;;
      -i)
        ;&
      -n)
        ;&
    esac
  fi
}
complete -F _projects projects
complete -F _projects prj
