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

USAGE="Usage: random_speaker.sh (m | f)"

# check for required argument
if [ "$#" -ne "1" ]; then
  echo $USAGE >&2
  exit 1
fi

# function
func() {
  local gender=$1
  local Y=( $(cat wav/speakers.csv \
    | grep ",$gender," \
    | sed "s/,.*/ /") )
  local l=${#Y[*]}

  # stdout
  echo "${Y[$(( RANDOM % l ))]}"
}

# ------------------------------------
# random_speaker.sh
#
#   $1 : (m | f)
# ------------------------------------

func $1
