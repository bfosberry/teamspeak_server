# Teamspeak 3 Server watcher
#
# VERSION 0.1

FROM bfosberry/gamekick_base
MAINTAINER bfosberry

# install etcdctl
RUN wget https://github.com/coreos/etcd/releases/download/v0.4.6/etcd-v0.4.6-linux-amd64.tar.gz
RUN tar -xzf etcd-v0.4.6-linux-amd64.tar.gz
RUN mv etcd-v0.4.6-linux-amd64 /opt/etcd
RUN rm etcd-*.tar.gz

VOLUME /opt/data

ADD watch.sh /opt/watch.sh
ENTRYPOINT ["/opt/watch.sh"]
