FROM composer:2.6.6 as composer
FROM node:21.6.0 as node

FROM php:8.2-fpm

ARG user
ARG uid
ARG env_file

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    git \
    libmagickwand-dev --no-install-recommends \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    zip \
    unzip \
    procps \
    mariadb-client \
    libzip-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs

RUN echo "memory_limit = 1024M" >> /usr/local/etc/php/php.ini && \
    echo "max_execution_time = 3000" >> /usr/local/etc/php/php.ini && \
    echo "upload_max_filesize = 256M" >> /usr/local/etc/php/php.ini

RUN docker-php-ext-configure intl && \
    docker-php-ext-configure zip && \
    docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd fileinfo intl zip && \
    pecl install imagick && \
    docker-php-ext-enable imagick && \
    pecl install openswoole && docker-php-ext-enable openswoole && \
    pecl install redis && docker-php-ext-enable redis


COPY --from=composer /usr/bin/composer /usr/bin/composer


COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules


ENV PATH /usr/local/lib/node_modules/npm/bin:$PATH

COPY $env_file .env



RUN useradd -G www-data,root -u $uid -d /home/$user $user && \
    mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user


USER $user
