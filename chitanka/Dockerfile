FROM php:7.2-fpm-buster
LABEL version="0.3"
LABEL description="chitanka.info"

RUN set -ex; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libfreetype6-dev \
		libjpeg-dev \
		libmagickwand-dev \
		libpng-dev \
		libzip-dev \
		libcurl4-openssl-dev \
		libxslt-dev \
	; \
	docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install -j "$(nproc)" \
		gd \
		curl \
		intl \
		xsl \
		zip \
		pdo \
		pdo_mysql; \
		\
	docker-php-ext-enable pdo_mysql; \
	\
	# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { print $3 }' \
        | sort -u \
        | xargs -r dpkg-query -S \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

# git clone the source and install dependencies
RUN set -ex; \
	\
	apt-get update; \
    apt-get install -y --no-install-recommends \
	  unzip \
	  mariadb-client \
	  busybox-static \
	  rsync \
	  git \
	; \
	rm -rf /var/lib/apt/lists/*; \
    git clone --depth 1 https://github.com/chitanka/chitanka-production.git /var/www/chitanka; \
    chown -R www-data:www-data /var/www/chitanka; \
    cd /var/www/chitanka && chmod -R 777 var/cache var/log var/spool web/cache; \
    curl -fsSL https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh > /wait-for-it.sh && \
    chmod 755 /wait-for-it.sh


VOLUME /var/www/chitanka/app/config

COPY *.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
