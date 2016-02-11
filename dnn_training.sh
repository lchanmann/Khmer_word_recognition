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
DNN_TRAIN_ALIGNED_MLF=

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
  DNN_TRAIN_ALIGNED_MLF="$DIR/dnn/train.aligned.mlf"
  
  mkdir -p $DIR/dnn
  mkdir -p $DIR/cvn
  
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
    -T 1 -a -l '*' -I labels/words.mlf -i $DNN_TRAIN_ALIGNED_MLF \
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

# heldout_split
heldout_split() {
  echo "$SCRIPT_NAME -> heldout_split()"
  echo
  
  local vSpkr="$(bash ./random_speaker.sh --trn)"
  cat $MFCLIST | grep ${vSpkr} > $DIR/dnn_holdout.scp
  cat $MFCLIST | grep -v ${vSpkr} > $DIR/dnn_trn.scp
}

# make_basic_pretrain_conf
make_basic_pretrain_conf() {
  echo "$SCRIPT_NAME -> make_basic_pretrain_conf()"
  echo
  
  local targetKind="TARGETKIND = MFCC_0_D_A_Z"
  local varScaleDir="HPARM: VARSCALEDIR = $DIR/cvn"
  local varScaleMask="HPARM: VARSCALEMASK = '*.%%%'"
  local varScaleFn="HPARM: VARSCALEFN = models/ident_MFCC_0_D_A_Z_cvn"
  
  echo ${targetKind}   > $DIR/basic_pretrain.conf
  echo ${varScaleDir}  >> $DIR/basic_pretrain.conf
  echo ${varScaleMask} >> $DIR/basic_pretrain.conf
  echo ${varScaleFn}   >> $DIR/basic_pretrain.conf
}

# pretrain
pretrain() {
  echo "$SCRIPT_NAME -> pretrain()"
  echo "  HCompV: y"
  echo "  HNTrainSGD: y"
  echo
  
  # generate variable vector for unit variance normalization
  HCompV -A -D -V -T 3 \
    -k "*.%%%" -C configs/hcompv.conf \
    -q v -c $DIR/cvn \
    -S $MFCLIST > $DIR/dnn/hcompv_pretrain.log
  
  # discriminative pre-train to add new hidden layer gruadually
  HNTrainSGD -A -D -V \
    -T 1 -C $DIR/basic_pretrain.conf -C configs/dnn_pretrain.conf \
    -H $DIR/dnn/models.mmf -M $DIR/dnn \
    -S $DIR/dnn_trn.scp -N $DIR/dnn_holdout.scp \
    -l LABEL -I $DNN_TRAIN_ALIGNED_MLF \
    $HMMLIST > $DIR/dnn/hntrainsgd_pretrain.log
}

# ------------------------------------
# dnn.sh - train dnn-hmm models
#
#   $1 : DIR
# ------------------------------------

  setup experiments/step_by_step # $@
  state2frame_align
  dnn_init
  heldout_split
  make_basic_pretrain_conf
  pretrain
  