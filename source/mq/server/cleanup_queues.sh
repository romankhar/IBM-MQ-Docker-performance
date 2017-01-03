#!/bin/bash
#
# DATE:		November 25, 2016
# AUTHOR:	Roman Kharkovski (http://advantage.ibm.com/about)
#
# DESCRIPTION:
# 	This script cleans all queues by calling "q" support pack to remove any and all existing messages on all queues
#
# PREREQUISITES:
#	This script requires that MQ support pack "MA01: WebSphere MQ Q PROGRAM" is installed

source setenv.sh
source setenv_mq.sh
source setenv_client.sh

echo_my "--> '$BASH_SOURCE' -->"

OLD_MSGS=${MQ_LOG_DIR}/cleanup_queues.log
QM=$MQ_QMGR_NAME
echo_my "MAX_Q_NUM=$MAX_Q_NUM"

echo "------- Cleaning old messages for QM '$QM' on `date`" >> $OLD_MSGS
for Q in `seq 1 $MAX_Q_NUM`; do
	echo "------- Cleaning old messages for 'REQUEST$Q'" >> $OLD_MSGS
	q -m $QM -I $MQ_INPUT_Q$Q >> $OLD_MSGS
	echo "------- Cleaning old messages for 'REPLY$Q'" >> $OLD_MSGS
	q -m $QM -I $MQ_OUTPUT_Q$Q >> $OLD_MSGS
done  
echo "<------- End of cleanup" >> $OLD_MSGS
echo_my "<-- '$BASH_SOURCE' <--"