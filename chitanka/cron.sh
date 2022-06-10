#!/bin/sh
set -eu

# create cron job
mkdir -p /var/spool/cron/crontabs
echo "${CHITANKA_CRON} /var/www/chitanka/bin/update" | busybox crontab -u www-data -
exec busybox crond -f -l 0 -L /dev/stdout
