#!/bin/sh
set -e

#su dev

if ! id -u dev > /dev/null 2>&1; then
    addgroup -g $GROUP_ID dev
    adduser -D -u $USER_ID -G dev dev
    addgroup www-data dev
    addgroup dev www-data
fi



su -s /bin/sh dev
cd /srv/app

#echo $GROUP_ID && \
#    echo $USER_ID && \
#    echo ${GROUP_ID} && \
#    echo ${USER_ID}

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

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
