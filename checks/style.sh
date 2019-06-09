#!/bin/bash

check_lazy_global="true"
check_fscope="true"
check_capitalization="true"
max_line_length=55
scripts_path="Script"

lazy_global_off_command="@LAZYGLOBAL OFF."
ignorable_line_regex="^[:space:]*((//)|$)"

declare -a instructions_and_keywords
instructions_and_keywords+=("add")
instructions_and_keywords+=("all")
instructions_and_keywords+=("at")
instructions_and_keywords+=("batch")
instructions_and_keywords+=("break")
instructions_and_keywords+=("clearscreen")
instructions_and_keywords+=("compile")
instructions_and_keywords+=("copy")
instructions_and_keywords+=("declare")
instructions_and_keywords+=("delete")
instructions_and_keywords+=("deploy")
instructions_and_keywords+=("do")
instructions_and_keywords+=("do")
instructions_and_keywords+=("edit")
instructions_and_keywords+=("else")
instructions_and_keywords+=("file")
instructions_and_keywords+=("for")
instructions_and_keywords+=("from")
instructions_and_keywords+=("from")
instructions_and_keywords+=("function")
instructions_and_keywords+=("global")
instructions_and_keywords+=("if")
instructions_and_keywords+=("in")
instructions_and_keywords+=("list")
instructions_and_keywords+=("local")
instructions_and_keywords+=("lock")
instructions_and_keywords+=("log")
instructions_and_keywords+=("off")
instructions_and_keywords+=("on")
instructions_and_keywords+=("once")
instructions_and_keywords+=("parameter")
instructions_and_keywords+=("preserve")
instructions_and_keywords+=("print")
instructions_and_keywords+=("reboot")
instructions_and_keywords+=("remove")
instructions_and_keywords+=("rename")
instructions_and_keywords+=("run")
instructions_and_keywords+=("set")
instructions_and_keywords+=("shutdown")
instructions_and_keywords+=("stage")
instructions_and_keywords+=("step")
instructions_and_keywords+=("switch")
instructions_and_keywords+=("then")
instructions_and_keywords+=("to")
instructions_and_keywords+=("toggle")
instructions_and_keywords+=("unlock")
instructions_and_keywords+=("unset")
instructions_and_keywords+=("until")
instructions_and_keywords+=("volume")
instructions_and_keywords+=("wait")
instructions_and_keywords+=("when")

usage_message="Usage: $(basename "${0}") [-hgGfFcC] [-l <line-length-limit>] [-L <line-length-limit>] [-p scripts_path]

Options:

      -h      Show this usage message

      -g      Exclude lazy globals off check

      -G      Perform lazy globals off check ONLY. Conflicts with -g, -L, -F, and -C

      -f      Exclude explicit function scope check

      -F      Perform explicit function scope check ONLY. Conflicts with -f, -G, -C, and -L

      -c      Exclude instruction and keyword capitalization check

      -C      Perform instruction and keyword capitalization check ONLY. Conflicts with -c, -G, -F, and -L

      -l      Set maximum line length. Use value < 1 to skip check. Default 55

      -L      Perform line length check (using provided maximum length) ONLY. Conflicts with -l, -G, -F, and -C

      -p      Path to kOS scripts. Default \"Script\""

while getopts hgGfFcCl:L:p: opt; do
  case ${opt} in 
    h) 
      printf "\n%s\n\n" "${usage_message}"
      exit 0
      ;;
    g)
      check_lazy_global="false"
      ;;
    G)
      check_lazy_global="true"
      check_fscope="false"
      check_capitalization="false"
      max_line_length=0
      ;;
    f)
      check_fscope="false"
      ;;
    F)
      check_fscope="true"
      check_lazy_global="false"
      check_capitalization="false"
      max_line_length=0
      ;;
    c)
      check_capitalization="false"
      ;;
    C)
      check_capitalization="true"
      check_lazy_global="false"
      check_fscope="false"
      max_line_length=0
      ;;
    l)
      max_line_length=${OPTARG}
      ;;
    L)
      max_line_length=${OPTARG}
      check_lazy_global="false"
      check_fscope="false"
      check_capitalization="false"
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
  check_lazy_global_script="${check_lazy_global}"

  while read -r line; do
    let line_num=line_num+1

    # check lazy globals
    if [[ "${check_lazy_global_script}" = "true" && ! "${line}" =~ ${ignorable_line_regex} ]]; then
      check_lazy_global_script="false" # there's only one possible line we want to check, so either way we're done
      if [[ "${line}" != "${lazy_global_off_command}" ]]; then
        regerr ${script} ${line_num} "lazy globals not turned off"
      fi
    fi

    # TODO check explicit function scope
    # file warning if FUNCTION appears outside a comment and not preceded by either LOCAL or GLOBAL
    # FUNCTION, LOCAL, and GLOBAL keywords case insensitive
    # if [[ "${check_fscope}" = "true" ]]

    # TODO check instruction and keyword capitalization

    # check line length
    if [[ ${max_line_length} -gt 0 && ${#line} -gt ${max_line_length} ]]; then
      regerr ${script} ${line_num} "line is too long (${#line})"
    fi
  done < "${script}"
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
