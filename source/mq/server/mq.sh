#!/bin/bash
# -*- mode: sh -*-
# © Copyright IBM Corporation 2015, 2016
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Some useful tips about error checking in bash found here: http://www.davidpashley.com/articles/writing-robust-shell-scripts/
# This prevents running the script if any of the variables have not been set
set -o nounset
# This automatically exits the script if any error occurs while running it
set -o errexit

source setenv_mq.sh

##############################################################################
# Tuning settings for our new QM
MQ_CONNECT_TYPE=FASTPATH
LOG_TYPE=CIRCULAR
LOG_TYPE_CRTMQM="-lc"
LOG_INTEGRITY=TripleWrite
# Set it to 100MB - when we have lots of memory
DefaultQBufferSize=104857600
DefaultPQBufferSize=104857600
MAX_MSG_SIZE=104857600
LOG_BUFFER_PAGES=4096
LOG_PRIMARY_FILES=40
# For performance reasons it is not recommended to use secondary log files as they are dynamically allocated (not pre-formatted)
LOG_SECONDARY_FILES=1
LOG_FILE_PAGES=65535
MAX_HANDLES=50000
MAX_DEPTH=50000
FDMAX=1048576
MAX_CHANNELS=5000

##############################################################################
# Stop running QM
##############################################################################
stopQM()
{
  endmqm $MQ_QMGR_NAME
}

##############################################################################
# Get the state of a QM
##############################################################################
state()
{
  dspmq -n -m ${MQ_QMGR_NAME} | awk -F '[()]' '{ print $4 }'
}

##############################################################################
# Run the loop to maintain running Docker container
##############################################################################
monitorQM()
{
  # Loop until "dspmq" says the queue manager is running
  until [ "`state`" == "RUNNING" ]; do
    sleep 1
  done
  dspmq

  # Loop until "dspmq" says the queue manager is not running any more
  until [ "`state`" != "RUNNING" ]; do
    sleep 5
  done

  # Wait until queue manager has ended before exiting
  while true; do
    STATE=`state`
    case "$STATE" in
      ENDED*) break;;
      *) ;;
    esac
    sleep 1
  done
  dspmq
}

#############################################
# Create QM.ini file
#
# Parameters
# 1 - Queue Manager temporary file name
#############################################
createQueueManagerIniFile() {
  echo "------> This function creates qm.ini file in local directory: $1"
  rm -f $1
  cat << EOF > $1
#*******************************************************************#
#* Module Name: qm.ini                                             *#
#* Type       : WebSphere MQ queue manager configuration file      *#
#* Function   : Define the configuration of a single queue manager *#
#*                                   *#
#*              This file was generated by 'functions.sh' script   *#
#*              Refer to http://whywebsphere.com for details       *#
#*******************************************************************#
ExitPath:
   ExitsDefaultPath=/var/mqm/exits
   ExitsDefaultPath64=/var/mqm/exits64
Log:
   LogPrimaryFiles=$LOG_PRIMARY_FILES
   LogSecondaryFiles=$LOG_SECONDARY_FILES
   LogFilePages=$LOG_FILE_PAGES
   LogType=$LOG_TYPE
   LogBufferPages=$LOG_BUFFER_PAGES
   LogPath=${MQ_LOG_DIR}/${MQ_QMGR_NAME}/
   LogWriteIntegrity=$LOG_INTEGRITY
Service:
   Name=AuthorizationService
   EntryPoints=14
ServiceComponent:
   Service=AuthorizationService
   Name=MQSeries.UNIX.auth.service
   Module=amqzfu
   ComponentDataSize=0
Channels:
   MQIBindType=$MQ_CONNECT_TYPE
   MaxActiveChannels=$MAX_CHANNELS
   MaxChannels=$MAX_CHANNELS
TuningParameters:
   DefaultPQBufferSize=$DefaultPQBufferSize
   DefaultQBufferSize=$DefaultQBufferSize
TCP:
   SndBuffSize=0
   RcvBuffSize=0
   RcvSndBuffSize=0
   RcvRcvBuffSize=0
   ClntSndBuffSize=0
   ClntRcvBuffSize=0
   SvrSndBuffSize=0
   SvrRcvBuffSize=0
EOF
   echo "<------ qm.ini is created"
}

