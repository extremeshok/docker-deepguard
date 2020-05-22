FROM extremeshok/baseimage-ubuntu:latest AS BUILD

LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"

RUN echo "**** install bash runtime packages ****" \
  && apt-install \
    bash \
    ca-certificates \
    curl \
    file \
    graphicsmagick \
    gsfonts \
    inotify-tools \
    jq \
    netcat

# add local files
COPY rootfs/ /

RUN echo "**** create dirs ****" \
  && mkdir -p /data/input \
  && mkdir -p /data/output \
  && mkdir -p /data/backup

RUN echo "**** configure ****" \
  && chmod 777 /xshok-deepguard.sh

WORKDIR /data

ENTRYPOINT ["/init"]
