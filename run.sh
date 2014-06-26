#!/bin/bash
# @author bfosberry
# run.sh is a wrapper for the teamspeak server docker container
# It does the following things: 
# 1) Writes any config needed from etcd into the container
# 2) Starts the container in the background
# 3) Extracts the admin token and reports it to etcd
# 4) Reports it status periodically to etcd (running/stopped)
# 5) Watches for light-restart events and restarts the app
# Required HOST_ID, first arg should be SERVER_ID

if [ -z "$ETCD_SERVER" ]; then
  ETCD_SERVER="$ETCD_1_PORT_4001_TCP_ADDR:$ETCD_1_PORT_4001_TCP_PORT"
fi

DIR=/opt/teamspeak3-server
SERVER_ID=$1
PORT=9987
SLEEP_INTERVAL=5
ETCDCTL_COMMAND="/opt/etcd/etcdctl --no-sync --peers $ETCD_SERVER"
DATA_FOLDER="/opt/data/"

function report_error {
  echo "Error: $1"
  $ETCDCTL_COMMAND set "$SERVER_ID/info/status" "errored"
  $ETCDCTL_COMMAND set "$SERVER_ID/info/error" "$1"
}

function set_info_value {
  $ETCDCTL_COMMAND set "$SERVER_ID/info/$1" "$2"
}

function get_info_value {
  VALUE=`$ETCDCTL_COMMAND get $SERVER_ID/info/$1`
}

function clear_server {
  $ETCDCTL_COMMAND rm --recursive $SERVER_ID
}

function clear_logs {
  rm -rf $DATA_FOLDER/logs/*
}

function clear_state {
  rm -rf $DATA_FOLDER/state/*
}

function get_action {
  error_regex="Key not found"
  ACTION_KEY="`$ETCDCTL_COMMAND ls /$SERVER_ID/actions | head -n 1`"
  if [[ ! "$ACTION_KEY" =~ $error_regex  ]] && [[ ! "$ACTION_KEY" == "" ]]; then
    ACTION_VALUE=`$ETCDCTL_COMMAND get $ACTION_KEY`
    $ETCDCTL_COMMAND rm $ACTION_KEY
  fi
}

function initialize_data_folder {
    mkdir -p "$DATA_FOLDER/state"
    mkdir -p "$DATA_FOLDER/logs"
    if [ ! -f "$DATA_FOLDER/state/ts3server.sqlitedb" ]; then
      touch "$DATA_FOLDER/state/ts3server.sqlitedb"
    fi
}

function parse_token {
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
}

function check_data {
  error_regex="Key not found"
  if [ "$1" == "" ] || [[ "$1" =~ $error_regex ]]; then
    parse_token
  fi
}

if [ -z $SERVER_ID ]; then
  echo "No Server Id provided"
  exit 1
fi

initialize_data_folder

# Write Config
# The etcd host is available via the ETCD_SERVER env variable
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

get_info_value "admin_token"
TOKEN="$VALUE"

get_info_value "username"
USERNAME="$VALUE"

get_info_value "password"
PASSWORD="$VALUE"

check_data "$TOKEN"
check_data "$USERNAME"
check_data "$PASSWORD"

# Reporting status and waiting for changes
set_info_value "status" "running"
set_info_value "admin_token" "$TOKEN"
set_info_value "username" "$USERNAME"
set_info_value "password" "$PASSWORD"

while [ true ]; do
  sleep $SLEEP_INTERVAL

  #could also use the status flag to startscript here
  if [ -z "`netstat -l | grep $PORT`" ]; then
    echo "Server is down"
    set_info_value "status" "stopped" $TOKEN $USERNAME $PASSWORD
    exit 1    
  fi

  get_action
  if [ "$ACTION_KEY" == "/$SERVER_ID/actions/restart" ]; then
    echo "Performing restart"
    set_info_value "status" "restarting"
    $DIR/ts3server_startscript.sh stop
    $DIR/ts3server_startscript.sh start &>> $DIR/logs/stderr.log
    set_info_value "status" "running" 
  elif [ "$ACTION_KEY" == "/$SERVER_ID/actions/reset" ]; then
    echo "Performing reset"
    set_info_value "status" "resetting"
    $DIR/ts3server_startscript.sh stop
    clear_server
    clear_logs
    clear_state
    initialize_data_folder
    $DIR/ts3server_startscript.sh start &>> $DIR/logs/stderr.log
    parse_token
    set_info_value "admin_token" "$TOKEN"
    set_info_value "username" "$USERNAME"
    set_info_value "password" "$PASSWORD"
    set_info_value "status" "running"
  elif [ "$ACTION_KEY" == "/$SERVER_ID/actions/delete_logs" ]; then
    echo "Deleting logs"
    clear_logs
  elif [ "$ACTION_KEY" == "/$SERVER_ID/actions/halt" ]; then
    echo "Cleaning up"
    $DIR/ts3server_startscript.sh stop
    clear_server
    exit 0
  fi
done
