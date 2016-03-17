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

# include
source ./process_queue.sh

# E_VARS
E_USAGE="Usage: $0 \$directory \$dnnHiddenNodes"
E_STAGE_REQUIRED="STAGE is required"

# global variables
SCRIPT_NAME=$0
DNN_HIDDEN_ACTIVATION="SIGMOID"
# EXPERIMENTAL: SGD pre-train for 1 epoch only
PRETRAIN_ITERATION=1

# show usage
show_usage() {
  echo $E_USAGE >&2
}

# setup
setup() {
  bash ./args_check.sh 2 $@ || (show_usage && exit 1)
  DIR=$1
  DNN_HIDDEN_NODES="$2"
  MFCLIST="$DIR/mfclist_trn"
  MODELS_MMF="$DIR/models/models.mmf"
  MONOPHONE_MMF="$DIR/models/monophone.mmf"
  TRIPHONE_MMF="$DIR/models/triphone.mmf"
  HMMLIST="$DIR/hmmlist"
  MONOLIST="$DIR/monolist"
  TIEDLIST="$DIR/tiedlist"
  DNN_PROTO="$DIR/dnn/proto"
  DNN_INIT_MMF="$DIR/dnn/init.mmf"
  DNN_MODELS_MMF="$DIR/dnn/models.mmf"
  __BEFORE_CONVERGED_MMF="$DIR/dnn/__before_converged.mmf"
  DNN_TRAIN_ALIGNED_MLF="$DIR/dnn/train.aligned.mlf"
  DNN_CONNECT_HED="$DIR/dnn/connect.hed"
  DNN_HOLDOUT_SCP="$DIR/dnn/holdout.scp"
  DNN_TRAINING_SCP="$DIR/dnn/training.scp"
  DNN_CVN="$DIR/dnn/cvn"
  DNN_BASIC_CONF="$DIR/dnn/basic.conf"
  DNN_HNTrainSGD="$DIR/dnn/HNTrainSGD"
  DNN_HTE="$DIR/dnn/HTE"
  DNN_COPY_HED="$DIR/dnn/copy.hed"
  DNN_EB_="$DIR/dnn/EB_"
  DNN_PRETRAIN="$DIR/dnn/PRETRAIN"
  DNN_TRIPHONE_PRETRAIN="$DIR/dnn/TRIPHONE_PRETRAIN"

  mkdir -p $DIR/dnn
  mkdir -p $DNN_CVN
  mkdir -p $DNN_HNTrainSGD
  
  # setup queue database
  set_queue_DB $DNN_HNTrainSGD.queue
  
  # reset decoding models list
  cat /dev/null > "$DIR/models/MODELS"
  
  # stdout
  echo "$SCRIPT_NAME -> setup()"
  echo "  DIR: $DIR"
  echo
}

# __make_hte
__make_hte() {
  cat <<_EOF_
#----------------------------#
# HTK Environment File       #
#----------------------------#

# DNN definition variables
set FEATURETYPE=MFCC_0_D_A_Z
set FEATUREDIM=39
set CONTEXTSHIFT=-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7  # Input feature context shift
set DNNSTRUCTURE=585X${DNN_HIDDEN_NODES}X180  # 3-layer MLP structure (585 = 39 * 13), BN dim = 39
set HIDDENACTIVATION=${DNN_HIDDEN_ACTIVATION}  # Hidden layer activation function
set OUTPUTACTIVATION=SOFTMAX  # Softmax output activation function
_EOF_
}

# __make_connect_hed
__make_connect_hed() {
  local N_Macro="$(grep '~N' $DNN_PROTO)"
  
  echo "CH $DNN_PROTO /dev/null $N_Macro <HYBRID>"
  echo "SW 1 39"
  echo "SK MFCC_0_D_A_Z"
  grep '~L' $DNN_PROTO | sort -u | sed "s/^/EL /"
}

# __make_basic_conf
__make_basic_conf() {
  echo "TARGETKIND = MFCC_0_D_A_Z"
  echo "HPARM: VARSCALEDIR = $DNN_CVN"
  echo "HPARM: VARSCALEMASK = '*.%%%'"
  echo "HPARM: VARSCALEFN = models/ident_MFCC_0_D_A_Z_cvn"
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
    grep -B 1 "<FEATURE>" $DNN_MODELS_MMF \
    | grep -A 1 "layer${prevLevel}" \
    | grep -o " [0-9]*$")"
  local N_Macro="$(grep '~N' $DNN_MODELS_MMF)"
  
  cat <<_EOF_
