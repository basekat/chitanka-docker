#!/bin/sh
set -eu

if [ "$1" = "php-fpm" ]; then
  if [ -f /run/secrets/chitanka_db_user ]; then
    MYSQL_USER=`cat /run/secrets/chitanka_db_user`
  fi
  if [ -f /run/secrets/chitanka_db_password ]; then
    MYSQL_PASSWORD=`cat /run/secrets/chitanka_db_password`
  fi

  # generate the parameters.yml
  if [ ! -e /var/www/chitanka/app/config/parameters.yml ]; then
    touch /var/www/chitanka/app/config/parameters.yml
    echo "Write config to $PWD/app/config/parameters.yml"
    echo "parameters:
    database_host: ${MYSQL_HOST}
    database_name: ${MYSQL_DATABASE}
    database_user: ${MYSQL_USER}
    database_password: ${MYSQL_PASSWORD}
    database_driver: pdo_mysql
    database_port: ${MYSQL_PORT:=3306}
    secret: \"$(head /dev/urandom | base64 | head -c 24)\"
    " > /var/www/chitanka/app/config/parameters.yml
  fi

  # initialize the DB
  if [ ! -e /var/www/chitanka/app/config/.db_initialized ]; then
     /wait-for-it.sh ${MYSQL_HOST}:${MYSQL_PORT:="3306"} -t 30
     curl -fsSL http://download.chitanka.info/chitanka.sql.gz | \
     gunzip | \
     mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -h ${MYSQL_HOST} ${MYSQL_DATABASE} && \
     touch /var/www/chitanka/app/config/.db_initialized || \
     echo "Failed to initialize database."
  fi
fi

exec "$@"
