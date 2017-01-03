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

echo_my "--> '$BASH_SOURCE' -->" $ECHO_DEBUG

# Message size is irrelevant since responder just uses whatever message is on the queue
runParallelClients $RESPONDER $1 $2 responder_msg.xml 1
echo_my "All responder threads have been started, now can go to sleep for 100 days so that container does not terminate (86400 sec in a day)..."
sleep 8640000

echo_my "<-- '$BASH_SOURCE' <--" $ECHO_DEBUG