AM ~M "$thisLayerWeight" <MATRIX> $numOfNodes $lastLayerNodes
AV ~V "$thisLayerBias" <VECTOR> $numOfNodes
IL $N_Macro $level ~L "layer${level}" <BEGINLAYER> <LAYERKIND> "PERCEPTRON" \
  <INPUTFEATURE> ~F "$lastLayerFeature" <WEIGHT> ~M "$thisLayerWeight" \
  <BIAS> ~V "$thisLayerBias" <ACTIVATION> "$DNN_HIDDEN_ACTIVATION" <ENDLAYER>
AF ~F "$thisLayerFeature" <NUMFEATURES> 1 $numOfNodes <FEATURE> 1 $numOfNodes \
  <SOURCE> ~L "layer${level}" <CONTEXTSHIFT> 1 0
CF ~L "layerout" ~F "$thisLayerFeature"
CD ~L "layerout" 0 $numOfNodes
EL ~L "layer${level}"
EL ~L "layerout"
_EOF_
}

# __read_numlayers
__read_numlayers() {
    grep "<NUMLAYERS>" $DNN_MODELS_MMF \
    | grep -o "[0-9]*$"
}

# __SGD_training - Stochastic Gradient Descent training
__SGD_training() {
  if [ -z $STAGE ]; then echo $E_STAGE_REQUIRED >&2; exit 1; fi

  local isConverged=0
  local i=0
  local j=0
  local logFile="$DNN_HNTrainSGD/${STAGE}_train"
  local fileList="${DNN_HNTrainSGD}_${STAGE}"
  local pretrainedModels="$DIR/dnn/${STAGE}_pretrain.mmf"
  
  printf "  SGD training."
  cat /dev/null > $fileList
  while true; do
    j=$i
    i=$(( i+1 ))
    
    # models backup before traning
    cp $DNN_MODELS_MMF $__BEFORE_CONVERGED_MMF
    HNTrainSGD -A -D -T 1 \
      -C $DNN_BASIC_CONF -C configs/dnn_pretrain.conf \
      -H $DNN_MODELS_MMF -M $DIR/dnn \
      -S $DNN_TRAINING_SCP -N $DNN_HOLDOUT_SCP \
      -l LABEL -I $DNN_TRAIN_ALIGNED_MLF \
      $HMMLIST > $logFile.$i.log
    printf "."
    
    # check for max iteration
    if [ -n "$PRETRAIN_ITERATION" ]; then
      if [ "$i" -ge "$PRETRAIN_ITERATION" ]; then
        # add last iteration of log file to list
        echo $logFile.$i.log >> $fileList
        break;
      fi
    fi
    
    # check for convergence
    if [ "$i" -gt "1" ]; then
      isConverged="$(cat $logFile.{$j,$i}.log \
        | grep "Validation Accuracy" \
        | sed "s/^.* = \([0-9]*\.[0-9]*\).*/\1/" \
        | perl -p -e "s/\n/ - /;" \
        | perl -p -e "s/ - $/ > 0\n/" | bc)"
    
      if [ "$isConverged" -eq "1" ]; then
        # use dnn models before training converged
        mv "$__BEFORE_CONVERGED_MMF" "$DNN_MODELS_MMF"
        break;
      fi
    fi

    echo $logFile.$i.log >> $fileList
  done
  
  echo "  : stopped at $i iteration(s)."
  echo
  
  # save as pretrain models
  cp $DNN_MODELS_MMF $pretrainedModels
  
  # add to PRETRAIN
  echo $pretrainedModels >> $DNN_PRETRAIN
  
  # to add pretrain models for evaluation uncomment below line
  # echo "$pretrainedModels:$(readlink $HMMLIST)" >> "$DIR/models/MODELS"
}

# __SGD_finetune
__SGD_finetune() {
  local prefix_=
  if [ -n "$TRIPHONE" ]; then prefix_="triphone_"; fi
  
  local layers="$1"
  local models="$2"
  local logFile="${DNN_HNTrainSGD}/${prefix_}dnn${layers}_finetune.log"
  local ebDir="${DNN_EB_}${prefix_}dnn${layers}"
  local hmmlist="$(readlink $HMMLIST)"
  
  # make epoch base dir
  mkdir -p $ebDir
  
  HNTrainSGD -A -D -T 1 \
    -eb $ebDir \
    -C $DNN_BASIC_CONF -C configs/dnn_finetune.conf \
    -H $models -M $DIR/models \
    -S $DNN_TRAINING_SCP -N $DNN_HOLDOUT_SCP \
    -l LABEL -I $DNN_TRAIN_ALIGNED_MLF \
    "$hmmlist" > $logFile

  if [ -z $TRIPHONE ]; then
    echo $logFile >> "${DNN_HNTrainSGD}_dnn${layers}"
  fi

  # remove intermediate epoch
  rm -rf "$ebDir"

  # add dnn fine-tuned models to MODELS list
  echo "$models:$hmmlist" >> $DIR/models/MODELS
}

