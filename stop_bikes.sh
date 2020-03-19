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
  q  code/util/intradaybikeswd.q -q -conn ${KDBRDBPORT}
  kill -15 $pid
fi
