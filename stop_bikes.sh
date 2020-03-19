#!/bin/bash

# Load the environment. 
. ./setenv.sh

# Get the base port and rdb port.
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export KDBRDBPORT=$(($KDBBASEPORT+1))

# Find the process id.
pid=$(ps -o pid,args -C q | grep ${KDBBASEPORT} | awk '{print $1}')

# Check the process is running. Kill if it is.
if [[ -z $pid  ]];then
  echo "BelfastBikes is not currently running."
else
  echo "Stopping BelfastBikes..."
  # Writes down data that has arrived during the day.
  q  code/util/intradaybikeswd.q -q -conn hhh
  if [[ $? = 0  ]]; then 
    kill -15 $pid
  else
    read -p "Todays data has not been saved. Do you still want to proceed?(y/n)" user
    case $user in
      [Yy]* ) echo "Proceeding with shutdown...";kill -15 $pid;; 
      [Nn]* ) echo "Cancelling shutdown.";exit 0 ;;
      * ) echo "Expected y/n.";;
    esac
  fi
fi
