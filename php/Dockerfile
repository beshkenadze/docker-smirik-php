ARG PHP_VERSION=8.2

FROM php:${PHP_VERSION}-fpm-alpine

RUN apk add --no-cache \
    acl \
    file \
    gettext \
    git \
    gnu-libiconv \
    icu-dev \
    libzip-dev \
    postgresql-dev \
    zip \
    ;

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod uga+x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions apcu intl opcache pdo pdo_pgsql zip sockets mbstring iconv gd

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_MEMORY_LIMIT -1

ARG HOST_UID

RUN if [ ! -z "${HOST_UID}" ]; then \
    deluser www-data \
    && addgroup www-data \
    && adduser -u "${HOST_UID}" -G www-data -H -s /bin/sh -D www-data; \
    fi

ENV WWW_DATA_UID ${HOST_UID}

ARG APP_ENV=prod
ENV APP_ENV ${APP_ENV}

RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini;

COPY ./symfony.${APP_ENV}.ini $PHP_INI_DIR/conf.d/symfony.ini
COPY ./symfony.pool.conf /usr/local/etc/php-fpm.d/
