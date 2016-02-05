#!/bin/sh

# -----------------------------------
# Project   : Khmer_word_recognition
# Author    : Chanmann Lim
#
# Changelogs:
#   - 01/29/2016  : refactoring.
# -----------------------------------

# exit on error
set -e

# E_VARS
E_USAGE="Usage: $0 \$directory"
# E_FILES_NOT_FOUND="Error: Required files could not be found."

# global variables
SCRIPT_NAME=$0
DIR=
MFCLIST=
HMMLIST=
PHONEME_MLF=
PHONEME_WITH_ALIGNMENT_MLF=
MODELS_MMF=

# show usage
show_usage() {
  echo $E_USAGE >&2
}

# setup
setup() {
  bash ./args_check.sh 1 $@ || (show_usage && exit 1)
  DIR=$1
  MFCLIST="$DIR/mfclist_trn"
  HMMLIST="$DIR/hmmlist"
  PHONEME_MLF="$DIR/phoneme.mlf"
  PHONEME_WITH_ALIGNMENT_MLF="$DIR/phoneme_with_alignment.mlf"
  MODELS_MMF="$DIR/models/models.mmf"

  mkdir -p $DIR/models

  # stdout
  echo "$SCRIPT_NAME -> setup()"
  echo
}

# flat-start
flat_start() {
  echo "$SCRIPT_NAME -> flat_start()"
  echo "  HCompV: y"
  echo "  HERest: 3x"
  echo

  # flat-start initialization
  HCompV \
    -T 1 -M $DIR/models \
    -C configs/hcompv.conf -m \
    -S $MFCLIST models/proto > $DIR/models/hcompv.log

   # initialize each hmm with the global estimated mean and variance in HMM macro file
  head -n 3 $DIR/models/proto > $MODELS_MMF
  for phone in $(cat $HMMLIST); do
    tail -n 28 $DIR/models/proto \
      | sed -e 's/~h \"proto\"/~h \"'$phone'\"/g' >> $MODELS_MMF
  done

  # Baum-Welch parameter re-estimation for 3 iterations
  HERest \
    -T 1 -H $MODELS_MMF \
    -C configs/herest.conf -w 1 -t 240.0 120.0 1920.0 \
    -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
    > $DIR/models/herest_hmm.log

  HERest \
    -T 1 -H $MODELS_MMF \
    -C configs/herest.conf -w 1 -t 180.0 90.0 1440.0 \
    -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
    > $DIR/models/herest_hmm.log

  HERest \
    -T 1 -H $MODELS_MMF \
    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
    -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
    > $DIR/models/herest_hmm.log
}

# fix sil model
fix_sil() {
  echo "$SCRIPT_NAME -> fix_sil()"
  echo "  HHEd: y"
  echo "  HERest: 2x"
  echo

  # update HMM parameters to fix silence model
  HHEd \
    -T 1 -H $MODELS_MMF -M $DIR/models \
    ed_files/fix_sil.hed $HMMLIST \
    > $DIR/models/hhed_hmm.log

  # 2x parameter re-estimation right after fixing silence model
  HERest \
    -T 1 -H $MODELS_MMF \
    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
    -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
    > $DIR/models/herest_hmm.log

  HERest \
    -T 1 -H $MODELS_MMF \
    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
    -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
    > $DIR/models/herest_hmm.log
}

# viterbi alignment
viterbi_align() {
  echo "$SCRIPT_NAME -> viterbi_align()"
  echo "  HVite: y"
  echo "  HERest: 2x"
  echo

  # viterbi alignment
  HVite \
    -T 1 -a -l '*' -I labels/words.mlf -i $PHONEME_WITH_ALIGNMENT_MLF \
    -C configs/hvite.conf -m -b SIL -o SW -y lab \
    -S $MFCLIST -H $MODELS_MMF \
    dictionary/dictionary.dct.withsil $HMMLIST \
    > $DIR/models/hvite_hmm.log

  # 2x parameter re-estimation right after viterbi alignment
  HERest \
    -T 1 -H $MODELS_MMF \
    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
    -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
    > $DIR/models/herest_hmm.log
  
  HERest \
    -T 1 -H $MODELS_MMF \
    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
    -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
    > $DIR/models/herest_hmm.log
}
 
# ------------------------------------
# init.sh - HMM flat start initialization 
#
#   $1 : MFCLIST
# ------------------------------------

  setup $@
  flat_start
  fix_sil
  viterbi_align
