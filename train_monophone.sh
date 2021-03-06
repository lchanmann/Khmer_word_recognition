#!/bin/sh

# -----------------------------------
# Project   : Khmer_word_recognition
# Author    : Chanmann Lim
#
# Changelogs:
#   - 01/30/2016  : refactoring.
# -----------------------------------

# exit on error
set -e

# E_VARS
E_USAGE="Usage: $0 \$mfclist_trn"

# global variables
SCRIPT_NAME=$0
MFCLIST=
DIR=
MIXTURES=16

# show usage
show_usage() {
  echo $E_USAGE >&2
}

# setup
setup() {
  bash ./args_check.sh 1 $@ || (show_usage && exit 1)
  MFCLIST=$1
  DIR=$(dirname $1)
  HMMLIST="$DIR/hmmlist"
  

  # stdout
  echo "$SCRIPT_NAME -> setup()"
  echo "  MFCLIST: $MFCLIST"
  echo "  DIR: $DIR"
  echo
}

# make phoneme.mlf
make_phoneme_mlf() {
  echo "$SCRIPT_NAME -> make_phoneme_mlf()"
  echo "  deps:"
  echo "    - dictionary/dictionary.dct"
  echo "    - ed_files/mkphn.led"
  echo "    - labels/words.mlf"
  echo "  writeTo: $DIR/phoneme.mlf"
  echo

  # word -> phoneme level label generation
  HLEd -A -D -V -T 1 -l '*/' \
    -i $DIR/phoneme.mlf \
    -d dictionary/dictionary.dct \
    ed_files/mkphn.led labels/words.mlf > $DIR/hled_make_phoneme.log
}

# make hmmlist
make_hmmlist() {
  echo "$SCRIPT_NAME -> make_hmmlist()"
  echo "  deps:"
  echo "    - $DIR/phoneme.mlf"
  echo "  output: $DIR/hmmlist"
  echo

  # phone set generation
  cat $DIR/phoneme.mlf \
    | grep '^[a-z]' \
    | sort -u > $DIR/hmmlist
}

# initialize models
initialize() {
  echo "$SCRIPT_NAME -> initialize()"
  echo "  deps:"
  echo "    - init.sh"
  echo "    - $DIR"
  echo "  output: $DIR/models/models.mmf"
  echo
  
  bash ./init.sh $DIR
}

# save_gmm_1_models
save_gmm_1_models() {
  echo "$SCRIPT_NAME -> save_gmm_1_models()"
  echo
  
  local model="$DIR/models/gmm_1_hmm.mmf"
  
  # save gmm model
  cp $DIR/models/models.mmf $model
  
  # add gmm_model to MODELS list
  echo "$model:$HMMLIST" >> $DIR/models/MODELS
}

# tune with mixture models
models_tuning() {
  echo "$SCRIPT_NAME -> models_tuning()"
  echo "  deps:"
  echo "    - increase_mixture.sh"
  echo "    - $DIR"
  echo "  output: $DIR/models/models.mmf"
  echo
  
  bash ./increase_mixture.sh $MIXTURES "$DIR"
}

# ------------------------------------
# train_monophone.sh - train monophone models
#
#   $1 : MFCLIST
# ------------------------------------

  setup $@
  make_phoneme_mlf
  make_hmmlist
  initialize
  save_gmm_1_models
  models_tuning
