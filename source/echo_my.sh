#!/bin/bash
# DATE:		November 29, 2016
# AUTHOR:	Roman Kharkovski (http://advantage.ibm.com/about)

##########################
# Available logging levels
ECHO_NONE=0
ECHO_NO_PREFIX=1
ECHO_ERROR=2
ECHO_WARNING=3
ECHO_INFO=4
ECHO_DEBUG=5

##########################
# Default logging level at the start of the script that sources this function
ECHO_LEVEL=$ECHO_DEBUG

##############################################################################
# DESCRIPTION:	Replace standard ECHO function with custom output
# PARAMS:		1 - Text to show (mandatory)
# 				2 - Type of output (optional) - see codes above
##############################################################################
echo_my()
{
	local RED='\033[0;31m'
	local GREEN='\033[32m'
	local ORANGE='\033[33m'
	local NORMAL='\033[0m'
	local PREFIX="[`hostname`] "

	if [ $# -gt 1 ]; then
		local ECHO_REQUESTED=$2
	else
		local ECHO_REQUESTED=$ECHO_INFO
	fi

	if [ $ECHO_REQUESTED -gt $ECHO_LEVEL ]; then return; fi
	if [ $ECHO_REQUESTED = $ECHO_NONE ]; then return; fi
	if [ $ECHO_REQUESTED = $ECHO_ERROR ]; then PREFIX="${RED}[ERROR] ${PREFIX}"; fi
	if [ $ECHO_REQUESTED = $ECHO_WARNING ]; then PREFIX="${RED}[WARNING] ${PREFIX}"; fi
	if [ $ECHO_REQUESTED = $ECHO_INFO ]; then PREFIX="${GREEN}[INFO] ${PREFIX}"; fi
	if [ $ECHO_REQUESTED = $ECHO_DEBUG ]; then PREFIX="${ORANGE}[DEBUG] ${PREFIX}"; fi
	if [ $ECHO_REQUESTED = $ECHO_NO_PREFIX ]; then PREFIX="${GREEN}"; fi

	echo -e "${PREFIX}$1${NORMAL}"
}