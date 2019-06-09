#!/bin/bash

check_todos="true"
check_version="true"
check_changelog="true"
scripts_path="Script"

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

# TODO check for TODOs

# TODO check for version bump

# TODO check for CHANGELOG update
