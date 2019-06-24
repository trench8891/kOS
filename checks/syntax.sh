#!/bin/bash

set -e

scripts_path="Script"

identifier_regex="^[_a-zA-Z][_a-zA-Z0-9]*$"
suffix_separator=":"

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

# count number of files examined
num_files=0

# register an error
function regerr() {
  script_path="${1}"
  linenum="${2}"
  message="${3}"

  error="${script_path}:${linenum} ${message}"
  errors+=("${error}")
}

# iterate over all scripts
for script in $(find ${scripts_path} -name "*.ks"); do
  let num_files=num_files+1
  line_num=0
  lazyglobal="on"
  instruction_count=0
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
        case ${mode} in
          start)
            if [[ "${tail}" =~ ^@ ]]; then
              mode="directive"
              tail="${tail:1}"
            else
              regerr ${script} ${line_num} "unknown command: $(echo "${tail}" | sed 's/[[:space:](:.].*$//')"
              breakflag="true"
            fi
            ;;
          directive)
            if [[ ${instruction_count} -gt 0 ]]; then
              regerr ${script} ${line_num} "compiler directives must precede commands"
              breakflag="true"
            else
              if [[ "${tail}" =~ ^[Ll][Aa][Zz][Yy][Gg][Ll][Oo][Bb][Aa][Ll][[:space:]$.] ]]; then
                tail=$(echo "${tail}" | sed -E 's/^[Ll][Aa][Zz][Yy][Gg][Ll][Oo][Bb][Aa][Ll][[:space:]$.]+//')
                mode="lazyGlobal"
              else
                regerr ${script} ${line_num} "unknown compiler directive: $(echo "${tail}" | sed 's/[[:space:]].*$//')"
                breakflag="true"
              fi
            fi
            ;;
          lazyGlobal)
            if [[ "${tail}" =~ ^[Oo][Ff][Ff][[:space:]$.] ]]; then
              lazyglobal="off"
              tail=$(echo "${tail}" | sed -E 's/^[Oo][Ff][Ff][[:space:]$.]+//')
              mode="expectEnd"
            elif [[ "${tail}" =~ ^[Oo][Nn][[:space:]$.] ]]; then
              lazyglobal="on"
              tail=$(echo "${tail}" | sed -E 's/^[Oo][Nn][[:space:]$.]+//')
              mode="expectEnd"
            else
              regerr ${script} ${line_num} "invalid lazy global mode: $(echo "${tail}" | sed 's/[[:space:](:.].*$//')"
              breakflag="true"
            fi
            ;;
          *)
            regerr ${script} ${line_num} "unknown mode: ${mode}"
            breakflag="true"
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
