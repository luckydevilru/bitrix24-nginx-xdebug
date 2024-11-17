# ОСОБЕННОСТИ СОЗДАНИЯ ДОКЕРА ДЛЯ BITRIX24

0. Создать линки в hosts:
   `127.0.0.1 b24.doc
127.0.0.1 bxapps.doc`
1. Создать серты: `mkcert b24.doc && mkcert b24.doc`. Положить все это дело в директорию ./certs `cp ./certs/bxapps.doc.pem ./certs/bxapps.doc.crt && cp ./certs/b24.doc.pem ./certs/b24.doc.crt`
2. Замените серты в директории certs на свои. и поправьте в конфигах nginx.conf на свои
3. в docker-compose правим id для user: "952:952" -- Указать UID и GID из команды 'id mysql' с локального компа! иначе будет работать только в докере, а локальный потом не будет запускаться

## сборка сервера

сборка контейнера Базы Данных часто заваливается из-за того что ulimits. слишком маленький. а ошибку он подлую выдает

## импорт файловой системы

## подключение бд и импорт дампа.

- включить в mysql до начала импорта: SET GLOBAL innodb_strict_mode=0;
- ВЫключить в mysql после импорта: SET GLOBAL innodb_strict_mode=0;
  иначе будет куча проблем. (Битра же).
- после или до без разницы создать пользователя в бд:
  `mariadb -u root -p
CREATE USER 'bitrix'@'%' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON sitemanager.* TO 'bitrix'@'%';
FLUSH PRIVILEGES;`

## скрин производительности:

![alt perfomance_screen](https://github.com/luckydevilru/bitrix24-nginx-xdebug/blob/master/Screenshot%20From%202024-11-14%2012-49-48.png)
