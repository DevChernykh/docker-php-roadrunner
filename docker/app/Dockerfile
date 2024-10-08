ARG BASE_PHP_IMAGE_TAG=base-php

ARG PHP_VERSION=8.3.12
ARG COMPOSER_VERSION=2.8.0
ARG COMPOSER_AUTH
ARG RR_VERSION=2024.1
ARG APP_BASE_DIR



# ╔═ IMAGE ════════════════════════════════════════════════════════════════╗
# ║                               COMPOSER                                 ║
# ╠════════════════════════════════════════════════════════════════════════╣
# ║ Нужен, чтобы получить composer, без ручной установки.                  ║
# ╚════════════════════════════════════════════════════════════════════════╝
FROM composer:${COMPOSER_VERSION} AS composer



# ╔═ IMAGE ════════════════════════════════════════════════════════════════╗
# ║                              ROADRUNNER                                ║
# ╠════════════════════════════════════════════════════════════════════════╣
# ║ Нужен, чтобы получить roadrunner, без ручной установки.                ║
# ╚════════════════════════════════════════════════════════════════════════╝
FROM ghcr.io/roadrunner-server/roadrunner:${RR_VERSION} AS rr



# ╔═ IMAGE ════════════════════════════════════════════════════════════════╗
# ║                              Shared PHP                                ║
# ╠════════════════════════════════════════════════════════════════════════╣
# ║ Настройки образа, которыt являются общими для разработки и продакшена. ║
# ╚════════════════════════════════════════════════════════════════════════╝
FROM ${BASE_PHP_IMAGE_TAG}:latest AS app-base

# Загружаем конфигурационные файлы PHP
COPY ./docker/app/php/base-* $PHP_INI_DIR/conf.d/

# Загружаем скрипты для выполнения
COPY ./docker/app/entrypoint/*-base \
    ./docker/app/post-build/*-base \
    ./docker/app/pre-run/*-base \
    ./docker/app/scripts/command-loop* \
    ./docker/app/rr/rr-healthcheck \
    # to
    /usr/local/bin/

# Делаем скрипты выполняемыми
RUN chmod +x /usr/local/bin/*-base /usr/local/bin/rr-healthcheck /usr/local/bin/command-loop*

# Копируем composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR /app
USER www-data

# Common PHP Frameworks Env Variables
ENV APP_ENV prod
ENV APP_DEBUG 0

# Копируем roadrunner
COPY --from=rr /usr/bin/rr /usr/bin/rr

HEALTHCHECK CMD ["healthcheck-rr"]
ENTRYPOINT ["entrypoint-base"]
EXPOSE 8080



# ╔═ IMAGE ════════════════════════════════════════════════════════════════╗
# ║                          Composer AS vendor                            ║
# ╠════════════════════════════════════════════════════════════════════════╣
# ║                                                                        ║
# ╚════════════════════════════════════════════════════════════════════════╝
FROM composer AS vendor

ARG PHP_VERSION
ARG COMPOSER_AUTH
ARG APP_BASE_DIR

ENV COMPOSER_AUTH $COMPOSER_AUTH

WORKDIR /app

COPY $APP_BASE_DIR/composer.json composer.json
COPY $APP_BASE_DIR/composer.lock composer.lock

RUN composer config platform.php ${PHP_VERSION}; \
    composer install -n --no-progress --ignore-platform-reqs --no-dev --prefer-dist --no-scripts --no-autoloader



# ╔═ IMAGE ════════════════════════════════════════════════════════════════╗
# ║                            PRODUCTION PHP                              ║
# ╠════════════════════════════════════════════════════════════════════════╣
# ║ Образ, предназначенный для продакшена, который не должен содержать     ║
# ║ зависимости, предназначенные для разработки.                           ║
# ║ А также имеет соответствующие скрипты.                                 ║
# ╚════════════════════════════════════════════════════════════════════════╝
FROM app-base AS app-prod

ARG APP_BASE_DIR
USER root

# Copy PHP Production Configuration
COPY ./docker/app/php/prod-*   $PHP_INI_DIR/conf.d/

# Copy Prod Scripts && delete xdebug
COPY ./docker/app/entrypoint/*-prod \
    ./docker/app/post-build/*-prod \
    ./docker/app/pre-run/*-prod \
     # to
     /usr/local/bin/
COPY ./docker/app/rr/rr.prod.server.yaml /usr/local/bin/rr.server.yaml

RUN  chmod +x /usr/local/bin/*-prod && pecl uninstall xdebug

USER www-data

COPY --chown=www-data:www-data --from=vendor /app/vendor /app/vendor

# Copy App Code
COPY --chown=www-data:www-data $APP_BASE_DIR/ .

RUN composer install --optimize-autoloader --apcu-autoloader --no-dev -n --no-progress && \
    composer check-platform-reqs && \
    post-build-base && post-build-prod

ENTRYPOINT ["entrypoint-prod"]
CMD ["rr", "serve", "-c", "/usr/local/bin/rr.server.yaml"]



# ╔═ IMAGE ════════════════════════════════════════════════════════════════╗
# ║                              DEVELOP PHP                               ║
# ╠════════════════════════════════════════════════════════════════════════╣
# ║ Образ, предназначенный для разработки, который может содержать         ║
# ║ зависимости, предназначенные для упрощения и удобства разработки.      ║
# ║ А также имеет соответствующие скрипты.                                 ║
# ╚════════════════════════════════════════════════════════════════════════╝
FROM app-base AS app-dev

ENV APP_ENV dev
ENV APP_DEBUG 1

USER root

RUN apk --no-cache add git openssh bash; \
    docker-php-ext-enable xdebug

ENV XDEBUG_CLIENT_HOST="host.docker.internal"

COPY ./docker/app/php/dev-* $PHP_INI_DIR/conf.d/
COPY ./docker/app/entrypoint/*-dev \
    ./docker/app/post-build/*-dev \
    ./docker/app/pre-run/*-dev \
     # to
     /usr/local/bin/
COPY ./docker/app/rr/rr.dev.server.yaml /usr/local/bin/rr.server.yaml

RUN chmod +x /usr/local/bin/*-dev /usr/local/bin/rr.server.yaml; \
    mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

USER www-data

ENTRYPOINT ["entrypoint-dev"]
CMD ["rr", "serve", "-c", "/usr/local/bin/rr.server.yaml"]
