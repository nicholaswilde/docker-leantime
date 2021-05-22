# Base image version
FROM php:7.2-fpm-alpine as php

FROM alpine:3.13.5 as dl
ARG VERSION
ARG CHECKSUM
WORKDIR /app
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    curl=7.76.1-r0 && \
  echo "**** download leantime ****" && \
  curl -LJO "https://github.com/Leantime/leantime/releases/download/v${VERSION}/Leantime-V${VERSION}.tar.gz" && \
  echo "$CHECKSUM  Leantime-v${VERSION}.tar.gz" | sha256sum -c && \
  tar -zxvf "Leantime-v${VERSION}.tar.gz" --strip-components 1

FROM php as php-ext-mysqli
RUN docker-php-ext-install -j"$(nproc)" mysqli

FROM php as php-ext-pdo_mysql
RUN docker-php-ext-install -j"$(nproc)" pdo_mysql

FROM php as php-ext-exif
RUN docker-php-ext-install -j"$(nproc)" exif

FROM php as php-ext-pcntl
RUN docker-php-ext-install -j"$(nproc)" pcntl

FROM php as php-ext-pdo
RUN docker-php-ext-install -j"$(nproc)" pdo

FROM php as php-ext-bcmath
RUN docker-php-ext-install -j"$(nproc)" bcmath

FROM php as php-ext-gd
RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    libpng-dev=1.6.37-r1 \
    libjpeg-turbo-dev=2.1.0-r0 && \
  docker-php-ext-configure gd \
    --with-gd \
    --with-jpeg-dir=/usr/include/ \
    --with-png-dir=/usr/include/ && \
  docker-php-ext-install -j"$(nproc)" gd

FROM php as php-ext-mbstring
RUN docker-php-ext-install -j"$(nproc)" mbstring

FROM php
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="nicholaswilde"
ARG TZ
ENV TZ $(TZ)

COPY --from=php-ext-mysqli /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=php-ext-mysqli /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

COPY --from=php-ext-pdo_mysql /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=php-ext-pdo_mysql /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

COPY --from=php-ext-mbstring /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=php-ext-mbstring /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

COPY --from=php-ext-exif /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=php-ext-exif /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

COPY --from=php-ext-pcntl /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=php-ext-pcntl /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

COPY --from=php-ext-pdo /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=php-ext-pdo /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

COPY --from=php-ext-bcmath /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=php-ext-bcmath /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

COPY --from=php-ext-gd /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=php-ext-gd /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

WORKDIR /var/www/html
COPY --from=dl /app .
COPY ./entrypoint.sh /entrypoint.sh
COPY ./config/custom.ini /usr/local/etc/php/conf.d/custom.ini
COPY ./config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./config/app.conf  /etc/apache2/conf.d/app.conf
RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    mysql-client=10.4.18-r0 \
    freetype=2.10.4-r0 \
    libpng=1.6.37-r1 \
    libjpeg-turbo=2.1.0-r0 \
    freetype-dev=2.10.4-r0 \
    libpng-dev=1.6.37-r1 \
    libjpeg-turbo-dev=2.1.0-r0 \
    icu-libs=67.1-r0 \
    jpegoptim=1.4.6-r0 \
    optipng=0.7.7-r0 \
    pngquant=2.12.6-r0 \
    gifsicle=1.92-r0 \
    supervisor=4.2.0-r0 \
    apache2=2.4.46-r1 \
    apache2-ctl=2.4.46-r1 \
    apache2-proxy=2.4.46-r1 \
    tzdata=2021a-r0 && \
  echo "**** cleanup ****" && \
  rm -rf /tmp/* && \
  chown www-data -R . && \
  chmod +x /entrypoint.sh && \
  echo "**** configure supervisord ****" && \
  sed -i '/LoadModule rewrite_module/s/^#//g' /etc/apache2/httpd.conf && \
  sed -i 's#AllowOverride [Nn]one#AllowOverride All#' /etc/apache2/httpd.conf && \
  sed -i '$iLoadModule proxy_module modules/mod_proxy.so' /etc/apache2/httpd.conf && \
  mkdir -p "/sessions" && \
  chown www-data:www-data /sessions && \
  chmod 0777 /sessions

VOLUME [ "/sessions" ]
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 80 9000
