# Load the environment
. ./setenv.sh

# sets the base port for a default TorQ installation
export KDBSTACKID="-stackid ${KDBBASEPORT}"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l32

# launch the service
echo 'Starting BelfastBikes...'
nohup q torq.q ${KDBSTACKID} -proctype belfastbikes -procname belfastbikes1 -localtime -kdblog ${KDBLOG} -xmllog ${XMLLOG} -cityno ${CITYNO} </dev/null >$KDBLOG/log.txt 2>&1 & 
