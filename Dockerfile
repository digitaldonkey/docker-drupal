FROM php:7.2-apache
MAINTAINER Thorsten Krug <email@donkeymedia.eu>

ENV DEBIAN_FRONTEND noninteractive

ARG APACHE_DOCUMENT_ROOT=/var/www/drupal/web/
ENV APACHE_DOCUMENT_ROOT=$APACHE_DOCUMENT_ROOT

# Add node 8.x repo.
# https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
# RUN  curl -sL https://deb.nodesource.com/setup_8.x | bash -


# Install PHP extensions and PECL modules.
RUN buildDeps=" \
        default-libmysqlclient-dev \
        libbz2-dev \
        libmemcached-dev \
        libsasl2-dev \
        make \
        xsltproc \
    " \
    runtimeDeps=" \
        zip \
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
        mysql-client \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libldap2-dev \
        libmemcachedutil2 \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
        libgmp-dev \
    " \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/ \
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $buildDeps $runtimeDeps \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-configure zip --with-libzip \
    && docker-php-ext-configure gmp \
    && docker-php-ext-install  -j$(nproc) gd ldap zip exif gmp bcmath bz2 calendar intl mysqli opcache pdo_mysql pdo_pgsql pgsql soap \
    && pecl install memcached redis \
    && docker-php-ext-enable memcached.so redis.so \
    && apt-get purge -y --auto-remove $buildDeps \
    && rm -r /var/lib/apt/lists/* \
    && a2enmod rewrite


# Install some extensions
# @see https://hub.docker.com/r/_/php/ 'How to install more PHP extensions'
# RUN apt-get update && apt-get install -y \
#         libfreetype6-dev \
#         libjpeg62-turbo-dev \
#         libmcrypt-dev \
#         libpng-dev \
#         libgmp-dev \
#         libzip-dev \
#         libxml2-dev \
#         re2c libmhash-dev \
#         libmcrypt-dev \
#         file \
#         zlib1g-dev \
#         zip \
#         curl \
#         ca-certificates \
#         openssh-server \
#         openssl \
#         vim \
#         wget \
#         git \
#         sed \
#         cron \
#         mysql-client \
#         make \
#         xsltproc \
#     && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/ \
#     && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
#     && docker-php-ext-configure gmp \
#     && docker-php-ext-configure xml --with-libxml \
#     && docker-php-ext-configure zip --with-libzip \
#     && docker-php-ext-install -j$(nproc) gd \
#     && docker-php-ext-install -j$(nproc) zip \
#     && docker-php-ext-install -j$(nproc) gettext \
#     && docker-php-ext-install -j$(nproc) opcache \
#     && docker-php-ext-install -j$(nproc) xml \
#     && docker-php-ext-install -j$(nproc) xmlreader \
#     && docker-php-ext-install -j$(nproc) xsl \
#     && docker-php-ext-install -j$(nproc) mbstring \
#     && docker-php-ext-install -j$(nproc) pdo_mysql \
#     && docker-php-ext-install -j$(nproc) gmp \

# RUN apt-get clean


# KeccakCodePackage for Ethereum keccac256.
# RUN mkdir -p /opt/local/bin && \
#     cd /opt/local && \
#     wget https://github.com/gvanas/KeccakCodePackage/archive/master.tar.gz && \
#     tar xvf master.tar.gz && \
#     rm master.tar.gz && \
#     cd KeccakCodePackage-master && \
#     make generic64/KeccakSum && \
#     mv bin/generic64/KeccakSum ../bin/keccac && \
#     rm -rf KeccakCodePackage-master master.tar.gz && \
#     apt-get remove --purge gcc xsltproc make -y


# Link Composer
# @see https://github.com/docker-library/php/issues/344#issuecomment-364843883
COPY --from=composer:1.5 /usr/bin/composer /usr/bin/composer


# Setup SSH.
RUN echo "root:root" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    mkdir /var/run/sshd && chmod 0755 /var/run/sshd && \
    mkdir -p /root/.ssh/ && touch /root/.ssh/authorized_keys && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

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
# In order to run our Simpletest tests, we need to make Apache
# listen on the same port as the one we forwarded. Because we use
# 8080 by default, we set it up for that port.

RUN sed -ri -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/*.conf
RUN sed -ri -e "s!/var/www/!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# CHerryPick
RUN sed -i '1s/^/ServerName localhost\n/' /etc/apache2/apache2.conf && \
    sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf && \
    echo "Listen 8080" >> /etc/apache2/ports.conf && \
    echo "Listen 8081" >> /etc/apache2/ports.conf && \
    echo "Listen 8443" >> /etc/apache2/ports.conf && \
#     sed -i 's/VirtualHost _default_:443/VirtualHost _default_:443 _default_:8443/' /etc/apache2/sites-available/default-ssl.conf && \
    a2enmod rewrite && \
    a2enmod ssl && \
    a2ensite default-ssl.conf


# OLD
# RUN sed -i '1s/^/ServerName localhost\n/' /etc/apache2/apache2.conf && \
#     sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf && \
#     sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf && \
#     sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf && \
#     sed -i 's/VirtualHost \*:80/VirtualHost \*:\*/' /etc/apache2/sites-available/000-default.conf && \
#     sed -i 's/VirtualHost _default_:443/VirtualHost _default_:443 _default_:8443/' /etc/apache2/sites-available/default-ssl.conf && \
#     a2enmod rewrite && \
#     a2enmod ssl && \
#     a2ensite default-ssl.conf

# Setup Supervisor.

# RUN echo '[program:apache2]\ncommand=/bin/bash -c "source /etc/apache2/envvars && exec /usr/sbin/apache2 -DFOREGROUND"\nautorestart=true\n\n' >> /etc/supervisor/supervisord.conf
# RUN echo '[program:mysql]\ncommand=/usr/bin/pidproxy /var/run/mysqld/mysqld.pid /usr/sbin/mysqld\nautorestart=true\n\n' >> /etc/supervisor/supervisord.conf
# RUN echo '[program:sshd]\ncommand=/usr/sbin/sshd -D\n\n' >> /etc/supervisor/supervisord.conf
# RUN echo '[program:blackfire]\ncommand=/usr/local/bin/launch-blackfire\n\n' >> /etc/supervisor/supervisord.conf
# RUN echo '[program:cron]\ncommand=cron -f\nautorestart=false \n\n' >> /etc/supervisor/supervisord.conf

# Setup XDebug.

# RUN echo "xdebug.max_nesting_level = 300" >> /etc/php5/apache2/conf.d/20-xdebug.ini
# RUN echo "xdebug.max_nesting_level = 300" >> /etc/php5/cli/conf.d/20-xdebug.ini

# NODE & NPM.

# @todo REPLACE WITH
# curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
# sudo apt-get install -y nodejs
# https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
#
# RUN curl -O https://nodejs.org/dist/latest-carbon/node-v8.11.2-linux-x64.tar.xz && \
#     tar xvf node-v8.11.2-linux-x64.tar.xz && \
#     mkdir -p /opt/local/bin && \
#     mv node-v8.11.2-linux-x64 /opt/local && \
#     rm node-v8.11.2-linux-x64.tar.xz && \
#     ln -s /opt/local/node-v8.11.2-linux-x64/bin/npm /opt/local/bin && \
#     ln -s /opt/local/node-v8.11.2-linux-x64/bin/node /opt/local/bin


# Add user "drupal"
RUN rm -rf /var/www && \
    useradd drupal --home-dir /var/www --create-home --user-group --groups www-data --shell /bin/bash && \
    mkdir -p /var/www/tools /var/www/bin && \
    echo "PATH=/var/www/bin:/opt/local/bin:/var/www/.composer/vendor/bin:$PATH " >> /var/www/.bashrc && \
    chown -R drupal:drupal /var/www && \
    echo "drupal:drupal" | chpasswd

COPY app/build/ssh/* /var/www/.ssh/
RUN chmod 700 /var/www/.ssh/ && chown 600 /var/www/.ssh/* && chown -R drupal:drupal /var/www/.ssh/


#  Database credentials for user (MariaDB is another container).
RUN printf "[client] \nuser=root \npassword=$MYSQL_ROOT_PASSWORD \nhost=mysql \nprotocol=tcp \nport=3306 \n" >> /var/www/.my.cnf

# Install Composer.
# RUN curl -sS https://getcomposer.org/installer | php && \
#     mv composer.phar /usr/bin/composer

# Install Drush 8.
ENV PATH="/var/www/bin:${PATH}"

RUN mkdir -p $APACHE_DOCUMENT_ROOT && echo "<?php phpinfo(); " >> "${APACHE_DOCUMENT_ROOT}index.php"

# Composer speedup.
# RUN su drupal -c "/usr/bin/composer global require hirak/prestissimo \
#                   && /usr/bin/composer global require drush/drush:8.*"

# Install Drupal Console.
# RUN su drupal -c "curl https://drupalconsole.com/installer -L -o /var/www/bin/drupal && chmod +x /var/www/bin/drupal && \
#                   /var/www/bin/drupal init --yes --no-interaction --destination /var/www/.console/ --autocomplete && \
#                   echo 'source /var/www/bin/.console/console.rc' >> /var/www/.bashrc"

# RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# RUN apt-get install nodejs


# Install Drupal.
# RUN su drupal -c  "/usr/bin/composer create-project drupal-composer/drupal-project:~8.0 /var/www/drupal --stability dev --no-interaction --no-install"

# We will use composer.json and composer.lock as provided.
COPY app/build/composer.* /var/www/drupal/.

# Scaffold
COPY app/build/scaffold /var/www/drupal/web/sites
RUN cd  /var/www/drupal/web/sites/default/ && \
    cp default.settings.php settings.php && \
    cp default.services.yml services.yml

RUN cd /var/www && \
  chmod 666 /var/www/drupal/web/sites/default/settings.php /var/www/drupal/web/sites/default/services.yml && \
  mkdir drupal/files_private -p && \
  chmod 777 drupal/files_private && \
  mkdir drupal/web/modules/contrib -p && \
  mkdir drupal/web/themes/contrib -p && \
  mkdir drupal/web/profiles/contrib -p && \
  chown -R drupal:www-data drupal/web

# RUN su drupal -c "/usr/bin/composer install --working-dir /var/www/drupal"

# COPY app/run/ /var/www/scripts/
# RUN chown -R drupal:drupal /var/www/scripts/ && \
#     chmod 700 /var/www/scripts/*

EXPOSE 80 22 443

# CMD exec supervisord -n
COPY default.env /var/www/drupal/.env

ENTRYPOINT chown -R drupal:www-data /var/www/drupal/web && \
           service ssh restart && \
           service apache2 start && \
#            su drupal /var/www/scripts/install-drupal.sh && \
           bash
