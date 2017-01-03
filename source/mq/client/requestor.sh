#!/bin/bash
#
# DESCRIPTION:
#	This script runs workload on the MOM server - waiting for messages on the input queue and sending those same messages to the output queue.
# 	In doing so it works as a partner to the requestor script.
#
# PARAMS:
# 	1 - Type of server (IBM_MQ or AMQ as in $LIST_OF_SERVERS)
# 	2 - Type of test (persistent or not as in $LIST_OF_TEST_TYPES)
#
# AUTHOR:   	
#	Roman Kharkovski (http://whywebsphere.com/resources-links)

cd ${EXEC_DIR}

source setenv.sh
source setenv_mq.sh
source setenv_client.sh
source perfharness.sh

echo_my "***********************************************************************" $ECHO_NO_PREFIX
echo_my "Begin '$BASH_SOURCE'..."
echo_my "Visit my blog for details about this script: http://advantage.ibm.com"
echo_my "***********************************************************************" $ECHO_NO_PREFIX
echo "------- Test run: `uname -a`" >> $RESULTS_FILE
echo "-------> Start of test run: `date`" >> $RESULTS_FILE

RUNTIME=$1
TEST_TYPE=$2

# As we start this client, we need to make sure we remove the "completeness signal"
SIGNAL=${LOG_DIR}/${REQUESTOR_WORK_COMPLETE_SIGNAL}
if [ -f "$SIGNAL" ]; then rm $SIGNAL; fi

echo_my "Cleaning log directory - it is OK if there is an error while doing it..." $ECHO_DEBUG
mkdir $LOG_DIR || true
mv $RESULTS_FILE ${RESULTS_FILE}.bak || true

for MSG_SIZE in $LIST_OF_MSG_SIZES; do
	for i in `seq 1 $REPEATS`; do 
		# Before we run the test, need to cleanup all queues from any old stuff
		#cleanupQueues $RUNTIME
		# We  measure requestor times, but responders need to be started on the server in advance
		runParallelClients $REQUESTOR $RUNTIME $TEST_TYPE $MSG_SIZE $i
	done
done		
echo "<------- Success - end of test run: `date`" >> $RESULTS_FILE

# now call the script to aggregate the results
${EXEC_DIR}/beautify.sh
# All work is complete, so we can signal to the master script that we are done
touch $SIGNAL

echo_my "***********************************************************************" $ECHO_NO_PREFIX
echo_my "Success: '$BASH_SOURCE' script is done."
echo_my "***********************************************************************" $ECHO_NO_PREFIX