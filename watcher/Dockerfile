# Teamspeak 3 Server watcher
#
# VERSION 0.1

FROM bfosberry/gamekick_base
MAINTAINER bfosberry

# install etcdctl
RUN wget -O /tmp/etcd.tar.gz https://github.com/coreos/etcd/releases/download/v0.4.6/etcd-v0.4.6-linux-amd64.tar.gz
RUN tar -xzf /tmp/etcd.tar.gz -C /opt && mv /opt/etcd-v0.4.6-linux-amd64 /opt/etcd

VOLUME /opt/data

ADD watch.sh /opt/watch.sh
ENTRYPOINT ["/opt/watch.sh"]
