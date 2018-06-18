ARG PHP_VERSION=7.2
ARG ALPINE_VERSION=3.7
FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION}

RUN apk add --no-cache \
		git

ARG APCU_VERSION=5.1.11
RUN set -xe \
	&& apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		icu-dev \
		postgresql-dev \
		zlib-dev \
		curl-dev \
	&& docker-php-ext-install -j$(nproc) \
		intl \
		pdo_pgsql \
		zip \
		mbstring \
		curl \
	&& pecl install \
		apcu-${APCU_VERSION} \
		xdebug \
	&& pecl clear-cache \
	&& docker-php-ext-enable --ini-name 20-apcu.ini apcu \
	&& docker-php-ext-enable --ini-name 05-opcache.ini opcache \
	&& docker-php-ext-enable --ini-name xdebug.ini xdebug \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
#    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini \
	&& runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
	&& apk add --no-cache --virtual .api-phpexts-rundeps $runDeps \
	&& apk del .build-deps

COPY docker/php/php.ini /usr/local/etc/php/php.ini
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer global require "hirak/prestissimo:^0.3" --prefer-dist --no-progress --no-suggest --classmap-authoritative \
	&& composer clear-cache
ENV PATH="${PATH}:/root/.composer/vendor/bin"

WORKDIR /srv/app

# Build for production
ARG APP_ENV=prod
# Allow to use development versions of Symfony
ARG STABILITY=stable
ENV STABILITY ${STABILITY}

# Allow to select skeleton version
ARG VERSION=""

# Prevent the reinstallation of vendors at every changes in the source code
#COPY composer.json composer.lock ./
#RUN composer install --prefer-dist --no-dev --no-autoloader --no-scripts --no-progress --no-suggest \
#	&& composer clear-cache

COPY . .

#RUN mkdir -p var/cache var/log var/sessions \
##	&& composer dump-autoload --classmap-authoritative --no-dev \
##	&& composer run-script --no-dev post-install-cmd \
##	&& chmod +x bin/console && sync \
#	&& chown -R www-data:www-data var
#VOLUME /srv/app/var

COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]
