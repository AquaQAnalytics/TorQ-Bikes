#!/bin/bash

# Load the environment 
. ./setenv.sh

# Get the base port
export KDBSTACKID="-stackid ${KDBBASEPORT}"

# Find the process id.
pid=$(ps -o pid,args -C q | grep ${KDBBASEPORT} | awk '{print $1}')

# Check the process is running. Kill if it is.
if [[ -z $pid  ]];then
  echo "BelfastBikes is not currently running."
else
  echo "Stopping BelfastBikes..."
  # Writes down data that has arrived during the day.
  q  code/util/intradaybikeswd.q -q -conn ${KDBBASEPORT}
  kill -15 $pid
fi
