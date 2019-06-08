#!/bin/bash

check_lazy_global_off="true"
max_line_length=55
scripts_path="Script"

usage_message="Usage: $(basename "${0}") [-hg] [-l <line-length-limit>] [-p scripts_path]

Options:

      -g      Allow lazy globals to be left on

      -l      Set maximum line length. Use value < 1 to skip check. Default 60

      -p      Path to kOS scripts. Default \"Script\""

while getopts hgl:p: opt; do
  case ${opt} in 
    h) 
      printf "\n%s\n\n" "${usage_message}"
      exit 0
      ;;
    g)
      check_lazy_global_off="false"
      ;;
    l)
      max_line_length=${OPTARG}
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
}

# iterate over all scripts
for script in $(find ${scripts_path} -name "*.ks"); do
  let num_files=num_files+1
  if [ ${max_line_length} -gt 0 ]; then
    line_num=0
    while read -r line; do
      let line_num=line_num+1

      # check line length
      if [ ${#line} -gt ${max_line_length} ]; then
        regerr ${script} ${line_num} "line is too long (${#line})"
      fi
    done < "${script}"
  fi
done

for error in "${errors[@]}"; do
  echo "${error}"
done
echo "found ${#errors[@]} errors in ${num_files} files"

# print out any errors
if [ "${#errors[@]}" -gt 0 ]; then
  exit 1
else
  exit 0
fi
