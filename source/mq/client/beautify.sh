#!/bin/bash
#
# DESCRIPTION:
#	This script parses test result log file and combines values of parallel runs into a single number (to avoid the use of XLS)
# AUTHOR:   
#	Roman Kharkovski (http://whywebsphere.com/resources-links)

cd ${EXEC_DIR}
source setenv.sh
source setenv_client.sh

set -o nounset
set -o errexit

echo_my "--> '$BASH_SOURCE' -->" $ECHO_DEBUG

INPUT_FILE=$RESULTS_FILE
OUTPUT_FILE=run_all.beautified.log

PREFIX=MessagingPerformance
DELIMITER="_"

echo_my "Starting parsing of the input file '$INPUT_FILE'..."
HEADER_LINES=10
LAST_LINE="<-------"
THREADS_POSITION=7
SERVER_TYPE_POSITION=11
PERSISTENCE_TYPE_POSITION=12
MSG_SIZE_POSITION=13
TPS_PERFORMANCE_POSITION=14

# load aggregate numbers for each of the above
declare -a lines=($(cat $INPUT_FILE | tr '\n' ' '))

# Here is an example of the log file:
#FinishTime 	RunSecs 	Threads 	Qs 	Corr 	OpsMode 	Vendor 	TestType 	MsgSize 	MsgRatePerSecond
#Wed Jan 28 14:17:34 PST 2015 	180 	30 	20 	false 	Requestor 	WMQ 	Persistent 	01_256.xml 	2654.52

i=0
# row cursor will be set to 0 for every line in the input report
row_cursor=0
# as we keep parsing the input row from log file, we will be forming this variable dynamically - later converting it into ENV variable
dynamic_variable=""

for line in ${lines[@]}
do
	i=$[i+1]
	if [ $i -lt $[HEADER_LINES+1] ]; then 
		# skip first few lines that are headers of the log file (first row)
		continue
	fi
	if [ $line = $LAST_LINE ]; then
		# once we get to the start of last line we can complete the processing
		break
	fi

	#echo line_value "$line"
	
	# reset cursor after we are done with one complete input row
	if [ $row_cursor = $[TPS_PERFORMANCE_POSITION+1] ]; then
		# since we have finished one row of input log file, need to reset cursor and variable
		row_cursor=0
	fi
	
#	if [ $row_cursor = $[THREADS_POSITION] ]; then
		# because this is the first value in the input row - we are adding PREFIX first thus initializing dynamic variable
		# TODO: let me skip the threads value - ignore it for now
		#dynamic_variable=${PREFIX}${DELIMITER}$line
#	fi
	
	if [ $row_cursor = $[SERVER_TYPE_POSITION] ]; then
		dynamic_variable=${PREFIX}${DELIMITER}$line
	fi
	
	if [ $row_cursor = $[PERSISTENCE_TYPE_POSITION] ]; then
		dynamic_variable=${dynamic_variable}${DELIMITER}$line
	fi
	
	if [ $row_cursor = $[MSG_SIZE_POSITION] ]; then
		# this is bad i know, but I am in a hurry :-)
		# trimming file index upfront
#		trim_front=${line:(3)}
		trim_front=${line}
		# trimming ".xml" from the end
		trim_back=${trim_front%?}
		trim_back=${trim_back%?}
		trim_back=${trim_back%?}
		trim_back=${trim_back%?}
		dynamic_variable=${dynamic_variable}${DELIMITER}${trim_back}
	fi
	
	if [ $row_cursor = $[TPS_PERFORMANCE_POSITION] ]; then
		
		# trim return symbol
		line=${line%?}
		set +u
		if [ -z ${!dynamic_variable} ]; then
			declare "$dynamic_variable"=0
		fi
		set -u
		declare "$dynamic_variable"=`echo ${!dynamic_variable}+$line|bc`
		#echo "$dynamic_variable ${!dynamic_variable}"
	fi
	
	#echo row_cursor="$row_cursor"
	row_cursor=$[row_cursor+1]
done

# Now print all this stuff
echo "Aggregated performance results:" > $OUTPUT_FILE

echo "----------------------------------------------" >> $OUTPUT_FILE
echo "Same info as below for copy&paste into sheets:" >> $OUTPUT_FILE
echo "----------------------------------------------" >> $OUTPUT_FILE
for var in ${!MessagingPerformance*}; do  
	# must adjust for the number of repetitions of the test
	echo -e "`echo ${!var}/$REPEATS|bc`" >> $OUTPUT_FILE
done

echo "-----------------------------------------" >> $OUTPUT_FILE
echo "Same info as above for visual inspection:" >> $OUTPUT_FILE
echo "-----------------------------------------" >> $OUTPUT_FILE
for var in ${!MessagingPerformance*}; do  
	# must adjust for the number of repetitions of the test
	echo -e "$var \t`echo ${!var}/$REPEATS|bc`" >> $OUTPUT_FILE
done

cat $OUTPUT_FILE
echo_my "<-- '$BASH_SOURCE' <--" $ECHO_DEBUG