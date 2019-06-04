#!/bin/bash

# matcher for ks scripts
scriptspath="${SCRIPTS_PATH}"
if [ -z "${scriptspath}" ]; then
  scriptspath="Script/*.ks"
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

  error="${scriptpath}:${linenum} #{message}"
  errors+=("${error}")
}

# iterate over all scripts
for script in ${scriptspath}; do
  # check line lengths
  readarray lines < "${script}"
  for i in ${!lines[@]}; do
    if [ ${#line} -gt ${maxlinelength} ]; then
      regerr ${script} ${i} "line is too long (${#line})"
    fi
  done

  # ensure all statements end with a period
done

# print out any errors
echo "linter in progress"
exit 1
