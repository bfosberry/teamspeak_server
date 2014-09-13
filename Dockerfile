# Teamspeak 3 Server
#
# VERSION 0.1

FROM bfosberry/gamekick_base
MAINTAINER bfosberry

# install teamspeak
RUN wget -q http://dl.4players.de/ts/releases/3.0.10.3/teamspeak3-server_linux-amd64-3.0.10.3.tar.gz
RUN tar -xzf teamspeak3-server_linux-amd64-3.0.10.3.tar.gz
RUN rm teamspeak3-server_linux-amd64-3.0.10.3.tar.gz
RUN mv teamspeak3-server_linux-amd64 /opt/teamspeak3-server

# prep the data directory, this will get wiped when the volume is mounted
# however this step ensures the links are set up correctly
RUN mkdir -p /opt/data/state
RUN mkdir -p /opt/data/logs
RUN touch /opt/data/state/ts3server.sqlitedb
RUN ln -s /opt/data/logs /opt/teamspeak3-server/logs
RUN ln -s /opt/data/state/ts3server.sqlitedb /opt/teamspeak3-server/ts3server.sqlitedb

VOLUME /opt/data

ENV PATH /opt/teamspeak3-server/scripts/:/opt/scripts/:$PATH
ENV DATA_FOLDER /opt/data/

# expose the teamspeak ports
EXPOSE 9987/udp
EXPOSE 10011
EXPOSE 30033

# add the runner script
ADD ./scripts /opt/teamspeak3-server/scripts
