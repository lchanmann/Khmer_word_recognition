#!/bin/bash

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
  DNN_MODELS_MMF="$DIR/dnn/models.mmf"
  DNN_TRAIN_ALIGNED_MLF="$DIR/dnn/train.aligned.mlf"
  DNN_CONNECT_HED="$DIR/dnn/connect.hed"
  DNN_HOLDOUT_SCP="$DIR/dnn/holdout.scp"
  DNN_TRAINING_SCP="$DIR/dnn/training.scp"
  DNN_CVN="$DIR/dnn/cvn"
  DNN_BASIC_CONF="$DIR/dnn/basic.conf"
  DNN_HIDDEN_NODES=1024

  mkdir -p $DIR/dnn
  mkdir -p $DNN_CVN
  
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
  
  # viterbi alignment
  HVite -A -D -V \
    -T 1 -a -l '*' -I labels/words.mlf -i $DNN_TRAIN_ALIGNED_MLF \
    -C configs/hvite.conf -f -o MW -b SIL -y lab \
    -S $MFCLIST -H $MODELS_MMF \
    dictionary/dictionary.dct.withsil $HMMLIST \
    > $DIR/dnn/HVite_state2frame_align.log
}

# holdout_split
holdout_split() {
  echo "$SCRIPT_NAME -> holdout_split()"
  echo
  
  local vSpkr="$(bash ./random_speaker.sh --trn)"
  cat $MFCLIST | grep ${vSpkr} > $DNN_HOLDOUT_SCP
  cat $MFCLIST | grep -v ${vSpkr} > $DNN_TRAINING_SCP
}

# __make_connect_hed
__make_connect_hed() {
  local N_Macro="$(cat $DNN_PROTO | grep '~N')"
  
  echo "CH $DNN_PROTO models/empty $N_Macro <HYBRID>"
  echo "SW 1 39"
  echo "SK MFCC_0_D_A_Z"
  cat $DNN_PROTO | grep '~L' | sort -u | sed "s/^/EL /"
  echo
}

# __make_basic_conf
__make_basic_conf() {
  echo "TARGETKIND = MFCC_0_D_A_Z"
  echo "HPARM: VARSCALEDIR = $DNN_CVN"
  echo "HPARM: VARSCALEMASK = '*.%%%'"
  echo "HPARM: VARSCALEFN = models/ident_MFCC_0_D_A_Z_cvn"
}

# __SGD_training - Stochastic Gradient Descent training
__SGD_training() {
  local callerFuncName="$(caller 0 | grep -o " .* " | sed "s/ //g")"
  local isConverged=0
  local i=0
  
  printf "  SGD training."
  while [ "$isConverged" -eq "0" ]; do
    HNTrainSGD -A -D -V -T 1 \
      -c -C $DNN_BASIC_CONF -C configs/dnn_pretrain.conf \
      -H $DNN_MODELS_MMF -M $DIR/dnn \
      -S $DNN_TRAINING_SCP -N $DNN_HOLDOUT_SCP \
      -l LABEL -I $DNN_TRAIN_ALIGNED_MLF \
      $HMMLIST > $DIR/dnn/HNTrainSGD_${callerFuncName}.log
    
    i=$(( i+1 ))
    # check for convergence
    isConverged="$(cat $DIR/dnn/HNTrainSGD_pretrain.log \
      | grep "Validation Accuracy" \
      | grep -o "[0-9]*\.[0-9]*%" \
      | perl -p -e "s/%\n/ - /;" \
      | perl -p -e "s/ - $/ >= 0\n/" | bc)"
    printf "."
  done
  
  echo "  : converged at $i iteration(s)."
  echo
}

# construct dnn hmm model
dnn_init() {
  echo "$SCRIPT_NAME -> dnn_init()"
  echo "  HHEd: y"
  echo "  write: $DNN_PROTO"
  echo "  write: $DNN_CONNECT_HED"
  echo
  
  # intialize 3 layer dnn prototype model
  python python/GenInitDNN.py --quiet \
    hte_files/dnn3.hte $DNN_PROTO
  
  # make connect.hed and basic.conf
  __make_connect_hed > $DNN_CONNECT_HED
  
  # associate DNN and HMM
  HHEd -A -D -V \
    -T 1 -H $MODELS_MMF -M $DIR/dnn \
    $DNN_CONNECT_HED $HMMLIST \
    > $DIR/dnn/HHEd_dnn_init.log
}

