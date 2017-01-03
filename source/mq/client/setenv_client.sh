#!/bin/bash
# DATE:         December 15, 2016
# AUTHOR:		Roman Kharkovski (http://advantage.ibm.com/about)
# DESCRIPTION:  This script sets MQ client variables

echo_my "--> '$BASH_SOURCE' -->" $ECHO_DEBUG

#########################################
# IBM Performance Harness for JMS (load generation client) specific settings
#########################################
# How many times to repeat the test for each set of configuration settings (to use the average result of several runs)
REPEATS=1

# How many concurrent client threads to start within a single JMSPerf.jar call
# The value of CLIENT_THREADS will be calculated later by dividing NP_CLIENT_THREADS or CLIENT_THREADS by the number of servers, 
# thus calculating number of threads for each server connection
# for NON-PERSISTENT test
#NP_CLIENT_THREADS=100
NP_CLIENT_THREADS=1
# for PERSISTENT test
#P_CLIENT_THREADS=100
P_CLIENT_THREADS=1

#########################################
# Possible message sizes
MSG_20=00_20.xml
MSG_256=01_256.xml
MSG_1024=02_1024.xml
MSG_10K=03_10K.xml
MSG_100K=04_100K.xml
MSG_1M=05_1M.xml
MSG_10M=06_10M.xml
#LIST_OF_MSG_SIZES="$MSG_20 $MSG_256 $MSG_1024 $MSG_10K $MSG_100K $MSG_1M $MSG_10M"
LIST_OF_MSG_SIZES="$MSG_1024"

#########################################
# Types of tests to be run
PERSISTENT=Persistent
NON_PERSISTENT=NonPersistent
#LIST_OF_TEST_TYPES="$NON_PERSISTENT $PERSISTENT"
LIST_OF_TEST_TYPES="$NON_PERSISTENT"

#########################################
# I want the total test time for requestor to be shorter than responder - the reason is that we are measuring performance based on requestor and hence responder needs to be already 
# running before we even start requestor to avoid zero message rate - in fact, we could even leave responder running forever 
# 24 hours = 86400
REQUESTOR_RUN_TIME=30

#########################################
# Test warmup time - this period wont be included in summary stats
#WARM_UP_TIME=60
WARM_UP_TIME=10

#########################################
# run responder for one week in background: 60 sec * 60 min * 24 hrs * 7 days
RESPONDER_RUN_TIME=604800

# Number to be appended to the end of the queue name (i.e. REQUEST1, REQUEST2 or REPLY1, REPLY2, etc. up to the max)
# Please note that total number of queues is a multiple of MAX_Q_NUM and the number of servers (brokers)
# For example, if we have 4 servers, then total number of queues is 4*MAX_Q_NUM*2 (where 2 is for request and reply queue)
MIN_Q_NUM=1
MAX_Q_NUM=2
#MAX_Q_NUM=20

#########################################
# how many more responders to start relative to the number of requestors (for the equal number of requestors and responders set this to 1)
RESPONDER_MULTIPLIER=1.2

#########################################
# These variables below can be extended to support other providers, but then you would have to add new functions to the script
#AMQ=ActiveMQ
WMQ=IBM_MQ
#LIST_OF_SERVERS="$WMQ $AMQ"
LIST_OF_SERVERS="$WMQ"

#########################################
# DNS name of the remote host that runs all Docker images with MQ servers. note that internally hostnames within those Docker images may differ
MQ_HOST=172.17.0.2
#MQ_HOST=localhost

#########################################
# Channel used to connect the client to the server
CHANNEL=SYSTEM.ADMIN.SVRCONN
# CHANNEL=SYSTEM.DEF.SVRCONN

#########################################
# Performance tool path
PERFHARNESS_PATH=/opt/perfharness
PERFHARNESS_JAR=perfharness.jar

#########################################
# Installation paths - same across all machines
WMQ_INSTALL_DIR=/opt/mqm
LD_LIBRARY_PATH=$WMQ_INSTALL_DIR/java/lib64
JAVA_HOME=$WMQ_INSTALL_DIR/java/jre64/jre
PATH=$PATH:$WMQ_INSTALL_DIR/bin:$JAVA_HOME/bin
MQ_JAVA_INSTALL_PATH=/opt/mqm/java
MQ_JAVA_DATA_PATH=/var/mqm
MQ_JAVA_LIB_PATH=/opt/mqm/java/lib64
CLASSPATH=/opt/mqm/java/lib/com.ibm.mq.jar:/opt/mqm/java/lib/com.ibm.mqjms.jar:/opt/mqm/java/lib/com.ibm.mq.allclient.jar:/opt/mqm/samp/wmqjava/samples:/opt/mqm/samp/jms/samples
CLASSPATH=$CLASSPATH:${PERFHARNESS_PATH}/${PERFHARNESS_JAR}
MESSAGE_PATH=$PROJECT_HOME/messages

######################################### 
# Stat reporting frequency in seconds
STAT_REPORT_SEC=5

######################################### 
# Settings for JVM with PerfHarness
JAVA_OPTS="-Xms4g -Xmx4g"

#########################################
# Message wait timeout for perfharness
TIMEOUT=40000

#########################################
# Message type (text,bytes,stream,map,object,empty). (default: text)
MSG_TYPE=text

######################################### 
# WorkerThread start interval (ms). This controls the pause between starting multiple threads
WAIT=0

#########################################
# If need to use correlation IDs, need to pass the option ('false' default)
CORRELATION=false

#########################################
# Requestor initiates message and waits for reply
REQUESTOR=Requestor

#########################################
# Responder gets the message from the input Q and puts that same message to the reply Q without touching the content
RESPONDER=Responder

#########################################
# This number below will be used as a difference between Requestor and Responder client IDs. 
CLIENT_ID_SHIFT=1000

#AMQ_INPUT_Q=dynamicQueues/REQUEST
#AMQ_OUTPUT_Q=dynamicQueues/REPLY

#########################################
# Template for the name of the queues
MQ_INPUT_Q=REQUEST
MQ_OUTPUT_Q=REPLY

#########################################
# For more WMQ settings see ../mq/functions.sh in the *CreateQueueManagerIniFile* function
WMQ_ACKNOWLEDGEMENT_MAX_MSGS=10

#########################################
# Name of responder and requestor containers and some of their settings
RESPONDER_CONTAINER_NAME="responderMQ"
REQUESTOR_CONTAINER_NAME="requestorMQ"
RESPONDER_VOLUME=${DATA_DIR}/${RESPONDER_CONTAINER_NAME}
REQUESTOR_VOLUME=${DATA_DIR}/${REQUESTOR_CONTAINER_NAME}

echo_my "<-- '$BASH_SOURCE' <--" $ECHO_DEBUG

#########################################
# This is log path within Docker container
LOG_DIR=/var/mqm
RESULTS_NAME=run.log
RESULTS_FILE=$LOG_DIR/${RESULTS_NAME}
RESPONDER_LOG=responder.log
HEADER_LINE_PRINTED=false