#############################################
# Create QM if when Docker container starts for the first time
#############################################
configureQM() {
  # Populate and update the contents of /var/mqm - this is needed for
  # bind-mounted volumes, and also to migrate data from previous versions of MQ
  echo "--> createQM if need: ${MQ_QMGR_NAME}"
  /opt/mqm/bin/amqicdir -i -f
  ls -l /var/mqm
  source /opt/mqm/bin/setmqenv -s
  dspmqver

  QMGR_EXISTS=`dspmq | grep ${MQ_QMGR_NAME} > /dev/null ; echo $?`
  if [ ${QMGR_EXISTS} -ne 0 ]; then
    echo "Checking filesystem..."
    amqmfsck /var/mqm

    echo "---> Creating new queue manager: ${MQ_QMGR_NAME}"
    CREATE_COMMAND="crtmqm -q -u SYSTEM.DEAD.LETTER.QUEUE -h $MAX_HANDLES $LOG_TYPE_CRTMQM -ld ${MQ_LOG_DIR} -lf $LOG_FILE_PAGES -lp $LOG_PRIMARY_FILES -ls $LOG_SECONDARY_FILES -md ${MQ_DATA_DIR} ${MQ_QMGR_NAME}"

    echo $CREATE_COMMAND
    $CREATE_COMMAND

    echo "--- Reset default values for the queue manager: ${MQ_QMGR_NAME}"
    # what if we do not do this?
    strmqm -c ${MQ_QMGR_NAME}

    echo "--- Generating qm.ini file"
    INI_TMP=qm.ini.tmp
    createQueueManagerIniFile $INI_TMP

    echo "--- Copy new configuration"
    cp $INI_TMP ${MQ_DATA_DIR}/${MQ_QMGR_NAME}/qm.ini
    # remove needs to be done separately so that initial qm.ini permissions are preserved
    rm $INI_TMP

    echo "--- Starting queue manager: ${MQ_QMGR_NAME}"
    strmqm ${MQ_QMGR_NAME}

    if [ ${MQ_QMGR_CMDLEVEL+x} ]; then
      # Enables the specified command level, then stops the queue manager
      strmqm -e CMDLEVEL=${MQ_QMGR_CMDLEVEL} || true
    fi

  echo "--> Configure queue manager: ${MQ_QMGR_NAME}"
  ADMIN_CHANNEL='PASSWORD.SVRCONN'
  runmqsc ${MQ_QMGR_NAME} <<-EOF
    alter qmgr activrec(disabled)
    alter qmgr routerec(disabled)
    alter qmgr chad(enabled)
    alter qmgr maxmsgl($MAX_MSG_SIZE)
    alter qlocal(system.default.local.queue) maxmsgl($MAX_MSG_SIZE)
    alter qmodel(system.default.model.queue) maxmsgl($MAX_MSG_SIZE)
    define listener(L1) trptype(tcp) port(${MQ_INSIDE_PORT}) control(qmgr)
    start listener(L1)
    alter channel(system.def.svrconn) chltype(svrconn) sharecnv(1)
    define channel($ADMIN_CHANNEL) chltype(svrconn)
    alter qmgr chlauth(disabled)
EOF

    # alter channel(system.def.svrconn) chltype(svrconn) mcauser($PERFORMANCE_USER) maxmsgl($MAX_MSG_SIZE)
    # alter channel(system.def.svrconn) chltype(svrconn) mcauser($NON_ADMIN_USER) maxmsgl($MAX_MSG_SIZE)
    # SET CHLAUTH($ADMIN_CHANNEL) TYPE(BLOCKUSER) USERLIST('nobody') DESCR('Allow privileged users on this channel')
    # SET CHLAUTH('*') TYPE(ADDRESSMAP) ADDRESS('*') USERSRC(NOACCESS) DESCR('BackStop rule')
    # SET CHLAUTH($ADMIN_CHANNEL) TYPE(ADDRESSMAP) ADDRESS('*') USERSRC(CHANNEL) CHCKCLNT(REQUIRED)
    # ALTER AUTHINFO(SYSTEM.DEFAULT.AUTHINFO.IDPWOS) AUTHTYPE(IDPWOS) ADOPTCTX(YES)

    echo "--- Restart queue manager: ${MQ_QMGR_NAME}"
    endmqm -i ${MQ_QMGR_NAME}
    strmqm ${MQ_QMGR_NAME}

    echo "--- Create queues and other configuration as needed for performance testing purposes"
    runmqsc ${MQ_QMGR_NAME} < /etc/mqm/config.mqsc

    echo "<-- DONE - creation of queue manager went well: ${MQ_QMGR_NAME}"
  else
    echo "--> Start queue manager: ${MQ_QMGR_NAME}"
    strmqm ${MQ_QMGR_NAME}
    echo "<-- DONE - no creation was necessary as queue manager already exists: ${MQ_QMGR_NAME}"
  fi
}

##############################################################################
# MAIN
##############################################################################
: ${MQ_QMGR_NAME?"ERROR: You need to set the MQ_QMGR_NAME environment variable"}

mq-license-check.sh
configureQM
trap stopQM SIGTERM SIGINT
monitorQM
