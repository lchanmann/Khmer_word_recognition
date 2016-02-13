#!/bin/sh

# -----------------------------------------#
# Khmer_word_recognition       02/10/2016  #
# -----------------------------------------#

# exit on error
set -e

# E_VARS
E_USAGE="Usage: $0 \$dnn_proto"

# global variables
SCRIPT_NAME=$0
DNN_PROTO=

# show usage
show_usage() {
  echo $E_USAGE >&2
}

# ch_command
ch_command() {
  local N_Macro="$(cat $DNN_PROTO | grep '~N')"
  echo "CH $DNN_PROTO models/empty $N_Macro <HYBRID>"
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
    
  echo "$(ch_command)"
  echo "$(sw_command)"
  echo "$(sk_command)"
  printf "$(el_command)"
  echo
}

# ------------------------------------
# make_connect_hed.sh - make connect.hed for DNN-HMM initialization
#
#   $1 : DNN_PROTO
# ------------------------------------

  main $@
  