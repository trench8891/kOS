#!/usr/bin/env bash

set -e
shopt -s extglob

scripts_path="Script"
separator_regex="([^_[:alnum:]]|$)"
identifier_regex="[_[:alpha:]][_[:alnum:]]*"

tail=""

usage_message="Usage: $(basename "${0}") [-hl] [-p scripts_path]

Options:

      -h      Show this usage message

      -l      Lenient mode. By default references to identifiers not explicitly declared will cause an error.
              In lenient mode, any unknown identifiers in a non-boot script will be assumed to have been defined elsewhere
              with GLOBAL scope.
              Identifiers in scripts in the boot directory however must ALWAYS be explicitly defined.

      -p      Path to kOS scripts. Default \"Script\""

while getopts hlp: opt; do
  case ${opt} in 
    h) 
      printf "\n%s\n\n" "${usage_message}"
      exit 0
      ;;
    l)
      lenient_mode="true"
      ;;
    p)
      scripts_path="${OPTARG}"
      ;;
  esac
done

shift $((OPTIND-1))

# declare array to hold errors
declare -a errors

# count number of files examined
num_files=0

# register an error
function regerr() {
  script_path="${1}"
  linenum="${2}"
  message="${3}"

  error="${script_path}:${linenum} ${message}"
  errors+=("${error}")

  breakflag=true
}

# drop the head of the tail
function swallow_tail() {
  word="${1}"

  pattern=""
  for i in $(seq 1 ${#word}); do
    pattern="${pattern}[$(echo ${word:i-1:1} | sed 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/')$(echo ${word:i-1:1} | sed 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/')]"
  done
  pattern=${pattern}*([[:space:]])
  tail=${tail##${pattern}}
}

# iterate over all scripts
for script in $(find ${scripts_path} -name "*.ks"); do
  let num_files=num_files+1
  line_num=0
  lazyglobal="on"
  directives_valid="true"
  mode="start"
  breakflag="false"

  while read -r line; do
    if [[ "${breakflag}" = "true" ]]; then
      break
    fi

    let line_num=line_num+1
    tail="${line}"

    while [[ -n "${tail}" ]]; do
      if [[ "${breakflag}" = "true" ]]; then
        break
      fi

      if [[ "${tail}" =~ ^// ]]; then
        tail=""
      else
        # echo "${script}:${line_num}:${mode} ${tail}"
        case ${mode} in
          start)
            if [[ "${tail}" =~ ^@ ]]; then
              tail="${tail:1}"
              mode="directive"
            elif [[ "${tail}" =~ ^[Dd][Ee][Cc][Ll][Aa][Rr][Ee]${separator_regex} ]]; then
              swallow_tail "declare"
              directives_valid="false"
              mode="declare"
            elif [[ "${tail}" =~ ^[Pp][Aa][Rr][Aa][Mm][Ee][Tt][Ee][Rr]${separator_regex} ]]; then
              swallow_tail "parameter"
              directives_valid="false"
              mode="declareParameter"
            else
              regerr ${script} ${line_num} "unknown command: $(echo "${tail}" | sed 's/[^_[:alnum:]].*$//')"
            fi
            ;;
          directive)
            if [[ "${directives_valid}" != "true" ]]; then
              regerr ${script} ${line_num} "compiler directives must precede commands"
            else
              if [[ "${tail}" =~ ^[Ll][Aa][Zz][Yy][Gg][Ll][Oo][Bb][Aa][Ll]${separator_regex} ]]; then
                swallow_tail "lazyglobal"
                mode="lazyGlobal"
              else
                regerr ${script} ${line_num} "unknown compiler directive: $(echo "${tail}" | sed 's/[^_[:alnum:]].*$//')"
              fi
            fi
            ;;
          lazyGlobal)
            if [[ "${tail}" =~ ^[Oo][Ff][Ff]${separator_regex} ]]; then
              lazyglobal="off"
              swallow_tail "off"
              mode="expectPeriod"
            elif [[ "${tail}" =~ ^[Oo][Nn]${separator_regex} ]]; then
              lazyglobal="on"
              swallow_tail "on"
              mode="expectPeriod"
            elif [[ "${tail}" =~ ^[^_[:alnum:]] ]]; then
              regerr ${script} ${line_num} "unexpected separator: \"${tail:0:1}\""
            else
              regerr ${script} ${line_num} "invalid lazy global mode: $(echo "${tail}" | sed 's/[^_[:alnum:]].*$//')"
            fi
            ;;
          expectPeriod)
            if [[ "${tail}" =~ ^\. ]]; then
              mode="start"
              tail="${tail:1}"
            else
              regerr ${script} ${line_num} "missing period"
            fi
            ;;
          declare)
            if [[ "${tail}" =~ ^[Pp][Aa][Rr][Aa][Mm][Ee][Tt][Ee][Rr]${separator_regex} ]]; then
              swallow_tail "parameter"
              mode="declareParameter"
            else
              regerr ${script} ${line_num} "unknown DECLARE statement: $(echo "${tail}" | sed 's/[^_[:alnum:]].*$//')"
            fi
            ;;
          declareParameter)
            if [[ "${tail}" =~ ^${identifier_regex}${separator_regex} ]]; then
              tail=$(echo "${tail}" | sed "s/${identifier_regex}//")
              mode="expectPeriod"
            else
              regerr ${script} ${line_num} "invalid identifier: $(echo "${tail}" | sed 's/[^_[:alnum:]].*$//')"
            fi 
            ;;
          *)
            regerr ${script} ${line_num} "unknown mode: ${mode}"
        esac
      fi
    done
  done < "${script}"
done

# print out any errors
for error in "${errors[@]}"; do
  printf "${error}\n"
done
printf "found errors in ${num_files} files\n"

if [ "${#errors[@]}" -gt 0 ]; then
  exit 1
else
  exit 0
fi
