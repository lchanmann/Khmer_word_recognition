#!/bin/bash

# global variable
QUEUE_DB=/tmp/$$.queue
MAX_QUEUE=3

# __check_queue
__check_queue() {
  local running=0
  local checkInterval=2
  local psCount=
  
  while true; do
    running=$(wc -l $QUEUE_DB | awk '{print $1}')
    if [ "$running" -lt "$MAX_QUEUE" ]; then
      break;
    fi
    
    # check each pid
    while read pid; do
      psCount=$(ps -p $pid | grep -c $pid | bc)
      if [ "$psCount" -eq "0" ]; then
        sed -i.bak "/$pid/d" $QUEUE_DB
      fi
    done < $QUEUE_DB
    sleep $checkInterval
  done
}

# __add_queue
__add_queue() {
  local pid="$1"
  
  echo $pid >> $QUEUE_DB
}

set_queue_DB() {
  QUEUE_DB="$1"
  cat /dev/null > $QUEUE_DB
}

set_max_queue() {
  MAX_QUEUE="$1"
}

run_in_queue() {
  __check_queue
  eval $@ &
  __add_queue $!
}

# -------------------------------------------------------#
# process_queue.sh - run a process in background queue   #
# -------------------------------------------------------#
#
# Usage:
#   source process_queue.sh     # include this at the top of your script
#   set_queue_DB file           # set queue db path (default: /tmp/$pid.queue)
#   set_max_queue number        # set maximum queue size (default: 3)
#   ...
#   run_in_queue cmd arg1 arg2  # add run_in_queue before the command to be run in the queue
#

cat /dev/null > $QUEUE_DB
