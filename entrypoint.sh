#!/bin/sh

# Обновление сертификатов
echo "Updating CA certificates..."
update-ca-certificates

# Запуск PHP-FPM
echo "Starting PHP-FPM..."
exec php-fpm