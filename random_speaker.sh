#!/bin/sh

# -----------------------------------
# Project   : Khmer_word_recognition
# Author    : Chanmann Lim
#
# Changelogs:
#   - 01/29/2016  : file created.
# -----------------------------------

# exit on error
set -e

E_USAGE="Usage: $0 \$pool [\$search]

  \$pool     : (--trn | --tst)
  [\$search] : field value in speakers.csv
"

# show usage
show_usage() {
  echo "$E_USAGE" >&2
}

# main
main() {
  bash ./args_check.sh 1 $@ || (show_usage && exit 1)
  local Y=
  while [ -n "$1" ]; do
    local param="$1"
    case "$param" in
      "--trn" | "--tst" ) Y="$(cat wav/speakers.csv | grep "${param:2}")";;
      *                 ) Y="$(echo "$Y" | grep ",$param")"
    esac
    shift
  done
  
  local SPKR=( $(echo "$Y" | grep -o "spkr[0-9]*/") )
  local l=${#Y[*]}

  # stdout
  echo "${SPKR[$(( RANDOM % l ))]}"
}

# ------------------------------------
# random_speaker.sh
#
#   $1   : $POOL
#   [$2] : $SEARCH
# ------------------------------------

main $@
