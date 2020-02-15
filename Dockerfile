# Dockerfile for Deploying the Janus WebRTC Server
# https://janus.conf.meetecho.com/
# https://github.com/meetecho/janus-gateway/
#
# The Janus project recommends to reverse-proxy traffic through a
# webserver, so we start with the latest Debian-stable image for NGINX.
#
# USAGE:
# docker build -t janus . && docker run --rm -it -p 8088:80 -v $(pwd)/my-demos:/opt/my-demos janus:latest

FROM nginx:stable

ARG JANUS="0.8.2"
ARG SRTP="2.3.0"
ARG LIBWEBSOCKET="3.2.2"
ARG COTURN="4.5.1.1"

WORKDIR /opt

# Dependencies needed for compiling Janus from source
RUN apt-get update && \
        apt-get install -y --no-install-recommends \
        ca-certificates \
        libmicrohttpd-dev \
        libjansson-dev \
        libnice-dev \
        libssl-dev \
        libsofia-sip-ua-dev \
        libglib2.0-dev \
        libopus-dev \
        libogg-dev \
        libcurl4-openssl-dev \
        liblua5.3-dev \
        libconfig-dev\
        pkg-config \
        gengetopt \
        libtool \
        make \
        cmake \
        automake \
        git \
        wget \
        lsof \
        locate \
        curl

RUN wget "https://github.com/cisco/libsrtp/archive/v${SRTP}.tar.gz" && \
        tar xfv "v${SRTP}.tar.gz" && \
        cd "libsrtp-${SRTP}" && \
        ./configure --prefix=/usr --enable-openssl && \
        make shared_library && make install

# Websockets:
# compile janus with the following flags for websocket support:
# --enable-websockets, --enable-websockets-event-handler
#
# RUN wget "https://github.com/warmcat/libwebsockets/archive/v${LIBWEBSOCKET}.tar.gz" && \
#     tar xzvf "v${LIBWEBSOCKET}.tar.gz" && \
#     cd "libwebsockets-${LIBWEBSOCKET}" && \
#     mkdir build && \
#     cd build && \
#     cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" -DLWS_MAX_SMP=1 -DLWS_IPV6="ON" .. && \
#     make && make install

# STUN / TURN
#
# RUN wget "https://github.com/coturn/coturn/archive/${COTURN}.tar.gz" && \
#     tar xzvf "${COTURN}.tar.gz" && \
#     cd "coturn-${COTURN}" && \
#     ./configure && \
#     make && make install


RUN wget "https://github.com/meetecho/janus-gateway/archive/v${JANUS}.tar.gz" && \
        tar xzvf "v${JANUS}.tar.gz"

RUN cd "janus-gateway-${JANUS}" && \
        sh autogen.sh &&  \
        ./configure \
        --prefix=/opt/janus \
        --libdir=/usr/lib64 \
        --disable-docs \
        --disable-all-plugins \
        --disable-all-transports \
        --disable-all-handlers \
        --enable-libsrtp2 \
        --enable-rest \
        --enable-plugin-videoroom \
        --enable-sample-event-handler \
        && make && make install && make configs && ldconfig

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD nginx && ./janus/bin/janus -e
