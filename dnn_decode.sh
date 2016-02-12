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
DIR=
HMMLIST=
MFCLIST=
MODELS_MMF=

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
  MODELS_MMF="$DIR/dnn/models.mmf"

  mkdir -p $DIR/dnn_results

  # stdout
  echo "$SCRIPT_NAME -> setup()"
  echo 
}

# viterbi_decode
viterbi_decode() {
  echo "$SCRIPT_NAME -> viterbi_decode()"
  echo "  \$models: $MODELS_MMF"
  echo

  # viterbi decoding
  HVite -A -D -V \
    -T 1 -l '*' -i $DIR/dnn_results/output.mlf \
    -C configs/hvite.conf -z zoo -q Atvaldmnr -s 2.4 -p -1.2 \
    -S $MFCLIST -H $MODELS_MMF -w lm/word_network.lat \
    dictionary/dictionary.dct $HMMLIST > $DIR/dnn_results/HVite_viterbi_decoding.log

  # generate result statistics
  HResults \
    -f -I labels/words.mlf /dev/null $DIR/dnn_results/output.mlf \
    > $DIR/dnn_results/result.log
}

# ------------------------------------
# dnn_decode.sh - decode dnn-hmm models
#
#   $1 : DIR
# ------------------------------------

  setup experiments/step_by_step # $@
  viterbi_decode