# state-to-frame alignment
__state2frame_align() { 
  # viterbi force alignment
  HVite -A -D \
    -T 1 -a -l '*' -I labels/words.mlf -i $DNN_TRAIN_ALIGNED_MLF \
    -C configs/hvite.conf -f -o MW -b SIL -y lab \
    -S $MFCLIST -H $MODELS_MMF \
    dictionary/dictionary.dct.withsil $HMMLIST \
    > $DIR/dnn/HVite_state2frame_align.log
}

# __make_copy_hed
__make_copy_hed() {
  local swapModels="$1"
  local numLayers="$2"
  
  for i in $(seq 2 1 $(( numLayers-1 ))); do
    echo "CP <HMMSET> $swapModels $DIR/monolist \
             <UPDATEFLAG> abw \
             <SOURCEMACRO> ~L \"layer$i\" \
             <TARGETMACRO> ~L \"layer$i\""
  done
}

# __copy_dnn_pretrain_params
__copy_dnn_pretrain_params() {
  local pretrainedModels="$1"
  local numLayers="$2"
  local newModels=$(basename $pretrainedModels | sed "s/^/triphone_/")
  
  # make copy.hed
  __make_copy_hed "$pretrainedModels" $numLayers > $DNN_COPY_HED
  
  # copy monophone dnn parameters -> triphone dnn
  HHEd -A -D \
    -T 1 -H $DNN_MODELS_MMF -M $DIR/dnn \
    $DNN_COPY_HED $HMMLIST \
    > $DIR/dnn/HHEd_copy_hed.log
  cp $DNN_MODELS_MMF "$DIR/dnn/$newModels"
  
  # add to TRIPHONE_PRETRAIN
  echo $DIR/dnn/$newModels >> $DNN_TRIPHONE_PRETRAIN
}

# construct dnn hmm monophone models
dnn_init() {
  echo "$SCRIPT_NAME -> dnn_init()"
  echo "  HHEd: y"
  echo "  write: $DNN_PROTO"
  echo "  write: $DNN_CONNECT_HED"
  echo
  
  # make HTE file
  __make_hte > $DNN_HTE
  
  # intialize 3 layer dnn prototype model
  python python/GenInitDNN.py --quiet \
    $DNN_HTE $DNN_PROTO
  
  # make connect.hed and basic.conf
  __make_connect_hed > $DNN_CONNECT_HED
  
  # init dnn-hmm with monophone models
  ln -sf "$PWD/$TRIPHONE_MMF" $MODELS_MMF
  ln -sf "$PWD/$TIEDLIST" $HMMLIST
  
  # associate DNN and HMM
  HHEd -A -D \
    -T 1 -H $MODELS_MMF -M $DIR/dnn \
    $DNN_CONNECT_HED $HMMLIST \
    > $DIR/dnn/HHEd_dnn_init.log
  
  # save init models
  cp $DNN_MODELS_MMF $DNN_INIT_MMF
}

# holdout_split
holdout_split() {
  echo "$SCRIPT_NAME -> holdout_split()"
  echo
  
  local vSpkr="$(bash ./random_speaker.sh --trn)"
  grep ${vSpkr} $MFCLIST > $DNN_HOLDOUT_SCP
  grep -v ${vSpkr} $MFCLIST > $DNN_TRAINING_SCP
}

# pretrain
pretrain() {
  echo "$SCRIPT_NAME -> pretrain()"
  echo "  State-to-frame force alignment"
  echo "  Compute global variance"
  echo
  
  # state to frame force alignment
  __state2frame_align

  # make basic.conf
  __make_basic_conf > $DNN_BASIC_CONF

  # compute global variance for unit variance normalization
  HCompV -A -D -T 3 \
    -k "*.%%%" -C configs/hcompv.conf \
    -q v -c $DNN_CVN \
    -S $MFCLIST > $DIR/dnn/HCompV_pretrain.log

  # use init.mmf as starting models
  cp $DNN_INIT_MMF $DNN_MODELS_MMF
   
  # reset DNN_PRETRAIN
  cat /dev/null > $DNN_PRETRAIN
  
  # training dnn-hmm models
  STAGE="dnn3" __SGD_training
}

