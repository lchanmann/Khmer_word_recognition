#!/bin/sh

# -----------------------------------
# Project   : Khmer_word_recognition
# Author    : Chanmann Lim
#
# Changelogs:
#   - 02/10/2016  : file created.
# -----------------------------------

# exit on error
set -e

# E_VARS
E_USAGE="Usage: $0 \$directory"

# global variables
SCRIPT_NAME=$0
DIR=
MFCLIST=
MODELS_MMF=
HMMLIST=
DNN_PROTO=
CONNECT_HED=

# show usage
show_usage() {
  echo $E_USAGE >&2
}

# setup
setup() {
  bash ./args_check.sh 1 $@ || (show_usage && exit 1)
  DIR=$1
  MFCLIST="$DIR/mfclist_trn"
  MODELS_MMF="$DIR/models/models.mmf"
  HMMLIST="$DIR/hmmlist"
  DNN_PROTO="$DIR/dnn/proto"
  CONNECT_HED="$DIR/dnn/connect.hed"
  
  mkdir -p $DIR/dnn
  
  # stdout
  echo "$SCRIPT_NAME -> setup()"
  echo "  DIR: $DIR"
  echo
}

# state-to-frame alignment
state2frame_align() {
  echo "$SCRIPT_NAME -> state2frame_align()"
  echo "  HVite: y"
  echo
  
  # viterbi alignment # -m -b SIL -o SW -y lab \
  HVite -A -D -V \
    -T 1 -a -l '*' -I labels/words.mlf -i $DIR/dnn/train.aligned.mmf \
    -C configs/hvite.conf -f -o MW -b SIL -y lab \
    -S $MFCLIST -H $MODELS_MMF \
    dictionary/dictionary.dct.withsil $HMMLIST \
    > $DIR/dnn/hvite_state2frame_align.log
}

# construct dnn prototype model
dnn_init() {
  echo "$SCRIPT_NAME -> dnn_init()"
  echo "  HHEd: y"
  echo "  write: $DNN_PROTO"
  echo "  write: $DIR/connect.hed"
  echo
  
  # intialize dnn proto model
  python python/GenInitDNN.py --quiet \
    hte_files/dnn.hte $DNN_PROTO
  
  # make_connect_hed
  bash ./make_connect_hed.sh $DNN_PROTO
  
  # associate DNN and HMM
  HHEd -A -D -V \
    -T 1 -H $MODELS_MMF -M $DIR/dnn \
    $CONNECT_HED $HMMLIST \
    > $DIR/dnn/hhed_dnn_init.log
}

# pretrain
pretrain() {
  echo "$SCRIPT_NAME -> pretrain()"
  echo
  
  # generate variable vector for unit variance normalization
  HCompV \
    -k "*.%%%" -C configs/hcompv.conf \
    -q v -c $DIR \
    -S $MFCLIST
  mv $DIR/mfc $DIR/dnn/variance
}

# ------------------------------------
# dnn.sh - train dnn-hmm models
#
#   $1 : DIR
# ------------------------------------

  setup experiments/step_by_step # $@
  state2frame_align
  dnn_init
  pretrain
  