FROM alpine:3.4

#
# PHP
#
ENV PHP_INI_DIR /usr/local/etc/php
ENV PHP_VERSION 5.6.26
ENV PHP_FILENAME php-5.6.26.tar.xz
ENV PHP_SHA256 203a854f0f243cb2810d1c832bc871ff133eccdf1ff69d32846f93bc1bef58a8
ENV PHP_GPG_KEYS \
    0BD78B5F97500D450838F95DFE857D9A90D90EC1 \
    6E4F6AB321FDC07F2C332E3AC2BF0BC433CFC8B3
COPY docker-php-source /usr/local/bin/
COPY docker-php-ext-* /usr/local/bin/
RUN apk add --no-cache --virtual .persistent-deps \
    ca-certificates \
    curl \
    tar \
    xz \
  # ensure www-data user exists
 && set -x \
 && addgroup -g 82 -S www-data \
 && adduser -u 82 -D -S -G www-data www-data \
# 82 is the standard uid/gid for "www-data" in Alpine
# http://git.alpinelinux.org/cgit/aports/tree/main/apache2/apache2.pre-install?h=v3.3.2
# http://git.alpinelinux.org/cgit/aports/tree/main/lighttpd/lighttpd.pre-install?h=v3.3.2
# http://git.alpinelinux.org/cgit/aports/tree/main/nginx-initscripts/nginx-initscripts.pre-install?h=v3.3.2
 && mkdir -p $PHP_INI_DIR/conf.d \
 && set -xe \
 && apk add --no-cache --virtual .fetch-deps \
    gnupg \
 && mkdir -p /usr/src \
 && cd /usr/src \
 && curl -fSL "https://secure.php.net/get/$PHP_FILENAME/from/this/mirror" -o php.tar.xz \
 && echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c - \
 && curl -fSL "https://secure.php.net/get/$PHP_FILENAME.asc/from/this/mirror" -o php.tar.xz.asc \
 && export GNUPGHOME="$(mktemp -d)" \
 && for key in $PHP_GPG_KEYS; do gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; done \
 && gpg --batch --verify php.tar.xz.asc php.tar.xz \
 && rm -r "$GNUPGHOME" \
 && apk del .fetch-deps \
 && apk add --no-cache --virtual .build-deps \
    autoconf \
    file \
    g++ \
    gcc \
    libc-dev \
    make \
    pkgconf \
    re2c \
    curl-dev \
    libedit-dev \
    libxml2-dev \
    openssl-dev \
    sqlite-dev \
 && docker-php-source extract \
 && cd /usr/src/php \
 && ./configure \
    --with-config-file-path="$PHP_INI_DIR" \
    --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
    --disable-cgi --enable-mbstring --enable-mysqlnd --with-curl \
    --with-libedit --with-openssl --with-zlib \
    $PHP_EXTRA_CONFIGURE_ARGS \
 && make -j"$(getconf _NPROCESSORS_ONLN)" \
 && make install \
 && { find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; } \
 && make clean \
 && docker-php-source delete \
 && runDeps="$(scanelf --needed --nobanner --recursive /usr/local \
| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | sort -u \
| xargs -r apk info --installed | sort -u)" \
 && apk add --no-cache --virtual .php-rundeps $runDeps \
 && apk del .build-deps


#
# Node.js
#
ENV NODE_VERSION=v6.7.0 NPM_VERSION=3
ENV NODE_CONFIG_FLAGS="--without-npm" RM_DIRS=/usr/include
RUN apk add --no-cache --virtual .persistent-deps \
    libgcc \
    libstdc++ \
 && apk add --no-cache --virtual .build-deps \
    curl \
    make \
    gcc \
    g++ \
    python \
    linux-headers \
    paxctl \
    gnupg \
 && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
 && curl -o node-${NODE_VERSION}.tar.gz -sSL https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}.tar.gz \
 && curl -o SHASUMS256.txt.asc -sSL https://nodejs.org/dist/${NODE_VERSION}/SHASUMS256.txt.asc \
 && gpg --verify SHASUMS256.txt.asc \
 && grep node-${NODE_VERSION}.tar.gz SHASUMS256.txt.asc | sha256sum -c - \
 && tar -zxf node-${NODE_VERSION}.tar.gz \
 && cd node-${NODE_VERSION} \
 && export GYP_DEFINES="linux_use_gold_flags=0" \
 && ./configure --prefix=/usr ${NODE_CONFIG_FLAGS} \
 && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
 && make -j${NPROC} -C out mksnapshot BUILDTYPE=Release \
 && paxctl -cm out/Release/mksnapshot \
 && make -j${NPROC} \
 && make install \
 && paxctl -cm /usr/bin/node \
 && cd / \
 && if [ -x /usr/bin/npm ]; then \
      npm install -g npm@${NPM_VERSION} && find /usr/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
    fi \
 && apk del .build-deps \
 && rm -rf \
    /etc/ssl \
    /node-${NODE_VERSION}.tar.gz \
    /SHASUMS256.txt.asc \
    /node-${NODE_VERSION} \
    ${RM_DIRS} \
    /usr/share/man \
    /tmp/* \
    /var/cache/apk/* \
    /root/.npm \
    /root/.node-gyp \
    /root/.gnupg \
    /usr/lib/node_modules/npm/man \
    /usr/lib/node_modules/npm/doc \
    /usr/lib/node_modules/npm/html


#
# Golang
#
ENV GOLANG_VERSION 1.7.1
ENV GOLANG_SRC_URL https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz
ENV GOLANG_SRC_SHA256 2b843f133b81b7995f26d0cb64bbdbb9d0704b90c44df45f844d28881ad442d3
COPY no-pic.patch /
RUN set -xe \
 && apk add --no-cache --virtual .build-deps \
    bash \
    gcc \
    musl-dev \
    openssl \
    go \
 && export GOROOT_BOOTSTRAP="$(go env GOROOT)" \
 && wget -q "$GOLANG_SRC_URL" -O golang.tar.gz \
 && echo "$GOLANG_SRC_SHA256 golang.tar.gz" | sha256sum -c - \
 && tar -C /usr/local -xzf golang.tar.gz \
 && rm golang.tar.gz \
 && cd /usr/local/go/src \
 && patch -p2 -i /no-pic.patch \
 && ./make.bash \
 && rm -rf /*.patch \
 && apk del .build-deps

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH
