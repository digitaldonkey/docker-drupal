FROM php:7.2-apache
MAINTAINER Thorsten Krug <email@donkeymedia.eu>

ENV DEBIAN_FRONTEND noninteractive

ENV APACHE_DOCUMENT_ROOT=/var/www/drupal/web/

ARG MYSQL_ROOT_PASSWORD
ENV MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD

# Switch Drupal composer install ('stable') or github version ('dev').
ARG BUILD_ENVIRONMENT
ENV BUILD_ENVIRONMENT=$BUILD_ENVIRONMENT

# Install PHP extensions and PECL modules.
RUN buildDeps=" \
        default-libmysqlclient-dev \
        libbz2-dev \
        libmemcached-dev \
        libsasl2-dev \
        libxml2-dev \
        make \
        xsltproc \
        apt-transport-https \
    " \
    runtimeDeps=" \
        curl \
        ca-certificates \
        openssh-server \
        openssl \
        ssl-cert \
        vim \
        wget \
        git \
        sed \
        cron \
        file \
        mysql-client \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libjpeg-dev \
        libldap2-dev \
        libmemcachedutil2 \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
        zip \
        libgmp-dev \
        zlib1g-dev \
        libxslt-dev \
        re2c\
        imagemagick \
        libmhash-dev \
        libmagickwand-dev \
    " \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/ \
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $buildDeps $runtimeDeps


RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ && docker-php-ext-install -j$(nproc) gd
RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && docker-php-ext-install -j$(nproc) ldap
RUN docker-php-ext-configure zip --with-libzip && docker-php-ext-install -j$(nproc) zip
RUN docker-php-ext-configure gmp && docker-php-ext-install -j$(nproc) gmp

RUN docker-php-ext-install -j$(nproc) xsl mbstring gettext exif bcmath bz2 calendar intl mysqli opcache pdo_mysql pdo_pgsql pgsql soap

RUN pecl install redis-4.0.1 \
    && pecl install xdebug-2.6.0 \
    && docker-php-ext-enable redis xdebug
RUN a2enmod rewrite

RUN pecl install imagick && docker-php-ext-enable imagick

# KeccakCodePackage for Ethereum keccac256.
RUN mkdir -p /opt/local/bin && \
    cd /opt/local && \
    wget https://github.com/gvanas/KeccakCodePackage/archive/master.tar.gz && \
    tar xvf master.tar.gz && \
    rm master.tar.gz && \
    cd KeccakCodePackage-master && \
    make generic64/KeccakSum && \
    mv bin/generic64/KeccakSum ../bin/keccac && \
    rm -rf KeccakCodePackage-master master.tar.gz


