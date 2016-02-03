#!/bin/sh

# -----------------------------------
# Project   : Khmer_word_recognition
# Author    : Chanmann Lim
#
# Changelogs:
#   - 02/03/2016  : use args_check.sh
#   - 01/29/2016  : file created.
# -----------------------------------

# exit on error
set -e

# E_VARS
E_USAGE="Usage: $0 (triphone | monophone)"

# global variables
MODEL=
DIR=

# show usage
show_usage() {
  echo $E_USAGE >&2
}

# setup directory
setup() {
  bash ./args_check.sh 1 $@ || (show_usage && exit 1)
  local dir=experiments/$(date +"%F.%H%M").$1

  if [ ! -e "$dir" ]; then \
    mkdir -p "$dir"; fi

  DIR="$dir"
  MODEL="$1"

  # stdout
  echo "Setting up experiment:"
  echo "  root: `pwd`$dir"
  echo
}

# data preparation
prepare_data() {
  local testMale=$(bash ./random_speaker.sh m)
  local testFemale=$(bash ./random_speaker.sh f)

  cat scripts/mfclist | grep -v -e "$testMale/" -e "$testFemale/" > $DIR/mfclist_trn
  cat scripts/mfclist | grep -e "$testMale/" -e "$testFemale/" > $DIR/mfclist_tst

  # stdout
  echo "Data preparation:"
  echo "  Test male   : $testMale"
  echo "  Test female : $testFemale"
  echo
}

# model training
training() {
  echo "Model training: $MODEL"
  echo

  bash "./train_$MODEL.sh" $DIR/mfclist_trn
  echo
}

# evaluation
evaluate() {
  echo "Evaluation: $MODEL"
  echo

  bash ./decode.sh $DIR
  echo
}

# ------------------------------------
# runTest.sh
#
#   $1 : MODEL (triphone | monophone)
# ------------------------------------

  setup $1
  prepare_data
  training
  evaluate