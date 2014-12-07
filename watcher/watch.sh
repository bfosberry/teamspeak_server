#!/bin/bash
# @author bfosberry

ETCDCTL_COMMAND="/opt/etcd/etcdctl --no-sync --peers http://$ETCD_SERVER"
SLEEP_INTERVAL=5
DATA_DIR=/opt/data/
TOKEN=""

if [ -z $SERVER_ID ]; then
  echo "No Server Id provided"
  exit 1
fi

if [ -z $ETCD_SERVER ]; then
  echo "No Etcd Server provided provided"
  exit 1
fi

function check_logs {
  PARSED_TOKEN=`grep -R -m 1 "token\=" $DATA_DIR/logs/stderr.log | sed 's/.*token\=\([^ ]*\).*/\1/'`
  PARSED_USERNAME=`grep -R -m 1 "loginname\=" $DATA_DIR/logs/stderr.log | sed 's/.*loginname\=\ \"\([^ \,\"]*\).*/\1/'`
  PARSED_PASSWORD=`grep -R -m 1 "password\=" $DATA_DIR/logs/stderr.log | sed 's/.*password\=\ \"\([^ \,\"]*\).*/\1/'`
}

function set_value {
  $ETCDCTL_COMMAND set "_$SERVER_ID/info/$1" "$2" > /dev/null
}

function do_exit {
  exit 1
}

trap do_exit SIGINT SIGTERM

while true; do
  check_logs

  if [ "$PARSED_TOKEN" != "$TOKEN" ]; then
    TOKEN=$PARSED_TOKEN
    set_value "admin_token" $TOKEN
  fi

  if [ "$PARSED_USERNAME" != "$USERNAME" ]; then
    USERNAME=$PARSED_USERNAME
    set_value "username" $USERNAME
  fi

  if [ "$PARSED_PASSWORD" != "$PASSWORD" ]; then
    PASSWORD=$PARSED_PASSWORD
    set_value "password" $PASSWORD
  fi
  
  sleep $SLEEP_INTERVAL
done
