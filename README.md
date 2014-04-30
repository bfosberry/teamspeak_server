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
## Running the container

It should be possible to run this container with the following commands

```
docker build -t teamspeak .
docker run -d -t teamspeak -e "HOST_IP=1.2.3.4" "$SERVER_ID"
```

This should start and maintain the teamspeak server, exiting if the teamspeak server dies.

