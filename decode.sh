#!/bin/bash

# -----------------------------------
# Project   : Khmer_word_recognition
# Author    : Chanmann Lim
#
# Changelogs:
#   - 01/31/2016  : refactoring.
# -----------------------------------

# exit on error
set -e

# include
source ./process_queue.sh

# E_VARS
E_USAGE="Usage: $0 \$directory"

# global variables
SCRIPT_NAME=$0
PID="$$"

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

  # setup queue
  set_queue_DB $DIR/results/HVite.queue
  set_max_queue 4

  # stdout
  echo "$SCRIPT_NAME -> setup()"
  echo
}

# viterbi decoding
viterbi_decode() {
  echo "$SCRIPT_NAME -> viterbi_decode()"
  echo "  \$models: $1"
  echo "  \$hmmlist: $2"
  echo

  local models="$1"
  local hmmlist="$2"
  local model_name=$(basename $models | sed "s/.mmf$//")
  local hvite_log="$DIR/results/hvite_${model_name}.$PID"

  # viterbi decoding
  # NOTE: when copy HVite command directly into terminal '*' must be quoted.
  HVite -A -D -V \
    -T 1 -l '*' -i $DIR/results/output_${model_name}.mlf \
    -C $DIR/configs/hvite_decode.conf -q Atvaldmnr -s 2.4 -p -1.2 \
    -S $MFCLIST -H $models -w lm/word_network.lat \
    dictionary/dictionary.dct "$hmmlist" > $hvite_log

  # generate result statistics
  HResults \
    -f -I labels/words.mlf /dev/null $DIR/results/output_${model_name}.mlf \
    > $DIR/results/result_${model_name}.log
}

# recognize
recognize() {
  local mmf=
  local hmmlist=

  while read line; do
    mmf="$(echo $line | sed "s/:.*//")"
    hmmlist="$(echo $line | sed "s/.*://")"

    run_in_queue viterbi_decode "$mmf" "$hmmlist"
  done < $DIR/models/MODELS

  # small delay to let HVite processes kickoff
  sleep 5
}

# show progress
show_progress() {
  local M=$(grep -c "" $DIR/models/MODELS)
  local testSet=$(grep -c "" $DIR/mfclist_tst)
  local total=$(( M*testSet ))
  local current=
  local progress=
  local progressBar=
  local dot="...................................................................................................."
  local refreshInterval=2

  while true; do
    current="$(cat $DIR/results/hvite_*.$PID | grep -c "^File:")"
    progress=$((current*100/total))

    progressBar="$dot ($progress%%)"
    if [ "$progress" -gt "0" ]; then
      progressBar=$(echo $progressBar | sed "s/./#/$progress"); fi
    printf "$progressBar\r"

    if [ "$progress" -eq "100" ]; then
      break; fi

    sleep $refreshInterval
  done

  # rename hvite log
  rename -f "s/$PID$/log/" $DIR/results/hvite_*.$PID

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
