FROM debian:jessie
MAINTAINER David Personette <dperson@dperson.com>

RUN (addgroup --gid=1000 nick)
RUN (adduser --system --uid=1000 --gid=1000 \
        --home /home/nick --shell /bin/bash nick)

# Install transmission
RUN export DEBIAN_FRONTEND='noninteractive' && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends transmission-daemon curl \
                $(apt-get -s dist-upgrade|awk '/^Inst.*ecurity/ {print $2}') &&\
    apt-get clean && \
    usermod -d /var/lib/transmission-daemon nick && \
    [ -d /var/lib/transmission-daemon/downloads ] || \
                mkdir -p /var/lib/transmission-daemon/downloads && \
    [ -d /var/lib/transmission-daemon/incomplete ] || \
                mkdir -p /var/lib/transmission-daemon/incomplete && \
    [ -d /var/lib/transmission-daemon/info/blocklists ] || \
                mkdir -p /var/lib/transmission-daemon/info/blocklists && \
    chown -Rh nick. /var/lib/transmission-daemon && \
    rm -rf /var/lib/apt/lists/* /tmp/*


COPY transmission.sh /usr/bin/

VOLUME ["/var/lib/transmission-daemon"]

EXPOSE 9091 51413/tcp 51413/udp

ENTRYPOINT ["transmission.sh"]
