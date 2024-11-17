FROM php:8.2-fpm

# Установка необходимых пакетов и зависимостей за одну команду
RUN apt-get update && apt-get install -y \
    pkg-config \
    zip \
    zlib1g-dev \
    libzip-dev \
    sendmail \
    curl \
    libonig-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    ca-certificates \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd mysqli opcache sockets pdo pdo_mysql \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Создание директории для сессий PHP и установка нужных прав
RUN mkdir -p /var/lib/php/session && \
    chown -R 1000:1000 /var/lib/php/session && \
    chmod 1733 /var/lib/php/session

# Установка и активация Xdebug (опционально; можно отключить при необходимости)
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Настройка прав доступа к корневой директории
RUN chown -R 1000:1000 /var/www/html && chmod -R 755 /var/www/html && mkdir /var/log/apps && chown 1000:1000 /var/log/apps && update-ca-certificates

# Перезапуск sendmail при запуске контейнера
RUN sed -i '/#!\/bin\/sh/aservice sendmail restart' /usr/local/bin/docker-php-entrypoint
