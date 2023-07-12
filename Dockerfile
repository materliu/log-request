FROM ubuntu:20.04

LABEL maintainer="materliu@gmail.com"

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# NOTE: When updating PHP_VERSION, update the following as well:
# ./conf/supervisor/supervisord.conf
# ./conf/nginx/conf.d/default.conf
# ./php/{php_version}/*
ENV PHP_VERSION 8.1
# `apt-cache madison php8.1` to list available minor versions
ENV PHP_MINOR_VERSION 8.1.21-1+ubuntu20.04.1+deb.sury.org+1
ENV COMPOSER_VERSION 2.4.4
# `apt-cache madison nginx` to list available versions
ENV NGINX_VERSION 1.23.2-1~bionic

# Install Craft Requirements
RUN set -x \
    && apt-get update \
    && apt-get install -yq --allow-downgrades apt=2.0.2 \
    && apt-get install -fyq --no-install-recommends \
        cron \
        aptitude \
        apt-utils \
        curl \
        gnupg2 \
        iproute2 \
        mysql-client \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        git \
        unzip \
        zip \
    && aptitude remove -fyq libglib2.0-0 \
    && aptitude install -fyq software-properties-common openssh-server \
    && LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y \
    && curl -o /usr/share/keyrings/nginx_signing.key http://nginx.org/keys/nginx_signing.key \
    && echo "deb [signed-by=/usr/share/keyrings/nginx_signing.key] http://nginx.org/packages/mainline/ubuntu/ bionic nginx" > /etc/apt/sources.list.d/nginx.list \
    && apt-get update && apt-get install --option Acquire::Retries=100 --option Acquire::http::Timeout="300" -yq --no-install-recommends \
        nginx=${NGINX_VERSION} \
        php${PHP_VERSION}-bcmath=${PHP_MINOR_VERSION} \
        php${PHP_VERSION}-cli=${PHP_MINOR_VERSION} \
        php${PHP_VERSION}-curl=${PHP_MINOR_VERSION} \
        php${PHP_VERSION}-fpm=${PHP_MINOR_VERSION} \
        php${PHP_VERSION}-gd=${PHP_MINOR_VERSION} \
        php${PHP_VERSION}-gmp=${PHP_MINOR_VERSION} \
        php${PHP_VERSION}-intl=${PHP_MINOR_VERSION} \
        php${PHP_VERSION}-mbstring=${PHP_MINOR_VERSION} \
        php${PHP_VERSION}-mysql=${PHP_MINOR_VERSION} \
        php${PHP_VERSION}-opcache=${PHP_MINOR_VERSION} \
        php${PHP_VERSION}-readline=${PHP_MINOR_VERSION} \
        php${PHP_VERSION}-soap=${PHP_MINOR_VERSION} \
        php${PHP_VERSION}-xml=${PHP_MINOR_VERSION} \
        php${PHP_VERSION}-zip=${PHP_MINOR_VERSION} \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-redis \
    && pip install --no-cache-dir supervisor \    
    && pip install --no-cache-dir git+https://gitee.com/materliu/supervisor-stdout \    
    && printf "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d \
    && apt-get autoremove --purge -y \
        software-properties-common \
        gnupg2 \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* /var/tmp/* \
    && sed -i \
        -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" \
        -e "s/memory_limit\s*=\s*.*/memory_limit = 256M/g" \
        -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" \
        -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" \
        -e "s/max_execution_time = 30/max_execution_time = 180/g" \
        -e "s/max_input_time = 60/max_input_time = 180/g" \
        -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" \
        -e "s/;opcache.enable=1/opcache.enable=1/"\
        -e "s/;opcache.memory_consumption=128/opcache.memory_consumption=512/g" \
        -e "s/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=64/g" \
        -e "s/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=30000/g" \
        -e "s/;opcache.revalidate_freq=2/opcache.revalidate_freq=0/g" \
        /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i \
        -e "s/;daemonize\s*=\s*yes/daemonize = no/g" \
        /etc/php/${PHP_VERSION}/fpm/php-fpm.conf \
    && sed -i \
        -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
        -e "s/pm.max_children = 5/pm.max_children = 4/g" \
        -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
        -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
        -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
        -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" \
        -e "s/^;clear_env = no$/clear_env = no/" \
        /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# Install Composer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
  && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} \
  && rm -rf /tmp/*

# Nginx config
COPY conf/nginx /etc/nginx

# Supervisor config
COPY conf/supervisor/supervisord.conf /etc/supervisord.conf

# Override default nginx welcome page
COPY . /usr/share/nginx/html

# Copy Scripts
COPY start.sh /start.sh
RUN chmod 755 /start.sh

RUN mkdir -p /run/php

RUN mkdir -p /usr/share/nginx/html/storage/framework/sessions
RUN mkdir -p /usr/share/nginx/html/storage/framework/cache
RUN mkdir -p /usr/share/nginx/html/storage/framework/testing
RUN mkdir -p /usr/share/nginx/html/storage/framework/views
RUN mkdir -p /usr/share/nginx/html/storage/app/public
RUN mkdir -p /usr/share/nginx/html/storage/logs

RUN chown -R www-data:www-data /var/cache/nginx \
    && chown -R www-data:www-data /var/log/nginx \
    && chown -R www-data:www-data /usr/share/nginx \
    && chown -R www-data:www-data /etc/nginx \
    && chown -R www-data:www-data /run/php \
    && chown -R www-data:www-data /usr/share/nginx/html/storage \
    && touch /var/run/nginx.pid \
    && chown -R www-data:www-data /var/run/nginx.pid \
    && touch /var/log/php-fpm.log \
    && chown -R www-data:www-data /var/log/php-fpm.log

ENV COMPOSER_ALLOW_SUPERUSER = 1
RUN cd /usr/share/nginx/html \
    && composer config -g repo.packagist composer https://mirrors.cloud.tencent.com/composer/ \
    && composer update --ignore-platform-reqs \
    && php artisan config:clear \
    && php artisan cache:clear \
    && php artisan clear-compiled \
    && php artisan config:cache \
    && composer dump-autoload -o 

# run container as the www-data user
USER www-data

EXPOSE 8080
ENTRYPOINT ["/start.sh"]