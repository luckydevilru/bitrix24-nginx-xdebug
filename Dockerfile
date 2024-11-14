FROM php:8.2-fpm

RUN apt-get update \
    && apt-get install  -y  \
	pkg-config \
	zip zlib1g-dev libzip-dev sendmail\ 
	curl \ 
	libonig-dev \ 
#	soap \
	ca-certificates   

# gd
RUN apt-get update && apt-get install -y \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng-dev \
	# && docker-php-ext-configure gd \
	&& docker-php-ext-configure gd --with-freetype --with-jpeg \
	&& docker-php-ext-install -j$(nproc) gd
	
RUN docker-php-ext-install mysqli opcache sockets pdo pdo_mysql
RUN mkdir -p /var/lib/php/session && \
    chown -R 1000:1000 /var/lib/php/session && \
    chmod 1733 /var/lib/php/session
# + ext lists
# bcmath bz2 calendar ctype dba dom enchant exif ffi fileinfo filter ftp gd gettext gmp
# hash iconv  intl  ldap mbstring oci8 odbc pcntl pdo pdo_dblib pdo_firebird
# pdo_mysql pdo_oci pdo_odbc pdo_pgsql pdo_sqlite pgsql phar posix pspell readline reflection
# shmop simplexml snmp   sodium spl
# standard sysvmsg sysvsem sysvshm tidy tokenizer xml xmlreader xmlrpc xmlwriter xsl zend_test | zip curl imap
 
RUN docker-php-ext-enable mysqli sockets  
# RUN apt-get install  -y  php-mbstring pdo_mysql
# DO NOT install php7.4-xdebug package for site running in production! It will slow it down significantly.
	

RUN chown -R 1000:1000 /var/www/html && chmod -R 755 /var/www/html
# RUN find /var/www/html/ -type d -exec chmod 755 {} \; &&\
#     find /var/www/html/ -type f -exec chmod 664 {} \;

RUN sed -i '/#!\/bin\/sh/aservice sendmail restart' /usr/local/bin/docker-php-entrypoint
#RUN sed -i '/#!\/bin\/sh/aecho "$(hostname -i)\t$(hostname) $(hostname).localhost ${VIRTUAL_HOST}" >> /etc/hosts' /usr/local/bin/docker-php-entrypoint  
 
 
RUN pecl install && pecl install xdebug && docker-php-ext-enable xdebug

RUN apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*
