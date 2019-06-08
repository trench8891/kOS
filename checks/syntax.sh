#!/bin/bash

scripts_path="Script"
check_lazy_global_off="true"

usage_message="Usage: $(basename "${0}") [-hg] [-p scripts_path]

Options:

      -g      Allow lazy globals to be left on

      -p      Path to kOS scripts. Default \"Script\""

while getopts hgp: opt; do
  case ${opt} in 
    h) 
      printf "\n%s\n\n" "${usage_message}"
      exit 0
      ;;
    g)
      check_lazy_global_off="false"
      ;;
    p)
      scripts_path="${OPTARG}"
      ;;
  esac
done

shift $((OPTIND-1))

arithmetic_operators="+  -  *  /  ^  e  (  )"
logic_operators="not  and  or  true  false  <>  >=  <=  =  >  <"
instructions_and_keywords="add all at batch break clearscreen compile copy declare delete
deploy do do edit else file for from from function global if
in list local lock log off on once parameter preserve print reboot
remove rename run set shutdown stage step switch then to toggle
unlock unset until volume wait when"

for iok in ${arithmetic_operators}; do
  echo "${iok}"
done

# # declare array to hold errors
# declare -a errors

# # register an error
# function regerr() {
#   script_path="${1}"
#   linenum="${2}"
#   message="${3}"

#   error="${script_path}:${linenum} ${message}"
#   errors+=("${error}")
# }

# # count number of files examined
# num_files=0

# # iterate over all scripts
# for script in $(find ${scripts_path} -name "*.ks"); do

# done
