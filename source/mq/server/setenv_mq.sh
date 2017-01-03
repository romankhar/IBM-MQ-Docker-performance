#!/bin/bash
# DATE:			December 8, 2016
# AUTHOR:		Roman Kharkovski (http://advantage.ibm.com/about)
# DESCRIPTION:	This script sets IBM MQ environment variables for clients and servers

#########################################
# Directories inside of Docker
MQ_DATA_DIR=/var/mqm
MQ_LOG_DIR=$MQ_DATA_DIR/log

#########################################
# Listerner port # when running in Docker
# read more about MQ JMS clients: http://www.ibm.com/support/knowledgecenter/SSFKSJ_9.0.0/com.ibm.mq.dev.doc/q031730_.htm
MQ_INSIDE_PORT=1414

#########################################
# User info within Docker container
PERFORMANCE_USER=mqperf
PERFORMANCE_USER_GRP=mqm
PERFORMANCE_USER_PW=password

##############################################################################
# Build a name for Queue Manager based on its index
# Parameters:
# 	1 - sequential index of this QM (0..9999)
##############################################################################
setQMname() {
	echo "QMgr${1}"
}	

##############################################################################
# Build a port number for Queue Manager based on its index
# Parameters:
# 	1 - sequential index of this QM (0..9999)
##############################################################################
setQMport() {
	echo "$[MQ_INSIDE_PORT + MQ_PORT_SHIFT * $1 + 1]"
}

##############################################################################
# Build a host name for Queue Manager based on its index
# Parameters:
# 	1 - sequential index of this QM (0..9999)
##############################################################################
setQMhost() {
	echo "mqhost${1}"
}

##############################################################################
# Build a container name for Queue Manager based on its index
# Parameters:
# 	1 - sequential index of this QM (0..9999)
##############################################################################
setContainerName() {
	echo "server${1}mq"
}