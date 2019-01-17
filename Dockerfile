#FROM alpine:latest
FROM php:7.2.14-fpm-alpine3.8

MAINTAINER David Chen <gentoobreaking@gmail.com>

ENV PATH .:$PATH
ENV TERM=xterm

RUN apk add --update --no-cache socat curl tzdata findutils
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# --- Set the locale --- #
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8

# --- basic package install --- #
RUN apk update
RUN apk upgrade
RUN apk add bash git make gcc libtool python npm 
#composer
#RUN apk add php7-pdo_mysql

# --- setup for Laravel --- #
RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        curl-dev \
        imagemagick-dev \
        libtool \
        libxml2-dev \
        postgresql-dev \
        sqlite-dev \
    && apk add --no-cache \
        curl \
        git \
        imagemagick \
        mysql-client \
        postgresql-libs \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && docker-php-ext-install \
        curl \
        iconv \
        mbstring \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        pdo_sqlite \
        pcntl \
        tokenizer \
        xml \
        zip \
    && curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer \
    && apk del -f .build-deps

# --- nginx install & setup --- #
RUN apk add nginx
RUN adduser -D -g 'www' www
RUN mkdir /www
RUN chown -R www:www /var/lib/nginx
RUN chown -R www:www /www
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
RUN mkdir -p /run/nginx
ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./default.conf /etc/nginx/conf.d/default.conf
RUN chown root:root /etc/nginx/conf.d/default.conf /etc/nginx/nginx.conf
RUN chmod 600 /etc/nginx/conf.d/default.conf /etc/nginx/nginx.conf

# --- php7 setup --- #
ADD ./php.ini /etc/php7/php.ini
ADD ./php-fpm.conf /usr/local/etc/php-fpm.conf
ADD ./www.conf /usr/local/etc/php-fpm.d/www.conf

# --- supervisor install & setup --- #
RUN apk add supervisor
RUN mkdir /etc/supervisor.d
ADD ./supervisor.d/nginx.ini /etc/supervisor.d/
ADD ./supervisor.d/php-fpm.ini /etc/supervisor.d/
RUN chown root:root /etc/supervisor.d/*.ini
RUN chmod 600 /etc/supervisor.d/*.ini

# --- clean apk cache & files --- #
#RUN apk cache download
#RUN apk -v cache clean

RUN mkdir -p /opt
#RUN cd /opt/ ; git clone https://github.com/ossrs/srs
#RUN cd /opt/srs/trunk ; git pull

# --- test nginx & php --- #
ADD ./index.html /www/
ADD ./phpinfo.php /www/

# --- mysql --- #
ADD ./.env /www/.env

#RUN top
##RUN /usr/bin/supervisord -n -c /etc/supervisord.conf
CMD /usr/bin/supervisord -n -c /etc/supervisord.conf

EXPOSE 80
