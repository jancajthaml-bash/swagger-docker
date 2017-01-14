FROM alpine:latest

MAINTAINER Jan Cajthaml <jan.cajthaml@gmail.com>

ENV S6_OVERLAY_VERSION v1.18.1.5
ENV GODNSMASQ_VERSION 1.0.7

RUN addgroup -S nginx && \
    adduser -S -G nginx nginx

RUN apk add --update libcap

RUN apk add --no-cache --virtual linux-headers && \
    apk add --no-cache --virtual tcl && \
    apk add --no-cache --virtual git && \
    apk add --no-cache --virtual perl && \
    apk add --no-cache --virtual curl && \
    apk add --no-cache --virtual make && \
    apk add --no-cache --virtual gcc && \
    apk add --no-cache --virtual g++

RUN curl -sSL https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz | tar xvfz - -C / && \
    curl -sSL https://github.com/janeczku/go-dnsmasq/releases/download/${GODNSMASQ_VERSION}/go-dnsmasq-min_linux-amd64 -o /bin/go-dnsmasq && \
    addgroup go-dnsmasq &&     adduser -D -g "" -s /bin/sh -G go-dnsmasq go-dnsmasq &&     setcap CAP_NET_BIND_SERVICE=+eip /bin/go-dnsmasq


ENV PCRE_VERSION 8.39

RUN mkdir -p /tmp/pcre-stable && \
    curl -sSL ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${PCRE_VERSION}.tar.gz | tar xvz --no-same-owner -C /tmp/pcre-stable --strip-components 1 -f - 

ENV NGINX_VERSION 1.10.2

RUN mkdir -p /tmp/nginx-stable && \
    curl -sSL http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar xvz --no-same-owner -C /tmp/nginx-stable --strip-components 1 -f - && \
    cd /tmp/nginx-stable && \
    ./configure \
    --sbin-path=/var/lib/nginx/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --user=nginx \
    --group=nginx \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --without-http_gzip_module \
    --with-pcre=/tmp/pcre-stable \
    --without-http_empty_gif_module && \
    make

RUN cd /tmp/nginx-stable && \
    make install && \
    rm -rf /tmp/nginx-stable && rm -rf /tmp/pcre-stable

RUN mkdir -p /tmp/swagger-stable && cd /tmp/swagger-stable && \
    git clone https://github.com/swagger-api/swagger-ui.git --branch master --single-branch --depth=1 . && mkdir -p /data && cp -a dist/* /data && \
    rm -rf /tmp/swagger-stable

RUN apk info

# Add the files
ADD etc /etc
ADD data /data
ADD usr /usr

# Remove comment to lower size
RUN a=$(sed -e '/^[[:space:]]*$/d' -e '/^[[:space:]]*#/d' /etc/nginx/nginx.conf);echo "$a" > /etc/nginx/nginx.conf

# Local to broadcast
RUN sed -i -e 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/nginx/nginx.conf

RUN mkdir -p /var/lib/nginx && \
    mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /data && \
    chown -R nginx:nginx /var/lib/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /usr/local/nginx

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# patch swagger file

RUN perl -pi -w -e 's!http://petstore.swagger.io/v2/swagger.json!http://localhost:8080/swagger.json!g;' /data/index.html

# cleanup
RUN apk del linux-headers && \
    apk del tcl && \
    apk del git && \
    apk del perl && \
    apk del curl && \
    apk del make && \
    apk del gcc && \
    apk del g++ && \
    rm -rf /var/cache/*

VOLUME ["/data"]

# Expose the ports for nginx
EXPOSE 8080

ENTRYPOINT ["/init"]
CMD []
