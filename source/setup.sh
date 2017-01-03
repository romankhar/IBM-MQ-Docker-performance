#!/bin/bash
#
# DESCRIPTION:
#	This script needs to be run once to prepare the host computer for tests. It is not necessar to run it again after reboots
#
# AUTHOR:   	
# 	Roman Kharkovski (http://advantage.ibm.com/about)

set -o nounset
set -o errexit

source setenv.sh
source mq/client/setenv_client.sh
source mq/build.sh

# Turn off Ubuntu firewall
sudo ufw disable
sudo ufw status

# Build reference image for the base MQ server - all specific images will be using this as a reference
build_vanilla_server