# add_hidden_layer
add_hidden_layer() {
  local numOfNodes="$1"
  local layers="$(__read_numlayers)"
  local pretrainedModels="$DIR/dnn/dnn${layers}_pretrain.mmf"
  
  echo "$SCRIPT_NAME -> add_hidden_layer()"
  echo "  # hidden nodes: $1"
  echo "  # layers: $(( layers+1 ))"
  echo
  
  # add layer to pretrain models but not to the already fine-tuned one
  if [ -a "$pretrainedModels" ]; then
    cp $pretrainedModels $DNN_MODELS_MMF
  fi
  
  # make addlayer_?.hed
  __make_addlayer_hed $((layers ++)) $numOfNodes > $DIR/dnn/addlayer_${layers}.hed
  
  # add new layer macro to models
  HHEd -A -D \
    -T 1 -H $DNN_MODELS_MMF -M $DIR/dnn \
    $DIR/dnn/addlayer_${layers}.hed $HMMLIST \
    > $DIR/dnn/HHEd_add_hidden_layer.log
  
  # train the network after adding hidden layer
  STAGE="dnn${layers}" __SGD_training
}

# finetune
finetune() {
  echo "$SCRIPT_NAME -> finetune()"
  echo "  HNTrainSGD: y"
  echo
  
  local numLayers="$(__read_numlayers)"
  local models="$DIR/models/dnn_${numLayers}_hmm.mmf"
  
  # clone $DNN_MODELS_MMF for finetuning
  cp $DNN_MODELS_MMF "$models"
  
  # run finetune in background
  __SGD_finetune $numLayers "$models"
}

# initialize triphone dnn with context independent (CI) initialization
triphone_dnn_init() {
  echo "$SCRIPT_NAME -> triphone_dnn_init()"
  echo "  HHEd: y"
  echo "  CI initialization: all monophone dnn pre-trained models"
  echo
    
  # init dnn-hmm with triphone models
  ln -sf "$PWD/$TRIPHONE_MMF" $MODELS_MMF
  ln -sf "$PWD/$TIEDLIST" $HMMLIST
  
  # reset TRIPHONE_PRETRAIN content
  cat /dev/null > $DNN_TRIPHONE_PRETRAIN
  
  # associate DNN3 prototype and triphone HMM
  HHEd -A -D \
    -T 1 -H $MODELS_MMF -M $DIR/dnn \
    $DNN_CONNECT_HED $HMMLIST \
    > $DIR/dnn/HHEd_triphone_dnn_init.log
  
  local layers=3
  # context independent initialization
  while read file; do
    # add a hidden layer to models
    local addLayer_hed="$DIR/dnn/addlayer_$layers.hed"
    if [ -f "$addLayer_hed" ]; then
      HHEd -A -D \
        -T 1 -H $DNN_MODELS_MMF -M $DIR/dnn \
        $addLayer_hed $HMMLIST \
        > $DIR/dnn/HHEd_addLayer_hed.log
    fi
    
    __copy_dnn_pretrain_params "$file" $layers
    layers=$(( layers+1 ))
  done < $DNN_PRETRAIN
}

# triphone_dnn_finetune
triphone_dnn_finetune() {
  echo "$SCRIPT_NAME -> triphone_dnn_finetune()"
  echo "  HNTrainSGD: y"
  echo "  Models: triphone_dnn*_pretrain.mmf"
  echo
  
  # numLayers increment immediately in while loop to start with dnn3
  local numLayers=2
  local models=
  
  # state to frame force alignment
  __state2frame_align
  
  while read file; do
    if [ -f "$file" ]; then
      echo "    finetune: $file"
      
      numLayers=$(( numLayers+1 ))
      models="$DIR/models/triphone_dnn_${numLayers}_hmm.mmf"
      
      # clone $file for finetuning
      cp $file "$models"
      
      TRIPHONE=yes __SGD_finetune $numLayers "$models"
    fi
  done < $DNN_TRIPHONE_PRETRAIN
  echo
}

# wait_HNTrainSGD
wait_HNTrainSGD() {
  echo "$SCRIPT_NAME -> wait_HNTrainSGD()"
  echo "  waiting for all HNTrainSGD..."
  echo
  
  wait
}

# ------------------------------------
# dnn_trainning.sh - train dnn-hmm models
#
#   $1 : DIR
#   $2 : DNN_HIDDEN_NODES
# ------------------------------------

  setup "$@"
  dnn_init
  # holdout_split
  pretrain && finetune
  add_hidden_layer $DNN_HIDDEN_NODES && finetune
  add_hidden_layer $DNN_HIDDEN_NODES && finetune
  
  # # let monophone models finish tuning since triphone model will overwrite $DNN_TRAIN_ALIGNED_MLF
  # wait_HNTrainSGD
  #
  # # triphone DNN-HMM
  # triphone_dnn_init
  # triphone_dnn_finetune

  # wait for finetuned triphone models before decoding
  wait_HNTrainSGD

  # decoding
  bash ./decode.sh $DIR

  # generate stats
  mkdir -p $DIR/results/stats
  bash ./HNTrainSGD_stats $DIR/dnn $DIR/results/stats $DNN_HIDDEN_NODES
