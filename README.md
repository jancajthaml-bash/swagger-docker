Dockerized swagger.ui dashboard

## Stack

Bundled Swagger UI [https://github.com/swagger-api/swagger-ui](http://nginx.org/download) served by [Nginx](http://nginx.org) running on top of lightweight [Alphine Linux](https://alpinelinux.org).

## Usage

```
docker run --rm -it --log-driver none \
       -p 8080:8080 \
       -v $(pwd)/opt/swagger.json:/etc/swagger/swagger.json \
       jancajthaml/swagger:latest nginx
```