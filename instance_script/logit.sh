#!/bin/sh
function log() {
   LOGFILE=/var/log/kops.log
   DATE=`date "+%b %d %H:%M:%S"`
   echo "$DATE $1" >> $LOGFILE
}
