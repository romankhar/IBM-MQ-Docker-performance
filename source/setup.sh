#!/bin/bash
#
# DESCRIPTION:
#	This script needs to be run once to prepare the host computer for tests. It is not necessary to run it again after reboots. 
# All we do here is just build a base MQ Docker image for reuse in later stages of the project.
# You only need to run it again if you need to upgrade to a new version of MQ or fixpack. This is usually done handful a times per year.
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