# __make_addlayer_hed
__make_addlayer_hed() {
  local level="$1"
  local prevLevel=$(( level-1 ))
  local numOfNodes="$2"
  local thisLayerWeight="layer${level}_weight"
  local thisLayerFeature="layer${level}_feamix"
  local thisLayerBias="layer${level}_bias"
  local lastLayerFeature="layer${prevLevel}_feamix"
  local lastLayerNodes="$( \
    cat $DNN_MODELS_MMF \
    | grep -B 1 "<FEATURE>" \
    | grep -A 1 "layer${prevLevel}" \
    | grep -o " [0-9]*$")"
  local N_Macro="$(cat $DNN_PROTO | grep '~N')"
  local activation="SIGMOID"
  
  # CD ~L "layerout" 0 $numOfNodes
  cat <<_EOF_
AM ~M "$thisLayerWeight" <MATRIX> $numOfNodes $lastLayerNodes
AV ~V "$thisLayerBias" <VECTOR> $numOfNodes
IL $N_Macro $level ~L "layer${level}" <BEGINLAYER> <LAYERKIND> "PERCEPTRON" \
  <INPUTFEATURE> ~F "$lastLayerFeature" <WEIGHT> ~M "$thisLayerWeight" \
  <BIAS> ~V "$thisLayerBias" <ACTIVATION> "$activation" <ENDLAYER>
AF ~F "$thisLayerFeature" <NUMFEATURES> 1 $numOfNodes <FEATURE> 1 $numOfNodes \
  <SOURCE> ~L "layer${level}" <CONTEXTSHIFT> 1 0
CF ~L "layerout" ~F "$thisLayerFeature"
EL ~L "layer${level}"
EL ~L "layerout"
_EOF_
}

# __read_numlayers
__read_numlayers() {
  cat $DNN_MODELS_MMF \
    | grep "<NUMLAYERS>" \
    | grep -o "[0-9]*$"
}

# add_hidden_layer
add_hidden_layer() {
  echo "$SCRIPT_NAME -> add_hidden_layer()"
  echo "  # hidden nodes: $1"
  echo
  
  local numOfNodes="$1"
  local layers="$(__read_numlayers)"
  
  # make addlayer_?.hed
  __make_addlayer_hed $((layers ++)) $numOfNodes > $DIR/dnn/addlayer_${layers}.hed
  
  # add new layer macro to models
  HHEd -A -D -V \
    -T 1 -H $DNN_MODELS_MMF -M $DIR/dnn \
    $DIR/dnn/addlayer_${layers}.hed $HMMLIST \
    > $DIR/dnn/HHEd_add_hidden_layer${layers}.log
  
  # re-train dnn after adding a new hidden layer
  __SGD_training
}

# pretrain
pretrain() {
  echo "$SCRIPT_NAME -> pretrain()"
  echo
  
  # make basic.conf
  __make_basic_conf > $DNN_BASIC_CONF
  
  # compute global variance for unit variance normalization
  HCompV -A -D -V -T 3 \
    -k "*.%%%" -C configs/hcompv.conf \
    -q v -c $DNN_CVN \
    -S $MFCLIST > $DIR/dnn/HCompV_pretrain.log
  
  # training dnn-hmm models
  __SGD_training
  
  # # add 2 hidden layers to dnn models
  # add_hidden_layer $DNN_HIDDEN_NODES
  # add_hidden_layer $DNN_HIDDEN_NODES

  # save dnn models
  cp $DNN_MODELS_MMF $DIR/dnn/dnn$(__read_numlayers)_hmm.mmf
}

# context_independent_init
context_independent_init() {
  echo "$SCRIPT_NAME -> context_independent_init()"
  echo "  HHEd: y"
  echo
  
  # monophone dnn -> triphone dnn
  HHEd -A -D -V \
    -T 1 -H $DNN_MODELS_MMF -M $DIR/dnn \
    configs/context_independent_init.hed $HMMLIST \
    > $DIR/dnn/HHEd_context_independent_init.log
}

# finetune
finetune() {
  echo "$SCRIPT_NAME -> finetune()"
  echo "  HNTrainSGD: y"
  echo
  
  # fine tune dnn models
  HNTrainSGD -A -D -V \
    -T 1 -C $DNN_BASIC_CONF -C configs/dnn_finetune.conf \
    -H $DNN_MODELS_MMF -M $DIR/dnn \
    -S $DNN_TRAINING_SCP -N $DNN_HOLDOUT_SCP \
    -l LABEL -I $DNN_TRAIN_ALIGNED_MLF \
    $HMMLIST > $DIR/dnn/HNTrainSGD_finetune.log
}

# ------------------------------------
# dnn_trainning.sh - train dnn-hmm models
#
#   $1 : DIR
# ------------------------------------

  setup experiments/step_by_step # $@
  # state2frame_align
  # holdout_split
  # dnn_init
  # pretrain
  # context_independent_init
  finetune