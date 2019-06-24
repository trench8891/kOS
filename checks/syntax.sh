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

# count number of files examined
num_files=0

# count number of files examined
num_files=0

# register an error
function printerr() {
  script_path="${1}"
  linenum="${2}"
  message="${3}"

  echo "${script_path}:${linenum} ${message}"
}

# iterate over all scripts
for script in $(find ${scripts_path} -name "*.ks"); do
  let num_files=num_files+1
  line_num=0
  lazyglobal="on"
  instruction_count=0
  mode="start"

  while read -r line; do
    let line_num=line_num+1
    tail="${line}"

    while [[ -n "${tail}" ]]; do
      if [[ "${tail}" =~ ^// ]]; then
        tail=""
      else
        case ${mode} in
          start)
            if [[ "${tail}" =~ ^@ ]]; then
              mode="directive"
              tail="${tail:1}"
            else
              printerr ${script} ${line_num} "unknown command: $(echo "${tail}" | sed 's/[[:space:](:].*$//')"
              exit 1
            fi
            ;;
          directive)
            if [[ ${instruction_count} -gt 0 ]]; then
              printerr ${script} ${line_num} "compiler directives must precede commands"
              exit 1
            else
              if [[ "${tail}" =~ ^[Ll][Aa][Zz][Yy][Gg][Ll][Oo][Bb][Aa][Ll][[:space:]$] ]]; then
                tail=$(echo "${tail}" | sed -E 's/^[Ll][Aa][Zz][Yy][Gg][Ll][Oo][Bb][Aa][Ll][[:space:]$]+//')
                mode="lazyGlobal"
              else
                printerr ${script} ${line_num} "unknown compiler directive: $(echo "${tail}" | sed 's/[[:space:]].*$//')"
                exit 1
              fi
            fi
            ;;
          *)
            echo "unknown mode: ${mode}"
            exit 1
        esac
      fi
    done
  done < "${script}"
done
