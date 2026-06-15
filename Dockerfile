FROM php:8.3-fpm

# Установка необходимых пакетов и зависимостей
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
    librdkafka-dev \
    libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd mysqli opcache sockets pdo pdo_mysql iconv gd zip intl \
    && pecl install xdebug rdkafka\
    && docker-php-ext-enable xdebug rdkafka intl \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Создание директории для сессий PHP и установка нужных прав
RUN mkdir -p /var/lib/php/session && \
    chown -R 1000:1000 /var/lib/php/session && \
    chmod 1733 /var/lib/php/session


# Настройка прав доступа к корневой директории
RUN chown -R 1000:1000 /var/www/html && chmod -R 755 /var/www/html && mkdir /var/log/apps && chown 1000:1000 /var/log/apps

# Добавление серты
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]