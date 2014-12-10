# Teamspeak 3 Server controller
#
# VERSION 0.1

FROM bfosberry/gamekick_base
MAINTAINER bfosberry

USER root
RUN apt-get update -y && apt-get install -y mysql-client

VOLUME /opt/data

ADD control.sh /opt/control.sh
ENTRYPOINT ["/opt/control.sh"]
