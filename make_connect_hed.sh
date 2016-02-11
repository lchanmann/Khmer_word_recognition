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
E_USAGE="Usage: $0 \$dnn_proto"

# global variables
SCRIPT_NAME=$0
DNN_PROTO=
DIR=
CONNECT_HED=

# show usage
show_usage() {
  echo $E_USAGE >&2
}

# ch_command
ch_command() {
  local N_Macro="$(cat $DNN_PROTO | grep '~N')"
  touch $DIR/emtpy
  echo "CH $DNN_PROTO $DIR/emtpy $N_Macro <HYBRID>"
}

# sw_command
sw_command() {
  echo "SW 1 39"
}

# sk_command
sk_command() {
  echo "SK MFCC_0_D_A_Z"
}

# el_command
el_command() {
  cat $DNN_PROTO | grep '~L' | sort -u | sed "s/^/EL /"
}

# main
main() {
  bash ./args_check.sh 1 $@ || (show_usage && exit 1)
  DNN_PROTO=$1
  DIR=$(dirname $1)
  CONNECT_HED="$DIR/connect.hed"
  
  echo "$(ch_command)" >  $CONNECT_HED
  echo "$(sw_command)" >> $CONNECT_HED
  echo "$(sk_command)" >> $CONNECT_HED
  printf "$(el_command)" >> $CONNECT_HED
  echo >> $CONNECT_HED
}

# ------------------------------------
# make_connect_hed.sh - make connect.hed for DNN-HMM initialization
#
#   $1 : DNN_PROTO
# ------------------------------------

  main experiments/step_by_step/dnn/proto # $@
  