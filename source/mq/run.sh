#!/bin/bash
#
# DESCRIPTION:
# 	This is the main script for the project and is the only one that is invoked by hand. All other scripts are either for 
# 	being called from one of this script's children or for debugging.
#   More details here: http://whywebsphere.com/2014/03/13/websphere-mq-and-apache-activemq-performance-comparison-part-1/
#
# AUTHOR:   	
# 	Roman Kharkovski (http://advantage.ibm.com/about)

set -o nounset
set -o errexit

echo "****************************************************************************"
echo "   Starting performance test '$BASH_SOURCE'"
echo "   Visit my blog for details about this script: http://advantage.ibm.com"
echo "****************************************************************************"

source ../setenv.sh
source client/setenv_client.sh
source build.sh

CPU_ACTIVITY_OUTPUT_FILE=activity_recorder.log
OLD_LOGS_DIR="../../old"

##############################################################################
# Run for the first time all of the existing Docker containers with MQ servers 
##############################################################################
run_mq_servers() {
	# Create and start new container
	for ((i=0; i<${NUM_MQ_SERVERS}; i++)); do
		local CONTAINER_NAME=$(setContainerName $i)
		local QM_NAME=$(setQMname $i)
		local QM_PORT=$(setQMport $i)
		local QM_HOST=$(setQMhost $i)
		echo_my "Running container ${CONTAINER_NAME}..."
		docker run --env LICENSE=accept \
				--env MQ_QMGR_NAME=${QM_NAME} \
				--volume ${DATA_DIR}/${CONTAINER_NAME}:${MQ_DATA_DIR} \
				--publish ${QM_PORT}:${MQ_INSIDE_PORT} \
				--detach \
				--hostname ${QM_HOST} \
				--name ${CONTAINER_NAME} ${MQ_IMAGE}
				# /bin/bash
				# -t -i \
				# --network="host" \

	done
}

##############################################################################
# Start all of the existing Docker containers with MQ servers in them.
#    In order for them to start, they must have been stopped earlier
##############################################################################
start_mq_servers() {
	# Start existing container without creating a new one
	for ((i=0; i<${NUM_MQ_SERVERS}; i++)); do
		local CONTAINER_NAME=$(setContainerName $i)
		echo_my "Starting container ${CONTAINER_NAME}..."
		docker start ${CONTAINER_NAME}
	done
}

##############################################################################
# Stop all of the existing Docker containers with MQ servers in them
##############################################################################
stop_mq_servers() {
	for ((i=0; i<${NUM_MQ_SERVERS}; i++)); do
		local CONTAINER_NAME=$(setContainerName $i)
		echo_my "Stopping container ${CONTAINER_NAME}..."
		docker stop ${CONTAINER_NAME}
	done
}

##############################################################################
# Remove all of the existing Docker containers with MQ servers 
#    as well as their files, logs, etc.
##############################################################################
remove_mq_servers() {
	for ((i=0; i<${NUM_MQ_SERVERS}; i++)); do
		local CONTAINER_NAME=$(setContainerName $i)
		echo_my "Removing container ${CONTAINER_NAME}..."
		docker rm ${CONTAINER_NAME}
		sudo rm -rf ${DATA_DIR}/${CONTAINER_NAME}
	done
}

##############################################################################
# Check if all MQ servers are in a running state
##############################################################################
wait4QMstart()
{
	for ((i=0; i<${NUM_MQ_SERVERS}; i++)); do
		local CONTAINER_NAME=$(setContainerName $i)
		local QM_NAME=$(setQMname $i)
		local MAX_WAIT_TIME_SEC=120
	  	local ELAPSED_SEC=0
	  	local STATE="tbd"
	  	while [ "$STATE" != "RUNNING" ]; do
	    	sleep 1
	    	STATE=`docker exec --tty --interactive $CONTAINER_NAME dspmq -n -m $QM_NAME | awk -F '[()]' '{ print $4 }'`
	    	echo_my "Current state of QM '$QM_NAME' is '$STATE'..."
	    	ELAPSED_SEC=$[ELAPSED_SEC + 1]
	    	if [ $ELAPSED_SEC -gt $MAX_WAIT_TIME_SEC ]; then
	    		echo_my "Server did not start in the maximum allowed time of $MAX_WAIT_TIME_SEC" $ECHO_ERROR
	    		exit 1
	    	fi
	  	done
	done
}

##############################################################################
# Wait until we see a signal that requestors are all complete
##############################################################################
wait4requestors()
{
	local COMPLETE=false
	local i=0
	local SLEEP_TIME=5
	while ( ! "$COMPLETE" ) do
		echo_my "Waiting for '$REQUESTOR_CONTAINER_NAME' to finish...$i sec"
		i=$[i + SLEEP_TIME]
		sleep $SLEEP_TIME
		if [ -f "$SIGNAL" ]; then COMPLETE=true; fi
	done
}

##############################################################################
# Run for the first time responder and requestor clients
# PARAMS:
# 	1 - Type of server (MQ or AMQ or other, as in $LIST_OF_SERVERS)
# 	2 - Type of test (persistent or not as in $LIST_OF_TEST_TYPES)
##############################################################################
run_mq_clients() {
	# Create and start responder and requestor containers
	local HOST_NAME=mqclient

	echo_my "Running RESPONDER container ${RESPONDER_CONTAINER_NAME}..."
	docker run --volume ${RESPONDER_VOLUME}:${LOG_DIR} \
			--hostname ${HOST_NAME}responder \
			--detach \
			--name ${RESPONDER_CONTAINER_NAME} ${MQ_CLIENT_IMAGE} \
			responder.sh $1 $2
			# -ti /bin/bash

	echo_my "Running REQUESTOR container ${REQUESTOR_CONTAINER_NAME}..."
	docker run --volume ${REQUESTOR_VOLUME}:${LOG_DIR} \
			--hostname ${HOST_NAME}requestor \
			--detach \
			--name ${REQUESTOR_CONTAINER_NAME} ${MQ_CLIENT_IMAGE} \
			requestor.sh $1 $2
}

