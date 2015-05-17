teamspeak_server
================

[![Deploy to Tutum](https://s.tutum.co/deploy-to-tutum.svg)](https://dashboard.tutum.co/stack/deploy/)

A standard teamspeak docker server compatible with the gamekick project

## Compatibility

In order to be compatible, the container must do the following

* Have the SERVER_ID environment variable with an ID
* No entrypoint defined
* MUST have a run script, to start the application in the foreground
* It can provide an optional "write_config" script to apply the provided configuration to the game server config files
* It can provide an optional "install_components" script to install additional components at runtime

## Configuration

This teamspeak server takes no configuration parameters, however, as with all containers
it requires the ETCD_SERVER (e.g. 1.2.3.4:4001) to be provided so it can access communicate. It also required "SERVER_ID" to it can namespace info and actions correctly.

## Info

This teamspeak server writes the following info to the logs and stdout:
* username
* password
* admin_token

This data can be collected into etcd using the watcher container in /watcher. This should be run as a separate container and will update etcd /_$SERVER_ID/info/key with the relevant value as it changes (every 5 seconds)

## Ports

This container exposes 3 ports as required for teamspeak. These ports will not be mapped directly one on the host.

## Volumes

The container will have a specific data folder mounted to /opt/data

It is the responsibility of the run script to initialize this directory with the
following subfolders:
* logs - contains log files persisted between runs
* state - maintains application state between runs, used for dbs file dumps

In the case of the teamspeak server, it initializes a blank sqlite db for the teamspeak application to use via a symlink. 

## Running the container

It should be possible to run this container with the following commands

```
docker build -t teamspeak .
docker run -d -t teamspeak -e "ETCD_SERVER=1.2.3.4:4001" -e "SERVER_ID=$SERVER_ID" -v /opt/data
```

A vagrant box with coreos is provided. To get started locally run
```
$ vagrant up #or if it is already up and you have made a change, vagrant provision
core$ docker build -t teamspeak .
core$ docker run -d -t -v "/data/$SERVER_ID:/opt/data" -e "ETCD_SERVER=1.2.3.4:4001" -e "SERVER_ID=$SERVER_ID" -t teamspeak
core$ docker ps
0bedba960a38        teamspeak:latest    /opt/run.sh 2       13 seconds ago      Up 13 seconds       9987/udp, 10011/tcp, 30033/tcp   hopeful_newton
core$ docker stop 0bedb
core$ docker rm 0bedb
```

This should start and maintain the teamspeak server, exiting if the teamspeak server dies.

The controller container should be run alongside when other actions are needed it supports only decomissioning. This will delete the relevant datastore as defined in the configuration, as well as the logs. This should be run after a container and it's data wish to be destroyed, or when a datastore is being moved (migrating to/from mysql).
