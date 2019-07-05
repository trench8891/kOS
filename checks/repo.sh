#!/usr/bin/env bash

set -e

check_todos="true"
check_version="true"
check_changelog="true"
scripts_path="Script"

version_file=".version"
changelog_file="CHANGELOG"

todo_regex="//[[:space:]]*[Tt][Oo][Dd][Oo]"
version_regex="^([0-9]+\.){2}[0-9]+$"

usage_message="Usage: $(basename "${0}") [-htTvVcC] [-p scripts_path]

Options:

      -h      Show this usage message

      -t      Exclude TODO check

      -T      Perform TODO check ONLY. Conflicts with -t, -V, and -C

      -v      Exclude version increment check

      -V      Perform version increment check ONLY. Conflicts with -v, -T, and -C

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
  exit 1
fi

base_branch=$(git show-branch -a | grep '\*' | grep -v `git rev-parse --abbrev-ref HEAD` | head -n1 | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//')
current_version=$(cat "${version_file}")

# check for valid version increment
if [[ "${check_version}" = "true" ]]; then
  base_version=$(git show "${base_branch}":"${version_file}")

  if [[ ! "${current_version}" =~ ${version_regex} ]]; then
    echo "invalid version on branch: ${current_version}"
    exit 1
  fi

  if [[ ! "${base_version}" =~ ${version_regex} ]]; then
    echo "invalid base version: ${base_version}"
    exit 1
  fi

  IFS='.' read -ra current_v_a <<< "${current_version}"
  IFS='.' read -ra base_v_a <<< "${base_version}"

  if [[ ${current_v_a[0]} -eq $(expr ${base_v_a[0]} + 1) ]]; then
    if [[ ${current_v_a[1]} -ne 0 ]]; then
      echo "invalid minor version increment: ${base_v_a[0]}.${base_v_a[1]} -> ${current_v_a[0]}.${current_v_a[1]}"
      exit 1
    elif [[ ${current_v_a[2]} -ne 0 ]]; then
      echo "invalid patch version increment: ${base_version} -> ${current_version}"
      exit 1
    fi
  elif [[ ${current_v_a[0]} -eq ${base_v_a[0]} ]]; then
    if [[ ${current_v_a[1]} -eq $(expr ${base_v_a[1]} + 1) ]]; then
      if [[ ${current_v_a[2]} -ne 0 ]]; then
        echo "invalid patch version increment: ${base_version} -> ${current_version}"
        exit 1
      fi
    elif [[ ${current_v_a[1]} -eq ${base_v_a[1]} ]]; then
      if [[ ${current_v_a[2]} -eq ${base_v_a[2]} ]]; then
        echo "no version increment detected: ${base_version} -> ${current_version}"
        exit 1
      elif [[ ${current_v_a[2]} -ne $(expr ${base_v_a[2]} + 1) ]]; then
        echo "invalid patch version increment: ${base_version} -> ${current_version}"
        exit 1
      fi
    else
      echo "invalid minor version increment: ${base_v_a[0]}.${base_v_a[1]} -> ${current_v_a[0]}.${current_v_a[1]}"
      exit 1
    fi
  else
    echo "invalid major version increment: ${base_v_a[0]} -> ${current_v_a[0]}"
    exit 1
  fi
fi

if [[ "${check_changelog}" = "true" ]]; then
  changelog_version=$(head -n 1 "${changelog_file}")
  if [[ $(head -n 1 "${changelog_file}") != "${current_version}" ]]; then
    echo "CHANGELOG out of date"
    exit 1
  fi
fi

exit 0
