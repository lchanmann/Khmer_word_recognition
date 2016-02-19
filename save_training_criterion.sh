#!/bin/sh

# -------------------------------------------#
# Khmer_word_recognition         02/19/2016  #
# -------------------------------------------#

# exit on error
set -e

E_USAGE="Usage: $0 \$logFiles [\$saveTo]

  \$logFiles     : log files pattern
  [\$saveTo]     : training criterion output file
"

# show usage
show_usage() {
  echo "$E_USAGE" >&2
}

TRAINING_CRITERION_DATA="TRAINING_CRITERION.data"

# setup
setup() {
  bash ./args_check.sh 1 $@ || (show_usage && exit 1)
  LOGFILES="$1"
  if [ -n "$2" ]; then
    TRAINING_CRITERION_DATA="$2"
  fi
}

# main
main() {
  ls -1d $LOGFILES | sort -u | while read file; do
    grep "Cross Entropy" "$file" \
      | sed "s/^.* = \([0-9]*\.[0-9]*\).*/\1/" \
      | perl -p -e "s/\n/,/;" \
      | perl -p -e "s/,$/\n/" >> $TRAINING_CRITERION_DATA
  done
}

# ------------------------------------
# save_training_criterion.sh
#
#   $1   : $LOGFILES
# ------------------------------------

setup "$@"
main
