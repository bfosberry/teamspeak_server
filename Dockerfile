FROM ubuntu
MAINTAINER Fozz

RUN apt-get -y install wget curl

ENV USERNAME admin
RUN adduser --gecos "" $USERNAME

RUN wget -q http://dl.4players.de/ts/releases/3.0.10.3/teamspeak3-server_linux-amd64-3.0.10.3.tar.gz
RUN tar -xzf teamspeak3-server_linux-amd64-3.0.10.3.tar.gz
RUN rm teamspeak3-server_linux-amd64-3.0.10.3.tar.gz
RUN mv teamspeak3-server_linux-amd64 /opt/teamspeak3-server

RUN mkdir -p /opt/data/state
RUN mkdir -p /opt/data/logs
RUN touch /opt/data/state/ts3server.sqlitedb
RUN ln -s /opt/data/logs /opt/teamspeak3-server/logs
RUN ln -s /opt/data/state/ts3server.sqlitedb /opt/teamspeak3-server/ts3server.sqlitedb

RUN wget https://github.com/coreos/etcd/releases/download/v0.3.0/etcd-v0.3.0-linux-amd64.tar.gz
RUN tar -xzf etcd-v0.3.0-linux-amd64.tar.gz
RUN mv etcd-v0.3.0-linux-amd64 /opt/etcd

EXPOSE 9987/udp
EXPOSE 10011
EXPOSE 30033

ADD ./run.sh /opt/run.sh

ENTRYPOINT ["/opt/run.sh"]
