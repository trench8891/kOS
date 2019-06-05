#!/bin/bash

# matcher for ks scripts
scriptspath="${SCRIPTS_PATH}"
if [ -z "${scriptspath}" ]; then
  scriptspath="Script/"
fi

# maximum line length, use -1 to disable
maxlinelength=${MAX_LINE_LENGTH}
if [ -z "${maxlinelength}" ]; then
  maxlinelength=60
fi

# declare array to hold errors
declare -a errors

# register an error
function regerr() {
  scriptpath="${1}"
  linenum="${2}"
  message="${3}"

  error="${scriptpath}:${linenum} ${message}"
  errors+=("${error}")
}

# iterate over all scripts
for script in $(find ${scriptpath} -name "*.ks"); do
  # check line lengths
  readarray lines < "${script}"
  for i in ${!lines[@]}; do
    line="${lines[${i}]}"
    if [ ${#line} -gt ${maxlinelength} ]; then
      let z=i+1
      regerr ${script} ${z} "line is too long (${#line})"
    fi
  done

  # ensure all statements end with a period
done

# print out any errors
if [ ${#errors[@]} -eq 0 ]; then
  echo "no issues found"
  exit 0
else
  for error in ${errors[@]}; do
    echo "${error}"
  done
fi

echo "linter in progress"
exit 1
