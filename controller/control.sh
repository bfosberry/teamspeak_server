#!/bin/bash
# @author bfosberry

ETCDCTL_COMMAND="/opt/etcd/etcdctl --no-sync --peers http://$ETCD_SERVER"
SLEEP_INTERVAL=5
DATA_DIR=/opt/data/

if [ -z $SERVER_ID ]; then
  echo "No Server Id provided"
  exit 1
fi

if [ -z $ETCD_SERVER ]; then
  echo "No Etcd Server provided provided"
  exit 1
fi

function delete_logs {
  rm -rf $DATA_DIR/logs/*
}

function delete_sqlite {
  rm -rf $DATA_DIR/state/*
}


function delete_state {
  delete_sqlite
}


#TODO fixme
if [ $1 == "decom" ]; then
	delete_logs
	delete_state
fi
