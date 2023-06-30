ARG PHP_VERSION=8.2
ARG CADDY_VERSION=2

FROM php:${PHP_VERSION}-fpm-alpine AS core_php

RUN set -eux; \
    apk upgrade --update --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community caddy; \
    apk add --update --no-cache libxslt-dev caddy zip gnu-libiconv git gettext file acl; \
    apk add --update --no-cache --virtual .php-deps postgresql-dev libzip-dev icu-dev; \
    # docker-php-ext-install -j$(nproc) pdo_pgsql xsl; \
    apk add --update --no-cache --virtual .php-rundeps libxslt so:libpq.so.5; \
    apk del .php-deps

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod uga+x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions apcu intl opcache pdo pdo_pgsql zip sockets mbstring iconv gd xsl

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

COPY --chown=nobody:nobody php/caddy/Caddyfile /usr/local/etc/caddy
COPY --chown=nobody:nobody php/supervisor/supervisord.conf /usr/local/etc/supervisor/supervisord.conf

############
### DEPS 
############

FROM core_php as app_deps

ENV HOME=/srv/app
WORKDIR /srv/app

# build for production
ARG APP_ENV=prod

RUN chown nobody:nobody ${HOME}
# prevent the reinstallation of vendors at every changes in the source code
COPY --chown=nobody:nobody composer.json composer.lock symfony.lock ./
RUN set -eux; \
    su-exec nobody composer install --prefer-dist --no-dev --no-scripts --no-progress; \
    su-exec nobody composer clear-cache;


#####################
### WEB CORE INSTALL
#####################

FROM node:alpine as app_assets
ENV HOME=/srv/app
WORKDIR /srv/app

# build for production
ARG NODE_ENV=production

RUN apk add --no-cache --virtual .gyp python3 make g++

# COPY FILES 
COPY --chown=nobody:nobody package.json webpack.config.js yarn.lock ./
COPY --chown=nobody:nobody public public/
# COPY --chown=nobody:nobody src src/
COPY --chown=nobody:nobody assets assets/

RUN yarn install
RUN yarn build

##################
### CREATING PROD
##################

FROM core_php as app_prod
ARG APP_ENV=prod
ENV APP_ENV $APP_ENV

#> Start setup the php conf for the prod env <#
RUN [ -e $PHP_INI_DIR/php.ini ] && unlink $PHP_INI_DIR/php.ini
RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
COPY php/symfony.prod.ini $PHP_INI_DIR/conf.d/app.ini
#> End setup the php conf for the prod env <#

# copy only specifically what we need
COPY --chown=nobody:nobody composer.json composer.lock symfony.lock ./
COPY --chown=nobody:nobody .env ./
COPY --chown=nobody:nobody assets assets/
COPY --chown=nobody:nobody bin bin/
COPY --chown=nobody:nobody config config/
COPY --chown=nobody:nobody migrations migrations/
COPY --chown=nobody:nobody translations translations/
COPY --chown=nobody:nobody public public/
COPY --chown=nobody:nobody src src/
COPY --chown=nobody:nobody templates templates/

# Already built data  
COPY --chown=nobody:nobody --from=app_deps /srv/app/vendor ./vendor
COPY --chown=nobody:nobody --from=app_assets /srv/app/public/build ./public/build

VOLUME /srv/app/var
RUN set -eux; \
    su-exec nobody echo 'Building for: ${APP_ENV}'; \
    su-exec nobody mkdir -p var/cache var/log public/uploads/books; \
    su-exec nobody composer dump-autoload --classmap-authoritative --no-dev; \
    su-exec nobody composer run-script --no-dev post-install-cmd; \
    su-exec nobody chmod +x bin/console; sync

COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080
# ENTRYPOINT ["docker-entrypoint.sh"] # we don't use this anymore because we use the docker-entrypoint.sh in supervisord.conf





#### GOVNO ####
#### GOVNO ####
#### GOVNO ####
#### GOVNO ####
#### GOVNO ####

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
