teamspeak_server
================

A standard teamspeak docker server compatible with the gamekick project

## Compatibility

In order to be compatible, the container must do the following

* Take one single argument, the ID of the server
* The entrypoint should be blocking
* The entrypoint can configure the server through any means it wishes (chef, puppet, shell)
* It must pull in any configuration variables from etcd using etcdctl
* It must update etcd with any information it can acquire
* What configuration is pulled in and what information it can update is defined in metadata.json
* It must set the key $SERVER_ID/info/status to running|errored|stopped|restarting
* It must maintain cleanliness of its etcd data, through cleansing and ttl
* It must report errors/status changes under any form of server error
* It must initialize its /opt/data folder with the correct structure and content

## Configuration

This teamspeak server takes no configuration parameters, however, as with all containers
it requires the HOST_IP to be provided so it can access etcd

## Info

This teamspeak server provides the following info:
* username
* password
* admin_token

along with the standard info which is always available:
* error
* status
* docker_id

## Actions

Setting $SERVER_ID/actions = "restart" will perform a soft restart of the teamspeak server. 
Once the teamspeak server restart message has begin, the action is deleted from etcd. 

## Ports

This container exposes 3 ports as required for teamspeak. These ports will not be mapped one
for one on the host. 

## Volumes

The container will have a specific data folder mounted to /opt/data

It is the responsibility of the run script to initialize this directory with the
following subfolders:
* logs # contains log files persisted between runs
* state # maintains application state between runs, used for dbs file dumps

In the case of the teamspeak server, it initializes a blank sqlite db for the teamspeak
application to use via a symlink. 

## Running the container

It should be possible to run this container with the following commands

```
docker build -t teamspeak .
docker run -d -t teamspeak -e "HOST_IP=1.2.3.4" -v /opt/data "$SERVER_ID"
```

A vagrant box with coreos is provided. To get started locally run
```
$ vagrant up #or if it is already up and you have made a change, vagrant provision
core$ docker build -t teamspeak .
core$ docker run -d -t -v "/data/$SERVER_ID:/opt/data" -e "HOST_IP=1.2.3.4" -t teamspeak $SERVER_ID
core$ etcdtl get $SERVER_ID/info/status
running
core$ etcdtl get $SERVER_ID/info/password
d73vcke93
core$ etcdtl set $SERVER_ID/action restart
restart
core$ etcdtl get $SERVER_ID/info/status
restarting
core$ etcdtl get $SERVER_ID/info/status
running
core$ docker ps
0bedba960a38        teamspeak:latest    /opt/run.sh 2       13 seconds ago      Up 13 seconds       9987/udp, 10011/tcp, 30033/tcp   hopeful_newton
core$ docker stop 0bedb
core$ docker rm 0bedb
```

This should start and maintain the teamspeak server, exiting if the teamspeak server dies.

In a production environment this will be wrapped in a systemd file which dynamically sets
the host ip, maps ports based on availability and mounts a private data folder.


