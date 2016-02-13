#!/bin/sh

# -----------------------------------
# Project   : Khmer_word_recognition
# Author    : Chanmann Lim
#
# Changelogs:
#   - 02/12/2016  : file created.
# -----------------------------------

# exit on error
set -e

# E_VARS
E_USAGE="Usage: $0 \$directory"

# global variables
SCRIPT_NAME=$0

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
  DNN_MODELS_MMF="$DIR/dnn/models.mmf"
  DNN_RESULTS="$DIR/dnn/results"

  mkdir -p $DNN_RESULTS

  # stdout
  echo "$SCRIPT_NAME -> setup()"
  echo 
}

# viterbi_decode
viterbi_decode() {
  echo "$SCRIPT_NAME -> viterbi_decode()"
  echo "  \$models: $DNN_MODELS_MMF"
  echo

  # viterbi decoding
  HVite -A -D -V \
    -T 5 -l '*' -i $DNN_RESULTS/output.mlf \
    -C configs/hvite.conf -z zoo -q Atvaldmnr -s 2.4 -p -1.2 \
    -S $MFCLIST -H $DNN_MODELS_MMF -w lm/word_network.lat \
    dictionary/dictionary.dct $HMMLIST > $DNN_RESULTS/HVite_viterbi_decoding.log

  # generate result statistics
  HResults \
    -f -I labels/words.mlf /dev/null $DNN_RESULTS/output.mlf \
    > $DNN_RESULTS/result.log
}

# ------------------------------------
# dnn_decode.sh - decode dnn-hmm models
#
#   $1 : DIR
# ------------------------------------

  setup experiments/step_by_step # $@
  viterbi_decode
