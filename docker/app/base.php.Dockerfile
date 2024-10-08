ARG PHP_VERSION=8.3.12
ARG PHP_ALPINE_VERSION=3.20
ARG XDEBUG_VERSION=3.3.2



# ╔═ IMAGE ════════════════════════════════════════════════════════════════╗
# ║                               BASE PHP                                 ║
# ╠════════════════════════════════════════════════════════════════════════╣
# ║ Базовый образ для всех PHP образов. Необходим, чтобы оптимизировать    ║
# ║ разворот при сборке на CI/CD. Является самой тяжёлой частью            ║
# ║ и самой редко изменяемой.                                              ║
# ╚════════════════════════════════════════════════════════════════════════╝
FROM php:${PHP_VERSION}-cli-alpine${PHP_ALPINE_VERSION}

ARG XDEBUG_VERSION

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN RUNTIME_DEPS="tini fcgi linux-headers"; \
    SECURITY_UPGRADES="curl"; \
    apk add --no-cache --upgrade ${RUNTIME_DEPS} ${SECURITY_UPGRADES}

RUN apk add --no-cache --virtual .build-deps \
      $PHPIZE_DEPS  \
      libzip-dev    \
      icu-dev       \
      libpq-dev     \
 # PHP Extensions --------------------------------- \
 && docker-php-ext-install -j$(nproc) \
      intl        \
      opcache     \
      zip         \
      sockets     \
      pdo_pgsql   \
 # Pecl Extensions -------------------------------- \
 && pecl install apcu && docker-php-ext-enable apcu \
 # ---------------------------------------------------------------------
 # Install Xdebug at this step to make editing dev image cache-friendly, we delete xdebug from production image later
 && pecl install xdebug-${XDEBUG_VERSION} \
 # Cleanup ---------------------------------------- \
 && rm -r /tmp/pear; \
 # - Detect Runtime Dependencies of the installed extensions. \
 # - src: https://github.com/docker-library/wordpress/blob/master/latest/php8.0/fpm-alpine/Dockerfile \
    out="$(php -r 'exit(0);')"; \
		[ -z "$out" ]; err="$(php -r 'exit(0);' 3>&1 1>&2 2>&3)"; \
		[ -z "$err" ]; extDir="$(php -r 'echo ini_get("extension_dir");')"; \
		[ -d "$extDir" ]; \
		runDeps="$( \
			scanelf --needed --nobanner --format '%n#p' --recursive "$extDir" \
				| tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
		)"; \
		# Save Runtime Deps in a virtual deps
		apk add --no-network --virtual .php-extensions-rundeps $runDeps; \
		# Uninstall Everything we Installed (minus the runtime Deps)
		apk del --no-network .build-deps; \
		# check for output like "PHP Warning:  PHP Startup: Unable to load dynamic library 'foo' (tried: ...)
		err="$(php --version 3>&1 1>&2 2>&3)"; 	[ -z "$err" ]

RUN deluser --remove-home www-data && adduser -u1000 -D www-data && rm -rf /var/www && \
    mkdir -p /var/www/.composer /app && chown -R www-data:www-data /app /var/www/.composer; \
# ------------------------------------------------ PHP Configuration ---------------------------------------------------
    mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
