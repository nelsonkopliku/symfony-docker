#!/bin/sh
set -e

#echo $GROUP_ID && \
#    echo $USER_ID && \
#    echo ${GROUP_ID} && \
#    echo ${USER_ID}

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

if ! id -u dev > /dev/null 2>&1; then
    addgroup -g $GROUP_ID dev
    adduser -D -u $USER_ID -G dev dev
    addgroup www-data dev
    addgroup dev www-data
fi

if [ "$1" = 'php-fpm' ] || [ "$1" = 'bin/console' ]; then
    # The first time volumes are mounted, the project needs to be recreated
    if [ ! -f composer.json ]; then
        composer create-project "symfony/skeleton $VERSION" tmp --stability=$STABILITY --prefer-dist --no-progress --no-interaction
        cp -Rp tmp/. .
        rm -Rf tmp/
    elif [ "$APP_ENV" != 'prod' ]; then
        # Always try to reinstall deps when not in prod
        composer install --prefer-dist --no-progress --no-suggest --no-interaction
    fi

	# Permissions hack because setfacl does not work on Mac and Windows
	chown -R dev:dev /srv/app
fi

#if [ ! -f app/composer.json ]; then
#    composer create-project symfony/skeleton app
#    chown -R dev:dev app
#fi

#if [ "$1" = 'php-fpm' ] || [ "$1" = 'bin/console' ]; then
##	mkdir -p var/cache var/log var/sessions
#
##	if [ "$APP_ENV" != 'prod' ]; then
##		composer install --prefer-dist --no-progress --no-suggest --no-interaction
##		bin/console doctrine:schema:update --force --no-interaction
##	fi
#
#	# Permissions hack because setfacl does not work on Mac and Windows
##	chown -R dev:dev var
#fi

exec docker-php-entrypoint "$@"
