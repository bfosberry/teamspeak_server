#!/bin/bash
# @author bfosberry
# run.sh is a wrapper for the teamspeak server docker container
# It does the following things: 
# 1) Writes any config needed from etcd into the container
# 2) Starts the container in the background
# 3) Extracts the admin token and reports it to etcd
# 4) Reports it status periodically to etcd (running/stopped)
# 5) Watches for light-restart events and restarts the app
# Required MACHINE_ID and HOST_ID, first arg should be SERVER_ID

DIR=/opt/teamspeak3-server
SERVER_ID=$1
PORT=9987
SLEEP_INTERVAL=5
ETCDCTL_COMMAND="/opt/etcd/etcdctl -peers $HOST_IP:4001"
DATA_FOLDER="/opt/data/"

function report_error {
  echo "Error: $1"
  $ETCDCTL_COMMAND set "$SERVER_ID/info/status" "errored"
  $ETCDCTL_COMMAND set "$SERVER_ID/info/error" "$1"
}

function set_info_value {
  $ETCDCTL_COMMAND set "$SERVER_ID/info/$1" "$2"
}


function clear_server {
  $ETCDCTL_COMMAND rmdir $SERVER_ID
}

function get_action {
  ACTION=`$ETCDCTL_COMMAND get $SERVER_ID/action`
  $ETCDCTL_COMMAND rm $SERVER_ID/action
}

function initialize_data_folder {
    mkdir -p "$DATA_FOLDER/state"
    mkdir -p "$DATA_FOLDER/logs"
    if [ ! -f "$DATA_FOLDER/state/ts3server.sqlitedb" ]; then
      touch "$DATA_FOLDER/state/ts3server.sqlitedb"
    fi
}


if [ -z $SERVER_ID ]; then
  echo "No Server Id provided"
  exit 1
fi

initialize_data_folder

# Write Config
# The etcd host is available via the HOST_IP env variable
# Teamspeak configuration is does at runtime and so no steps are needed here

# Start Container
$DIR/ts3server_startscript.sh start &>> $DIR/logs/stderr.log

# Extract the admin token
ATTEMPTS=0
MAX_ATTEMPTS=10
while [ ! -e $DIR/logs/stderr.log ]; do
  echo "Waiting for stderr.log"
  sleep 1
done

while [ -z "`grep -R "token\=" $DIR/logs/stderr.log`" ]; do
  if [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; then 
    sleep 1
    #echo "Waiting for token, Attempt $ATTEMPTS"
    ATTEMPTS=$((ATTEMPTS+1))
  else 
    report_error "Unable to parse admin token"
    exit 1
  fi
done
TOKEN=`grep -R "token\=" $DIR/logs/stderr.log | sed 's/.*token\=\([^ ]*\).*/\1/'`
USERNAME=`grep -R "loginname\=" $DIR/logs/stderr.log | sed 's/.*loginname\=\ \"\([^ \,\"]*\).*/\1/'`
PASSWORD=`grep -R "password\=" $DIR/logs/stderr.log | sed 's/.*password\=\ \"\([^ \,\"]*\).*/\1/'`

# Reporting status and waiting for changes
set_info_value "status" "running"
set_info_value "admin_token" "$TOKEN"
set_info_value "username" "$USERNAME"
set_info_value "password" "$PASSWORD"
set_info_value "docker_id" "$HOSTNAME"

while [ true ]; do
  sleep $SLEEP_INTERVAL

  #could also use the status flag to startscript here
  if [ -z "`netstat -l | grep $PORT`" ]; then
    echo "Server is down"
    set_info_value "status" "stopped" $TOKEN $USERNAME $PASSWORD
    exit 1    
  fi

  get_action
  if [ "$ACTION" == "restart" ]; then
    echo "Performing restart"
    set_info_value "status" "restarting" $TOKEN $USERNAME $PASSWORD
    $DIR/ts3server_startscript.sh restart
    set_info_value "status" "running" $TOKEN $USERNAME $PASSWORD
  fi 
done
