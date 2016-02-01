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
E_USAGE="Usage: $0 \$mixtures \$directory"

# check for required argument
if [ "$#" -ne "2" ]; then
  echo $E_USAGE >&2
  exit 1
fi

# global variables
SCRIPT_NAME=$0
DIR=
MFCLIST=
HMMLIST=
PHONEME_MLF=
MODELS_MMF=
MIXTURES=

# setup
setup() {
  MIXTURES=$1
  DIR=$2
  MFCLIST="$DIR/mfclist_trn"
  HMMLIST="$DIR/hmmlist"
  PHONEME_MLF="$DIR/phoneme.mlf"
  MODELS_MMF="$DIR/models/models.mmf"

  # stdout
  echo "$SCRIPT_NAME -> setup()"
  echo 
}

# viterbi alignment for mixture model
viterbi_align() {
  local num=$1

  echo "$SCRIPT_NAME -> viterbi_align()"
  echo "  HVite: y"
  echo "  HERest: 2x"
  echo

  HVite \
    -T 1 -a -l '*' -I labels/words.mlf -i $DIR/phoneme_with_alignment.mlf \
    -C configs/hvite.conf -m -b SIL -o SW -y lab \
    -S $MFCLIST -H $MODELS_MMF \
    dictionary/dictionary.dct.withsil $HMMLIST \
    > $DIR/models/hvite_gmm_${num}_hmm.log

  # 2x parameter re-estimation right after viterbi alignment
  HERest \
    -T 1 -H $MODELS_MMF \
    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
    -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
    > $DIR/models/herest_gmm_${num}_hmm.log
  HERest \
    -T 1 -H $MODELS_MMF \
    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
    -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
    > $DIR/models/herest_gmm_${num}_hmm.log
  
  cp $MODELS_MMF $DIR/models/gmm_${num}_hmm.mmf
}

# make mixtures
make_mixtures() {
  echo "$SCRIPT_NAME -> make_mixtures()"
  echo "  HHEd: y"
  echo "  HERest: 2x"
  echo

  for num in $(seq 2 2 $MIXTURES);do
    echo "Mixtures: $num"
    echo "MU $num {*.state[2-4].mix}" > $DIR/mixture.hed
    HHEd \
      -T 1 -H $MODELS_MMF \
      $DIR/mixture.hed $HMMLIST \
      > $DIR/models/hhed_gmm_${num}_hmm.log

    # 2x parameter re-estimation after increasing mixtures
    HERest \
      -T 1 -H $MODELS_MMF \
      -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
      -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
      > $DIR/models/herest_gmm_${num}_hmm.log
    HERest \
      -T 1 -H $MODELS_MMF \
      -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
      -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
      > $DIR/models/herest_gmm_${num}_hmm.log

    # 2x viterbi alignment
    viterbi_align $num
    viterbi_align $num
  done
  echo
}

# -----------------------------------
# increase_mixture.sh - Increase mixture components 
#
#   $1 : MFCLIST
# -----------------------------------

  setup $@
  make_mixtures