#!/bin/sh

# -------------------------------------------#
# Khmer_word_recognition         02/19/2016  #
# -------------------------------------------#

# exit on error
set -e

E_USAGE="Usage: $0 \$pattern \$fileList

  \$pattern       : pattern to search for
  \$fileList      : file list to look at
"

# show usage
show_usage() {
  echo "$E_USAGE" >&2
}

# setup
setup() {
  bash ./args_check.sh 2 $@ || (show_usage && exit 1)
  PATTERN="$1"
  FILELIST="$2"
}

# main
main() {
  while read file; do
    if [ -a "$file" ]; then
      grep "$PATTERN" "$file" \
        | sed "s/^.* = \([0-9]*\.[0-9]*\).*/\1/"
    fi
  done < $FILELIST
}

# ------------------------------------
# search_for.sh
#
#   $1   : $PATTERN
#   $2   : $FILELIST
# ------------------------------------

setup "$@"
main
