#!/bin/bash

set -e

scripts_path="Script"
separator_regex="([^_[:alnum:]]|$)"

tail=""

usage_message="Usage: $(basename "${0}") [-h] [-p scripts_path]

Options:

      -h      Show this usage message

      -p      Path to kOS scripts. Default \"Script\""

while getopts hp: opt; do
  case ${opt} in 
    h) 
      printf "\n%s\n\n" "${usage_message}"
      exit 0
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
              tail=$(echo "${tail}" | sed 's/^[Dd][Ee][Cc][Ll][Aa][Rr][Ee][[:space:]]*//')
              directives_valid="false"
              mode="declare"
            elif [[ "${tail}" =~ ^[Pp][Aa][Rr][Aa][Mm][Ee][Tt][Ee][Rr]${separator_regex} ]]; then
              tail=$(echo "${tail}" | sed 's/^[Pp][Aa][Rr][Aa][Mm][Ee][Tt][Ee][Rr][[:space:]]*//')
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
                tail=$(echo "${tail}" | sed 's/^[Ll][Aa][Zz][Yy][Gg][Ll][Oo][Bb][Aa][Ll][[:space:]]*//')
                mode="lazyGlobal"
              else
                regerr ${script} ${line_num} "unknown compiler directive: $(echo "${tail}" | sed 's/[^_[:alnum:]].*$//')"
              fi
            fi
            ;;
          lazyGlobal)
            if [[ "${tail}" =~ ^[Oo][Ff][Ff]${separator_regex} ]]; then
              lazyglobal="off"
              tail=$(echo "${tail}" | sed 's/^[Oo][Ff][Ff][[:space:]]*//')
              mode="expectPeriod"
            elif [[ "${tail}" =~ ^[Oo][Nn]${separator_regex} ]]; then
              lazyglobal="on"
              tail=$(echo "${tail}" | sed 's/^[Oo][Nn][[:space:]]*//')
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
              tail=$(echo "${tail}" | sed 's/^[Pp][Aa][Rr][Aa][Mm][Ee][Tt][Ee][Rr][[:space:]]*//')
              mode="declareParameter"
            else
              regerr ${script} ${line_num} "unknown DECLARE statement: $(echo "${tail}" | sed 's/[^_[:alnum:]].*$//')"
            fi
            ;;
          # declareParameter)
            
          #   ;;
          *)
            echo "${tail}"
            regerr ${script} ${line_num} "unknown mode: ${mode}"
        esac
      fi
    done
  done < "${script}"
done

# print out any errors
for error in "${errors[@]}"; do
  echo "${error}"
done
echo "found errors in ${num_files} files"

if [ "${#errors[@]}" -gt 0 ]; then
  exit 1
else
  exit 0
fi