##############################################################################
# Start responder and requestor clients (must have been stopped earlier)
##############################################################################
start_mq_clients() {
	# Start existing container without creating a new one
	echo_my "Starting container ${RESPONDER_CONTAINER_NAME}..."
	docker start ${RESPONDER_CONTAINER_NAME}

	echo_my "Starting container ${REQUESTOR_CONTAINER_NAME}..."
	docker start ${REQUESTOR_CONTAINER_NAME}
}

######################## ######################################################
# Remove responder and requestor clients and their logs and files
##############################################################################
remove_mq_clients() {
		echo_my "Removing container ${RESPONDER_CONTAINER_NAME}..."
		docker rm ${RESPONDER_CONTAINER_NAME} || true
		echo_my "Removing container ${REQUESTOR_CONTAINER_NAME}..."
		docker rm ${REQUESTOR_CONTAINER_NAME} || true
		
		sudo rm -rf ${DATA_DIR}/${RESPONDER_CONTAINER_NAME} || true
		sudo rm -rf ${DATA_DIR}/${REQUESTOR_CONTAINER_NAME} || true
}

##############################################################################
# Stop responder and requestor clients
##############################################################################
stop_mq_clients() {
	echo_my "Stopping container ${RESPONDER_CONTAINER_NAME}..."
	docker stop ${RESPONDER_CONTAINER_NAME} || true
	echo_my "Stopping container ${REQUESTOR_CONTAINER_NAME}..."
	docker stop ${REQUESTOR_CONTAINER_NAME} || true
}

##############################################################################
# Stop recording CPU stats
##############################################################################
stop_activity_recording() {
	echo_my "Kill any existing 'docker stats' instances..."
	#kill -9 $(ps aux | grep '[i]ostat' | awk '{print $2}') | true
	kill -9 $(ps aux | grep '[d]ocker stats' | awk '{print $2}') | true
}

##############################################################################
# Recording CPU, memory and other stats for all container
##############################################################################
start_activity_recording() {
	stop_activity_recording
	echo_my "Start recording CPU and disk usage into the file '$CPU_ACTIVITY_OUTPUT_FILE'..."
	local CONTAINERS="$RESPONDER_CONTAINER_NAME $REQUESTOR_CONTAINER_NAME"
	
	for ((i=0; i<${NUM_MQ_SERVERS}; i++)); do
		CONTAINERS="$CONTAINERS $(setContainerName $i)"
	done

	echo_my "List of containers to be monitoried: '$CONTAINERS'"
	nohup docker stats $CONTAINERS >> $CPU_ACTIVITY_OUTPUT_FILE 2> $CPU_ACTIVITY_OUTPUT_FILE < /dev/null &
}

##############################################################################
# MAIN
##############################################################################
echo_my "Build latest Docker images with all updates (assuming vanilla image is current once it was built using setup.sh)..."
build_mq_server
build_mq_client

# Move results of previous run into backup file
GLOBAL_RESULTS_FILE="results.log"
if [ -f "$GLOBAL_RESULTS_FILE" ]; then mv $GLOBAL_RESULTS_FILE $OLD_LOGS_DIR/${GLOBAL_RESULTS_FILE}_`date +%s`; fi
if [ -f "$CPU_ACTIVITY_OUTPUT_FILE" ]; then mv $CPU_ACTIVITY_OUTPUT_FILE ${OLD_LOGS_DIR}/${CPU_ACTIVITY_OUTPUT_FILE}_`date +%s` || true; fi

# As we start this client, we need to make sure we remove the "completeness signal"
SIGNAL=${REQUESTOR_VOLUME}/${REQUESTOR_WORK_COMPLETE_SIGNAL}
if [ -f "$SIGNAL" ]; then sudo rm $SIGNAL; fi

for RUNTIME in $LIST_OF_SERVERS; do
	for TEST in $LIST_OF_TEST_TYPES; do
		echo_my "****** Starting new round of tests: RUNTIME=$RUNTIME, TEST=$TEST"
		stop_mq_clients || true
		remove_mq_clients || true
		stop_mq_servers || true
		remove_mq_servers || true
		echo_my "Starting servers..."
		run_mq_servers
		wait4QMstart
		echo_my "Starting clients..."
		run_mq_clients $RUNTIME $TEST
		start_activity_recording
		wait4requestors
		# Copy the results from many containers into a single file to avoid them being removed when containers are cleaned.
		# Obviously all client containers must be local to the machine where this script is run.
		# It is not likely that  distributed multi-machine client setup is needed for a single machine MQ tests.
		cat ${REQUESTOR_VOLUME}/${RESULTS_NAME} >> $GLOBAL_RESULTS_FILE
	done  
done

stop_activity_recording
echo "****************************************************************************"
echo "   Success: '$BASH_SOURCE' script is complete."
echo "   Test results can be found in ${REQUESTOR_VOLUME}/${RESULTS_NAME}"
echo "****************************************************************************"
