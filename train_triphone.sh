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
PHONEME_MLF=
TRIPHONE_MLF=
PHONEME_WITH_ALIGNMENT=
MODELS_MMF=
MONOPHONE_MMF=
STATSFILE=
HMMLIST=
CDLIST=
MKTRI_HED=
MKTREE_HED=
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
  PHONEME_MLF="$DIR/phoneme.mlf"
  TRIPHONE_MLF="$DIR/triphone.mlf"
  PHONEME_WITH_ALIGNMENT="$DIR/phoneme_with_alignment.mlf"
  MODELS_MMF="$DIR/models/models.mmf"
  MONOPHONE_MMF="$DIR/models/monophone.mmf"
  STATSFILE="$DIR/khmer_triphone.sta"
  HMMLIST="$DIR/hmmlist"
  CDLIST="$DIR/cdlist"
  TIED_CDLIST="$DIR/tied_cdlist"
  MKTRI_HED="$DIR/mktri.hed"
  MKTREE_HED="$DIR/mktree.hed"

  # stdout
  echo "$SCRIPT_NAME -> setup()"
  echo "  DIR: $DIR"
  echo
}

# make monophone list
make_hmmlist() {
  echo "$SCRIPT_NAME -> make_hmmlist()"
  echo "  HLEd: y"
  echo "  write: $PHONEME_MLF"
  echo "  write: $HMMLIST"
  echo "  write: $HMMLIST.nosil"
  echo

  # word -> phoneme level label generation
  HLEd -T 1 -l '*/' \
    -i $PHONEME_MLF \
    -d dictionary/dictionary.dct \
    ed_files/mkphn.led labels/words.mlf > $DIR/hled_make_hmmlist.log

  # phone set generation
  cat $PHONEME_MLF \
    | grep '^[a-z]' \
    | sort -u > $HMMLIST
  cat $HMMLIST \
    | grep -v '^sil' \
    | sort -u > $HMMLIST.nosil
}

# make context dependent triphone list
make_cdlist() {
  echo "$SCRIPT_NAME -> make_cdlist()"
  echo "  HLEd: y"
  echo "  write: $TRIPHONE_MLF"
  echo "  write: $CDLIST"
  echo

  # phoneme -> triphone labels generation
  HLEd -T 1 -l '*/' \
    -i $TRIPHONE_MLF -n $CDLIST \
    ed_files/mktri.led $PHONEME_MLF > $DIR/hled_make_cdlist.log

  # triphone list generation
  perl pl/mkful.pl $HMMLIST.nosil > ${CDLIST}_redund
  perl pl/mkuniq.pl ${CDLIST}_redund  ${CDLIST}_all
}

# make required hed file
make_hed_files() {
  echo "$SCRIPT_NAME -> make_hed_files()"
  echo "  write: $MKTRI_HED"
  echo "  write: $MKTREE_HED"
  echo

  # phonetic question set generation for triphone clustering
  local ro_command="RO 30.0 $STATSFILE"
  local tb_command="TB 480.0 $HMMLIST"
  local au_command="AU ${CDLIST}_all"
  local st_command="ST $DIR/khmer_QS_and_tree"
  local co_command="CO $TIED_CDLIST"
  local lt_command="LT $DIR/khmer_QS_and_tree"

  # mktri.hed -> monophone to triphone
  perl pl/mktrihed.pl $HMMLIST $CDLIST > $MKTRI_HED

  # mktree.hed -> stats, QS and tree, cdlist_all, tied_cdlist
  echo ${ro_command} > $MKTREE_HED
  cat ed_files/khmer_QS.hed >> $MKTREE_HED
  perl pl/mktrehed.pl $tb_command >> $MKTREE_HED
  echo TR 1 >> $MKTREE_HED
  echo ${au_command} >> $MKTREE_HED
  echo ${st_command} >> $MKTREE_HED
  echo ${co_command} >> $MKTREE_HED

  # # mkfull.hed -> tied state to full state
  # echo TR 1 > $DIR/mkfull.hed
  # echo ${lt_command} >> $DIR/mkfull.hed
  # echo ${au_command} >> $DIR/mkfull.hed
}

