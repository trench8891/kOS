#!/bin/bash

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

declare -a arithmetic_operators
arithmetic_operators+=("+")
arithmetic_operators+=("-")
arithmetic_operators+=("*")
arithmetic_operators+=("/")
arithmetic_operators+=("^")
arithmetic_operators+=("e")
arithmetic_operators+=("(")
arithmetic_operators+=(")")

declare -a logic_operators
logic_operators+=("not")
logic_operators+=("and")
logic_operators+=("or")
logic_operators+=("true")
logic_operators+=("false")
logic_operators+=("<>")
logic_operators+=(">=")
logic_operators+=("<=")
logic_operators+=("=")
logic_operators+=(">")
logic_operators+=("<")

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
instructions_and_keywords+=("edit")
instructions_and_keywords+=("else")
instructions_and_keywords+=("file")
instructions_and_keywords+=("for")
instructions_and_keywords+=("from")
instructions_and_keywords+=("function")
instructions_and_keywords+=("global")
instructions_and_keywords+=("if")
instructions_and_keywords+=("in")
instructions_and_keywords+=("is")
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

declare -a other_symbols
other_symbols+=("{")
other_symbols+=("}")
other_symbols+=("[")
other_symbols+=("]")
other_symbols+=(",")
other_symbols+=(":")
other_symbols+=("//")

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
              echo "${tail}"
            else
              tail=""
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
