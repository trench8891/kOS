#!/bin/bash

set -e

check_todos="true"
check_version="true"
check_changelog="true"
scripts_path="Script"
version_file=".version"
version_regex="^([0-9]+\.){2}[0-9]+$"

todo_regex="//[[:space:]]*[Tt][Oo][Dd][Oo]"

failure="false"

usage_message="Usage: $(basename "${0}") [-htTvVcC] [-p scripts_path]

Options:

      -h      Show this usage message

      -t      Exclude TODO check

      -T      Perform TODO check ONLY. Conflicts with -t, -V, and -C

      -v      Exclude version bump check

      -V      Perform version bump check ONLY. Conflicts with -v, -T, and -C

      -c      Exclude CHANGELOG check

      -C      Perform CHANGELOG check ONLY. Conflicts with -c, -V, and -T

      -p      Path to kOS scripts. Default \"Script\""

while getopts htTvVcCp: opt; do
  case ${opt} in
    h) 
      printf "\n%s\n\n" "${usage_message}"
      exit 0
      ;;
    t)
      check_todos="false"
      ;;
    T)
      check_todos="true"
      check_version="false"
      check_changelog="false"
      ;;
    v)
      check_version="false"
      ;;
    V)
      check_version="true"
      check_todos="false"
      check_changelog="false"
      ;;
    c)
      check_changelog="false"
      ;;
    C)
      check_changelog="true"
      check_todos="false"
      check_version="false"
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

# # parse a version
# function parse_version() {
#   version_string="${1}"

#   # verify version string
#   if [[ ! "${version_string}" =~ ${version_regex} ]]; then
#     echo "invalid version: ${version_string}" >&2
#     exit 1
#   fi

#   IFS='.' read -ra split_version <<< "${version_string}"
#   printf "${split_version[0]} ${split_version[1]} ${split_version[2]}"
# }

# iterate over all scripts
for script in $(find ${scripts_path} -name "*.ks"); do
  let num_files=num_files+1
  line_num=0

  while read -r line; do
    let line_num=line_num+1

    # check for TODOs
    if [[ "${check_todos}" = "true" && "${line}" =~ ${todo_regex} ]]; then
      regerr ${script} ${line_num} "unresolved TODO"
    fi
  done < "${script}"
done

# print out any errors
if [ "${#errors[@]}" -gt 0 ]; then
  for error in "${errors[@]}"; do
    echo "${error}"
  done
  echo "found ${#errors[@]} TODOs in ${num_files} files"
  failure="true"
fi

base_branch=$(git show-branch -a | grep '\*' | grep -v `git rev-parse --abbrev-ref HEAD` | head -n1 | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//')

current_version=$(cat "${version_file}")
base_version=$(git show "${base_branch}":"${version_file}")

if [[ ! "${current_version}" =~ ${version_regex} ]]; then
  echo "invalid version on branch: ${current_version}"
  failure="true"
fi

if [[ ! "${base_version}" =~ ${version_regex} ]]; then
  echo "invalid base version: ${base_version}"
  failure="true"
fi

echo "${current_version}"
echo "${base_version}"

# TODO check for CHANGELOG update

if [[ "${failure}" = "true" ]]; then
  exit 1
else
  exit 0
fi