# initialize models
initialize() {
  echo "$SCRIPT_NAME -> initialize()"
  echo "  deps:"
  echo "    - init.sh"
  echo "    - $DIR"
  echo "  output: $MODELS_MMF"
  echo

  bash ./init.sh $DIR
  cp $MODELS_MMF $MONOPHONE_MMF
}

# create triphone models from monophone
make_triphone_model() {
  echo "$SCRIPT_NAME -> make_triphone_model()"
  echo "  HHEd: y"
  echo "  HERest: 2x"
  echo "  write: $STATSFILE"
  echo

  # reproduce clean models.mmf from monophone.mmf for isolated testing
  cp $MONOPHONE_MMF $MODELS_MMF
  # create triphone models from monophone
  HHEd \
    -T 1 -H $MODELS_MMF \
    $MKTRI_HED $HMMLIST \
    > $DIR/models/hhed_make_triphone_model.log

  # first 2x parameter re-estimation on triphone models
  HERest \
    -T 1 -H $MODELS_MMF \
    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
    -S $MFCLIST -I $TRIPHONE_MLF $CDLIST \
    > $DIR/models/herest_make_triphone_model.log
  HERest \
    -T 1 -H $MODELS_MMF \
    -s $STATSFILE \
    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
    -S $MFCLIST -I $TRIPHONE_MLF $CDLIST \
    > $DIR/models/herest_make_triphone_model.log
}

# tied triphone model
make_tied_triphone_model() {
  echo "$SCRIPT_NAME -> make_tied_triphone_model()"
  echo "  HHEd: y"
  echo "  HERest: 2x"
  echo "  write: $TIED_CDLIST"
  echo "  replace: $HMMLIST"
  echo "  replace: $PHONEME_MLF"
  echo

  # generate tied state triphone models
  HHEd \
    -T 1 -H $MODELS_MMF \
    $MKTREE_HED $CDLIST \
    > $DIR/hhed_make_tied_triphone_model.log
  
  # use triphone.mlf -> phoneme.mlf and tied_cdlist -> hmmlist
  mv $PHONEME_MLF $DIR/monophone.mlf
  mv $TRIPHONE_MLF $PHONEME_MLF
  mv $HMMLIST $DIR/monolist
  mv $TIED_CDLIST $HMMLIST

  # # extract full state triphone models
  # cp $MODELS_MMF $DIR/models/models_full.mmf
  # HHEd \
  #   -T 1 -H $DIR/models/models_full.mmf \
  #   $DIR/mkfull.hed $HMMLIST \
  #   > $DIR/hhed_make_tied_triphone_model_2.log

  # 2x parameter re-estimation on tied triphone models
  HERest \
    -T 1 -H $MODELS_MMF \
    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
    -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
    > $DIR/herest_make_tied_triphone_model.log
  HERest \
    -T 1 -H $MODELS_MMF \
    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
    -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
    > $DIR/herest_make_tied_triphone_model.log
}

# viterbi alignment
viterbi_align() {
  echo "$SCRIPT_NAME -> viterbi_align()"
  echo "  HVite: y"
  echo "  HERest: 2x"
  echo "  write: $PHONME_WITH_ALIGNMENT"
  echo

  # viterbi alignment
  HVite \
    -T 1 -a -l '*' -I labels/words.mlf -i $PHONME_WITH_ALIGNMENT \
    -C configs/hvite.conf -m -b SIL -o SW -y lab \
    -S $MFCLIST -H $MODELS_MMF \
    dictionary/dictionary.dct.withsil $HMMLIST \
    > $DIR/models/hvite_viterbi_align.log

  # 2x parameter re-estimation right after viterbi alignment
  HERest \
    -T 1 -H $MODELS_MMF \
    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
    -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
    > $DIR/models/herest_viterbi_align.log

  HERest \
    -T 1 -H $MODELS_MMF \
    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
    -S $MFCLIST -I $PHONEME_MLF $HMMLIST \
    > $DIR/models/herest_viterbi_align.log

  cp $MODELS_MMF $DIR/models/gmm_1_hmm.mmf
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
# train_triphone.sh - train monophone model
#
#   $1 : MFCLIST
# ------------------------------------

  setup $1
  make_hmmlist
  make_cdlist
  make_hed_files
  initialize
  make_triphone_model
  make_tied_triphone_model
  viterbi_align
  models_tuning
