FROM php:7.2-fpm-alpine
ARG VERSION=2.1.6
ARG CHECKSUM=e1c258ca43f620571bf7d8c9b7e6705bc8c2b67075f321d584a8b8523b55b4aa
ARG TZ
ENV TZ $(TZ)
WORKDIR /var/www/html
COPY ./entrypoint.sh /entrypoint.sh
COPY ./config/custom.ini /usr/local/etc/php/conf.d/custom.ini
COPY ./config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./config/app.conf  /etc/apache2/conf.d/app.conf
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    mysql-client=10.4.15-r0 \
    freetype=2.10.4-r0 \
    libpng=1.6.37-r1 \
    libjpeg-turbo=2.0.5-r0 \
    freetype-dev=2.10.4-r0 \
    libpng-dev=1.6.37-r1 \
    libjpeg-turbo-dev=2.0.5-r0 \
    icu-libs=67.1-r0 \
    jpegoptim=1.4.6-r0 \
    optipng=0.7.7-r0 \
    pngquant=2.12.6-r0 \
    gifsicle=1.92-r0 \
    supervisor=4.2.0-r0 \
    apache2=2.4.46-r1 \
    apache2-ctl=2.4.46-r1 \
    apache2-proxy=2.4.46-r1 \
    tzdata=2020f-r0 && \
  echo "**** cleanup ****" && \
  rm -rf /tmp/* && \
  echo "**** configure php extensions ****" && \
  docker-php-ext-configure \
    gd --with-gd --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ && \
  echo "**** install php extensions ****" && \
  docker-php-ext-install \
    mysqli \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    pdo \
    bcmath \
    gd && \
  echo "**** download leantime ****" && \
  curl -LJO "https://github.com/Leantime/leantime/releases/download/v${VERSION}/Leantime-v${VERSION}.tar.gz" && \
  echo "$CHECKSUM  Leantime-v${VERSION}.tar.gz" | sha256sum -c && \
  tar -zxvf "Leantime-v${VERSION}.tar.gz" --strip-components 1 && \
  rm "Leantime-v${VERSION}.tar.gz" && \
  chown www-data -R . && \
  chmod +x /entrypoint.sh && \
  echo "**** configure supervisord ****" && \
  sed -i '/LoadModule rewrite_module/s/^#//g' /etc/apache2/httpd.conf && \
  sed -i 's#AllowOverride [Nn]one#AllowOverride All#' /etc/apache2/httpd.conf && \
  sed -i '$iLoadModule proxy_module modules/mod_proxy.so' /etc/apache2/httpd.conf
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 80 9000
