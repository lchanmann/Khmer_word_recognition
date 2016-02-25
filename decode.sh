#!/bin/sh

# -----------------------------------
# Project   : Khmer_word_recognition
# Author    : Chanmann Lim
#
# Changelogs:
#   - 01/31/2016  : refactoring.
# -----------------------------------

# exit on error
set -e

# E_VARS
E_USAGE="Usage: $0 \$directory"

# global variables
SCRIPT_NAME=$0
DIR=
HMMLIST=
MFCLIST=

# show usage
show_usage() {
  echo $E_USAGE >&2
}

# setup directory
setup() {
  bash ./args_check.sh 1 $@ || (show_usage && exit 1)
  DIR="$1"
  HMMLIST="$DIR/hmmlist"
  MFCLIST="$DIR/mfclist_tst"

  mkdir -p $DIR/results

  # stdout
  echo "$SCRIPT_NAME -> setup()"
  echo 
}

# viterbi decoding
viterbi_decode() {
  echo "$SCRIPT_NAME -> viterbi_decode()"
  echo "  \$models: $1"
  echo

  local models=$1
  local num=$(basename $models | sed "s/.*_\([0-9]*\)_hmm.mmf$/\1/")

  # viterbi decoding
  HVite -A -D -V \
    -T 1 -l '*' -i $DIR/results/output_${num}.mlf \
    -C configs/hvite.conf -z zoo -q Atvaldmnr -s 2.4 -p -1.2 \
    -S $MFCLIST -H $models -w lm/word_network.lat \
    dictionary/dictionary.dct $HMMLIST > $DIR/results/hvite_${num}.log

  # generate result statistics
  HResults \
    -f -I labels/words.mlf /dev/null $DIR/results/output_${num}.mlf \
    > $DIR/results/result_${num}.log
}

# recognize
recognize() {
  ls -1d $DIR/models/*hmm.mmf | while read mmf; do
    viterbi_decode $mmf &
  done
}

# show progress
show_progress() {
  local M=$(ls $DIR/models | grep -c "hmm.mmf")
  local testSet=$(cat $DIR/mfclist_tst | grep -c "")
  local total=$(( M*(testSet) ))
  local current=
  local progress=
  local progressBar=
  local dot="...................................................................................................."
  local refreshInterval=2

  # trick current progress counter
  touch $DIR/results/hvite_0.log
  while true; do
    sleep $refreshInterval
    current="$(cat $DIR/results/hvite_*.log | grep -c "^File:")"
    progress=$((current*100/total))

    progressBar="$dot ($progress%%)"
    if [ "$progress" -gt "0" ]; then
      progressBar=$(echo $progressBar | sed "s/./#/$progress"); fi
    printf "$progressBar\r"

    if [ "$progress" -eq "100" ]; then
      break; fi
  done
  rm $DIR/results/hvite_0.log

  echo
  echo "Done!"
  echo
}

# -----------------------------------
# decode.sh - decode with viterbi algorithm 
#             and generate hypothesis results
#
#   $1 : $DIR
# -----------------------------------

  setup $@
  recognize
  show_progress
