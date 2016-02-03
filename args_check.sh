#/bin/sh

# -----------------------------------
# Project   : Khmer_word_recognition
# Author    : Chanmann Lim
#
# Changelogs:
#   - 02/03/2016  : file created.
# -----------------------------------

# main program
main() {
  local requiredArgs=$1
  local seenArgs=$2
  
  if [ "$requiredArgs" == "-1" ] || \
    [ "$requiredArgs" != "$seenArgs" ]; then
    exit 1; fi
}

# -----------------------------------
# args_check.sh - check if required 
#   arguments are provided
# -----------------------------------

main $1 $(( $#-1 ))
