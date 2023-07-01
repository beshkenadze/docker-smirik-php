ARG PHP_VERSION=8.2
ARG CADDY_VERSION=2

FROM php:${PHP_VERSION}-fpm-alpine AS core_php

RUN set -eux; \
    apk upgrade --update --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community caddy; \
    apk add --update --no-cache libxslt-dev caddy zip gnu-libiconv git gettext file acl su-exec supervisor fcgi; \
    apk add --update --no-cache --virtual .php-deps postgresql-dev libzip-dev icu-dev; \
    # docker-php-ext-install -j$(nproc) pdo_pgsql xsl; \
    apk add --update --no-cache --virtual .php-rundeps libxslt so:libpq.so.5; \
    apk del .php-deps

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod uga+x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions apcu intl opcache pdo pdo_pgsql zip sockets mbstring iconv gd xsl

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

COPY --chown=nobody:nobody ./caddy/Caddyfile /usr/local/etc/caddy
COPY --chown=nobody:nobody ./supervisor/supervisord.conf /usr/local/etc/supervisor/supervisord.conf
COPY --chown=nobody:nobody ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY ./docker-entrypoint.sh /usr/local/etc/entry.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

#> Start setup the php conf for the prod env <#
RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
COPY ./symfony.prod.ini $PHP_INI_DIR/conf.d/app.ini

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

################
### PHP FOR DEV
###############

FROM core_php AS core_php_dev

ENV APP_ENV=dev
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY ./symfony.dev.ini $PHP_INI_DIR/conf.d/app.ini


RUN set -eux; \
    apk add --no-cache --update \
    make\
    nano \
    bash \
    ;