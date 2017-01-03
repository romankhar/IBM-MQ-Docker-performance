#!/bin/bash
# DATE:		November 25, 2016
# AUTHOR:	Roman Kharkovski (http://advantage.ibm.com/about)

# This prevents running the script if any of the variables have not been set
set -o nounset
# This automatically exits the script if any error occurs while running it
set -o errexit

#########################################
# Project location - this is where this script is located
PROJECT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#########################################
# Import my custom ECHO function
source $PROJECT_HOME/echo_my.sh
echo_my "--> '$BASH_SOURCE' -->" $ECHO_DEBUG

#########################################
# Directory to store server data and logs as seen from outside of container.
# Mounted to Docker images via volumes.
DATA_DIR=/home/roman/MOM_data

#########################################
# Directory to store my scripts inside of the Docker containers.
EXEC_DIR=/usr/local/bin

#########################################
# Shared Docker settings across this project
REPO=rk

#########################################
# Docker settings for MQ Docker images
MQ_VANILLA_IMAGE=$REPO:mq9vanilla
MQ_IMAGE=$REPO:mq9server
MQ_CLIENT_IMAGE=$REPO:mq9client
MQ_PORT_SHIFT=1

#########################################
# How many MQ servers to start. Each individual server is hosted by its own Docker container
NUM_MQ_SERVERS=1

#########################################
# How many MQ servers to start. Each individual server is hosted by its own Docker container
REQUESTOR_WORK_COMPLETE_SIGNAL="requestor_is_complete.signal"

#########################################
# What servers to test
AMQ=AMQ
IBMMQ=IBM_MQ
#LIST_OF_SERVERS="${IBMMQ} ${AMQ}"
LIST_OF_SERVERS="${IBMMQ}"

echo_my "<-- '$BASH_SOURCE' <--" $ECHO_DEBUG