# NODE & NPM - Install PHP 7 Repo
RUN rm -f /etc/nginx/conf.d/* && \
    apt-get update && apt-get install -my wget gnupg  && \
    sh -c "echo 'deb http://packages.dotdeb.org jessie all' >> /etc/apt/sources.list" && \
    sh -c "echo 'deb-src http://packages.dotdeb.org jessie all' >> /etc/apt/sources.list"  && \
    wget https://www.dotdeb.org/dotdeb.gpg -O - | apt-key add -  && \
    wget https://nginx.org/keys/nginx_signing.key -O - | apt-key add - && \
    curl --fail -ssL -o setup-nodejs https://deb.nodesource.com/setup_8.x && \
    bash setup-nodejs && \
    apt-get install -y nodejs build-essential

# Clean up
RUN apt-get purge -y --auto-remove $buildDeps && rm -r /var/lib/apt/lists/* && apt-get clean


# Link Composer
# @see https://github.com/docker-library/php/issues/344#issuecomment-364843883
COPY --from=composer:1.5 /usr/bin/composer /usr/bin/composer


# Setup SSH.
# Both users (root, drupal) are only allowed to login with key in app/build/ssh/authorized_keys.
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin without-password/' /etc/ssh/sshd_config && \
    mkdir /var/run/sshd && chmod 0755 /var/run/sshd && \
    mkdir -p /root/.ssh/ &&  chmod 700 /root/.ssh/ && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
COPY app/build/ssh/* /root/.ssh/
RUN chown root:root /root/.ssh/* && chmod 600 /root/.ssh/*


# Setup PHP.

# RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php/apache2/php.ini
# RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php5/cli/php.ini

# Setup Blackfire.
# Get the sources and install the Debian packages.
# We create our own start script. If the environment variables are set, we
# simply start Blackfire in the foreground. If not, we create a dummy daemon
# script that simply loops indefinitely. This is to trick Supervisor into
# thinking the program is running and avoid unnecessary error messages.

# RUN wget -O - https://packagecloud.io/gpg.key | apt-key add -
# RUN echo "deb http://packages.blackfire.io/debian any main" > /etc/apt/sources.list.d/blackfire.list
# RUN apt-get update
# RUN apt-get install -y blackfire-agent blackfire-php
# RUN echo '#!/bin/bash\n\
# if [[ -z "$BLACKFIREIO_SERVER_ID" || -z "$BLACKFIREIO_SERVER_TOKEN" ]]; then\n\
#     while true; do\n\
#         sleep 1000\n\
#     done\n\
# else\n\
#     /usr/bin/blackfire-agent -server-id="$BLACKFIREIO_SERVER_ID" -server-token="$BLACKFIREIO_SERVER_TOKEN"\n\
# fi\n\
# ' > /usr/local/bin/launch-blackfire
# RUN chmod +x /usr/local/bin/launch-blackfire
# RUN mkdir -p /var/run/blackfire


# Setup Apache.
RUN sed -ri -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/*.conf
RUN sed -ri -e "s!/var/www/!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

RUN sed -i '1s/^/ServerName localhost\n/' /etc/apache2/apache2.conf && \
    sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf && \
    echo "Listen 8080" >> /etc/apache2/ports.conf && \
    echo "Listen 8081" >> /etc/apache2/ports.conf && \
    echo "Listen 8443" >> /etc/apache2/ports.conf && \
    a2enmod rewrite && \
    a2enmod ssl && \
    a2ensite default-ssl.conf


# Setup Supervisor.

# RUN echo '[program:apache2]\ncommand=/bin/bash -c "source /etc/apache2/envvars && exec /usr/sbin/apache2 -DFOREGROUND"\nautorestart=true\n\n' >> /etc/supervisor/supervisord.conf
# RUN echo '[program:mysql]\ncommand=/usr/bin/pidproxy /var/run/mysqld/mysqld.pid /usr/sbin/mysqld\nautorestart=true\n\n' >> /etc/supervisor/supervisord.conf
# RUN echo '[program:sshd]\ncommand=/usr/sbin/sshd -D\n\n' >> /etc/supervisor/supervisord.conf
# RUN echo '[program:blackfire]\ncommand=/usr/local/bin/launch-blackfire\n\n' >> /etc/supervisor/supervisord.conf
# RUN echo '[program:cron]\ncommand=cron -f\nautorestart=false \n\n' >> /etc/supervisor/supervisord.conf

# Setup XDebug.

# RUN echo "xdebug.max_nesting_level = 300" >> /etc/php5/apache2/conf.d/20-xdebug.ini
# RUN echo "xdebug.max_nesting_level = 300" >> /etc/php5/cli/conf.d/20-xdebug.ini


# Add user "drupal"
RUN rm -rf /var/www && \
    useradd drupal --home-dir /var/www --create-home --user-group --groups www-data --shell /bin/bash && \
    sed -i "s/#alias ll='ls -l'/alias ll='ls -l'/" /var/www/.bashrc && \
    mkdir -p /var/www/tools && \
    echo "PATH=/opt/local/bin:/var/www/.composer/vendor/bin:$PATH " >> /var/www/.bashrc && \
    chown -R drupal:drupal /var/www

# SSH keys
COPY app/build/ssh/* /var/www/.ssh/
RUN chmod 700 /var/www/.ssh/ && chown 600 /var/www/.ssh/* && chown -R drupal:drupal /var/www/.ssh/


#  Database credentials for user (MariaDB is another container).
RUN printf "[client] \nuser=root \npassword=$MYSQL_ROOT_PASSWORD \nhost=mysql \nprotocol=tcp \nport=3306 \n" > /var/www/.my.cnf


# Composer speedup.
RUN su drupal -c "/usr/bin/composer global require hirak/prestissimo \
                  && /usr/bin/composer global require drush/drush:8.*"

# Install Drupal Console.
RUN curl https://drupalconsole.com/installer -L -o /usr/bin/drupal && \
    chmod +x /usr/bin/drupal && \
    su drupal -c "/usr/bin/drupal init --yes --no-interaction --destination /var/www/.console/ --autocomplete && \
    echo 'source /var/www/bin/.console/console.rc' >> /var/www/.bashrc"


# Composer install for Drupal.
RUN su drupal -c  "/usr/bin/composer create-project drupal-composer/drupal-project:~8.0 /var/www/drupal --stability dev --no-interaction --no-install"

# We will use composer.json and composer.lock as provided.
COPY app/build/composer.* /var/www/drupal/.

# Scaffold
COPY app/build/scaffold /var/www/drupal/web/sites
RUN cd  /var/www/drupal/web/sites/default/ && \
    cp default.settings.php settings.php && \
    cp default.services.yml services.yml

RUN cd /var/www && \
  chown -R drupal:www-data drupal/web/sites/default && \
  find drupal/web/sites/default -type d -exec chmod 775 {} + && \
  chmod 644 drupal/web/sites/default/settings.php && \
  chmod 644 drupal/web/sites/default/services.yml  &&\
  mkdir drupal/files_private -p && \
  mkdir drupal/web/modules/contrib -p && \
  mkdir drupal/config/sync -p && \
  mkdir drupal/web/themes/contrib -p && \
  mkdir drupal/web/profiles/contrib -p && \
  chown -R drupal:drupal drupal && \
  chown -R drupal:www-data drupal/web && \
  chown -R drupal:www-data drupal/files_private && \
  chown -R drupal:www-data drupal/config && \
  chmod 775 drupal/files_private && \
  chmod -R 775 drupal/config


RUN su drupal -c "/usr/bin/composer install --working-dir /var/www/drupal "

# Add phpinfo() file.
RUN su drupal -c "echo '<?php phpinfo();' > ${APACHE_DOCUMENT_ROOT}phpinfo.php"


COPY app/run/ /var/www/scripts/
RUN chown -R drupal:drupal /var/www/scripts/ && \
    chmod 700 /var/www/scripts/*

EXPOSE 80 22 443

# CMD exec supervisord -n
COPY default.env /var/www/drupal/.env

ENTRYPOINT service ssh restart && \
           service apache2 start && \
           su drupal /var/www/scripts/install-drupal.sh && \
           bash
