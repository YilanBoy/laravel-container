ARG PHP_VERSION=8.3

###########################################
# Laravel Dependencies
###########################################
FROM composer:latest AS vendor

WORKDIR /var/www/html

# copy only the 'composer.json' and 'composer.lock' files into the container
COPY composer* ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --ignore-platform-reqs \
    --optimize-autoloader \
    --apcu-autoloader \
    --ansi \
    --no-scripts \
    --audit

###########################################
# Front-End Assets
###########################################
FROM node:22 AS assets

WORKDIR /var/www/html

COPY . .
RUN npm install \
    && npm run build

###########################################
# Laravel Queue
###########################################
FROM php:${PHP_VERSION}-alpine3.20

LABEL maintainer="Allen"

ENV ROOT=/var/www/html
WORKDIR $ROOT

# set the default shell to /bin/ash with some useful options
# -e: exit immediately if a command exits with a non-zero status
# -c: execute the following command when the shell starts
SHELL ["/bin/ash", "-e", "-c"]

# install necessary package to install php extension
RUN apk update \
    && apk upgrade \
    && apk add autoconf gcc g++ make

# install php extension
RUN docker-php-ext-install pdo_mysql \
    && docker-php-ext-install opcache \
    && docker-php-ext-install pcntl \
    && pecl install redis \
    && docker-php-ext-enable redis

ARG WWWUSER=1001
ARG WWWGROUP=1001

# create group and user "queue"
RUN addgroup -g $WWWGROUP -S queue || true \
    && adduser -D -h /home/queue -s /bin/ash -G queue -u $WWWUSER queue

# copy supervisor and php config files into container
COPY containerize/php/php.ini /usr/local/etc/php/conf.d/queue.ini
COPY containerize/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

COPY . .

# create bootstrap and storage files if they do not exist
# gives the 'queue' user read/write and execute privileges to those files
RUN mkdir -p \
    storage/framework/sessions \
    storage/framework/views \
    storage/framework/cache/data \
    storage/logs \
    bootstrap/cache \
    && chown -R queue:queue \
    storage \
    bootstrap/cache \
    && chmod -R ug+rwx storage bootstrap/cache

# copy dependencies from another stage
COPY --from=vendor ${ROOT}/vendor vendor
COPY --from=assets ${ROOT}/public/build public/build

USER queue

ENTRYPOINT ["php", "artisan", "queue:work"]
