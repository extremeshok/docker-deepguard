FROM extremeshok/baseimage-alpine:latest AS BUILD

LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"

RUN \
  echo "**** install bash runtime packages ****" \
  && apk-install \
    bash \
    ca-certificates \
    coreutils \
    curl \
    file \
    graphicsmagick \
    inotify-tools \
    netcat-openbsd

# add local files
COPY rootfs/ /

RUN \
  echo "**** configure ****" \
  && chmod 777 /xshok-deepguard.sh

WORKDIR /data

ENTRYPOINT ["/init"]
