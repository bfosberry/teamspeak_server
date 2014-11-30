# Teamspeak 3 Server
#
# VERSION 0.1

FROM bfosberry/gamekick_base
MAINTAINER bfosberry


# install teamspeak
ENV TS3_VERSION 3.0.11.1
RUN wget -q http://dl.4players.de/ts/releases/$TS3_VERSION/teamspeak3-server_linux-amd64-$TS3_VERSION.tar.gz
RUN tar -xzf teamspeak3-server_linux-amd64-$TS3_VERSION.tar.gz
RUN mv teamspeak3-server_linux-amd64 /opt/teamspeak3-server
#RUN rm teamspeak3-server_linux-amd64-$TS3_VERSION.tar.gz

# prep the data directory, this will get wiped when the volume is mounted
# however this step ensures the links are set up correctly
ENV PATH /opt/teamspeak3-server/scripts/:$PATH
RUN mkdir -p $DATA_FOLDER/state

WORKDIR /opt/teamspeak3-server

VOLUME /opt/data

# expose the teamspeak ports
EXPOSE 9987/udp
EXPOSE 10011
EXPOSE 30033

# add the runner script
ADD ./scripts /opt/teamspeak3-server/scripts
