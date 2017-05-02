FROM jancajthaml/nginx:latest

MAINTAINER Jan Cajthaml <jan.cajthaml@gmail.com>

COPY opt/nginx.conf /etc/nginx/nginx.conf

RUN apk add --update perl git && \
    mkdir -p /var/cache/swagger-stable && \
    mkdir -p /etc/swagger && \
    touch /etc/swagger/swagger.json && \
    cd /var/cache/swagger-stable && \
    git clone https://github.com/swagger-api/swagger-ui.git --branch master --single-branch --depth=1 . && \
    mkdir -p /www && \
    cp -a dist/* /www && \
    cd /www && \
    ln -sv /etc/swagger/swagger.json swagger.json && \
    chmod +rX /etc/swagger && \
    chmod +rX -R /etc/swagger/swagger.json && \
    perl -pi -w -e 's!http://petstore.swagger.io/v2/swagger.json!/swagger.json!g;' /www/index.html && \
    apk del git perl

EXPOSE 8080

CMD nginx
