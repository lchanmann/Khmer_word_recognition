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
E_USAGE="Usage: $0 (triphone | monophone) [\$target_directory [--rerun]]"

# global variables
MODEL=
DIR=
FLAG_RERUN=0

# show usage
show_usage() {
  echo $E_USAGE >&2
}

# setup directory
setup() {
  bash ./args_check.sh 1 $@ || (show_usage && exit 1)  
  MODEL="$1"
  DIR="$2"
  
  if [ -z "$2" ]; then
    DIR=experiments/$(date +"%F.%H%M").$MODEL
    mkdir "$DIR"
  fi
  # check for rerun flag
  if [ "$3" = "--rerun" ]; then
    FLAG_RERUN=1
  fi

  # stdout
  echo "Setting up experiment:"
  echo "  directory: $DIR"
  echo
}

# data preparation
prepare_data() {
  if [ "$FLAG_RERUN" -eq "0" ]; then
    # local testMale=$(bash ./random_speaker.sh m)
    # local testFemale=$(bash ./random_speaker.sh f)
    
    # use 4 neutral test speakers instead of randomization
    local testSpeakers="spkr4/ spkr8/ spkr1/ spkr11/"
    local grepOption=$(echo $testSpeakers | sed "s/\(spkr\)/\\-e \1/g")
    
    cat scripts/mfclist | grep -v ${grepOption} > $DIR/mfclist_trn
    cat scripts/mfclist | grep ${grepOption} > $DIR/mfclist_tst

    # stdoutr
    echo "Data preparation:"
    echo "  Test speakers: $testSpeakers"
    echo
  fi
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

# results summary
results_summary() {
  echo "Result summary: "
  echo
  
  tail -n 4 $DIR/results/result_*
}

# ------------------------------------
# runTest.sh
#
#   $1 : MODEL (triphone | monophone)
# ------------------------------------

  setup $@
  prepare_data
  training
  evaluate
  results_summary