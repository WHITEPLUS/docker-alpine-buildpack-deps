FROM alpine:3.4

MAINTAINER WHITEPLUS System "sysadmin@wh-plus.com"

RUN apk add --no-cache \
    # curl
    ca-certificates \
    curl \
    wget \
    # git
    git \
    openssh-client \
    procps \
    # slim
    autoconf \
    automake \
    bzip2 \
    bzip2-dev \
    curl-dev \
    db-dev \
    file \
    g++ \
    gcc \
    geoip-dev \
    glib-dev \
    imagemagick-dev \
    jpeg-dev \
    krb5-dev \
    libc-dev \
    libevent-dev \
    libffi-dev \
    libpng-dev \
    libtool \
    libwebp-dev \
    libxml2-dev \
    libxslt-dev \
    linux-headers \
    make \
    ncurses-dev \
    openssl-dev \
    patch \
    readline-dev \
    sqlite-dev \
    xz \
    xz-dev \
    yaml-dev \
    zlib-dev
