#!/bin/bash

# DESCRIPTION: 	This script makes a backup copy of the project zipped with time stamp into a local backup directory
# AUTHOR:   	Roman Kharkovski (http://whywebsphere.com/)

source setenv.sh

SOURCE=${PROJECT_HOME}
DEST=/mnt/hgfs/projects/backup
if [ ! -d "$DEST" ]; then
	mkdir $DEST
fi

BACKUP_FILE=$DEST/backup_`date +%s`
echo_my "Making new backup of the '$SOURCE' into the '$BACKUP_FILE'..."
cp -r $SOURCE $BACKUP_FILE
echo_my "Backup complete. Content of the $DEST folder is listed below:"
dir -l -t $DEST