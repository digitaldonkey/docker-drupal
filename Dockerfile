FROM ubuntu:17.04
MAINTAINER Thorsten Krug <email@donkeymedia.eu>
ENV DEBIAN_FRONTEND noninteractive

ENV MYSQL_ROOT_PASSWORD root

# Cache APT
# RUN echo 'Acquire::HTTP::Proxy "http://apt_cacher:3142";' >> /etc/apt/apt.conf.d/01proxy && \
#     echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

# Install packages.
RUN  apt-get update &&  apt-get install -y openssh-server \
  vim \
  wget \
  git \
  sed \
  cron \
  curl \
  apache2 \
  php7.0 \
  libapache2-mod-php7.0 \
  php7.0-cli \
  php7.0-common \
  php7.0-mbstring \
  php7.0-gd \
  php7.0-imagick \
  php7.0-intl \
  php7.0-xml \
  php7.0-mysql \
  php7.0-mcrypt \
  php7.0-zip \
  mysql-client \
  php-xdebug \
  iproute2 \
  gcc \
  xsltproc \
  make \
  nodejs

# RUN apt-get install -y \
# supervisor
# phpmyadmin


RUN apt-get clean

# Setup SSH.
RUN echo "root:root" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    mkdir /var/run/sshd && chmod 0755 /var/run/sshd && \
    mkdir -p /root/.ssh/ && touch /root/.ssh/authorized_keys && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Setup PHP.

# RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php/7.0/apache2/php.ini
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
RUN sed -i '1s/^/ServerName localhost\n/' /etc/apache2/apache2.conf && \
    sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf && \
    sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/drupal\/web/' /etc/apache2/sites-available/000-default.conf && \
    sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/drupal\/web/' /etc/apache2/sites-available/default-ssl.conf && \
    echo "Listen 8080" >> /etc/apache2/ports.conf && \
    echo "Listen 8081" >> /etc/apache2/ports.conf && \
    echo "Listen 8443" >> /etc/apache2/ports.conf && \
    sed -i 's/VirtualHost \*:80/VirtualHost \*:\*/' /etc/apache2/sites-available/000-default.conf && \
    sed -i 's/VirtualHost _default_:443/VirtualHost _default_:443 _default_:8443/' /etc/apache2/sites-available/default-ssl.conf && \
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

# NODE & NPM.
RUN curl -O https://nodejs.org/dist/v8.1.3/node-v8.1.3-linux-x64.tar.xz && \
    tar xvf node-v8.1.3-linux-x64.tar.xz && \
    mkdir -p /opt/local/bin && \
    mv node-v8.1.3-linux-x64 /opt/local && \
    rm node-v8.1.3-linux-x64.tar.xz && \
    ln -s /opt/local/node-v8.1.3-linux-x64/bin/npm /opt/local/bin && \
    ln -s /opt/local/node-v8.1.3-linux-x64/bin/node /opt/local/bin

# KeccakCodePackage for Ethereum keccac256.
RUN cd /opt/local && \
    wget https://github.com/gvanas/KeccakCodePackage/archive/master.tar.gz && \
    tar xvf master.tar.gz && \
    rm master.tar.gz && \
    cd KeccakCodePackage-master && \
    make generic64/KeccakSum && \
    mv bin/generic64/KeccakSum ../bin/keccac && \
    rm -rf KeccakCodePackage-master master.tar.gz && \
    apt-get remove --purge gcc xsltproc make -y

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
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /var/www/bin/composer

# Install Drush 8.
ENV PATH="/var/www/bin:${PATH}"
RUN su drupal -c "/var/www/bin/composer global require drush/drush:8.* && \
                  /var/www/bin/composer global update"

# Install Drupal Console.
RUN su drupal -c "curl https://drupalconsole.com/installer -L -o /var/www/bin/drupal && chmod +x /var/www/bin/drupal && \
                  /var/www/bin/drupal init --yes --no-interaction --destination /var/www/.console/ && \
                  echo 'source /var/www/bin/.console/console.rc' >> /var/www/.bashrc"

# Install Drupal.
RUN su drupal -c  "/var/www/bin/composer create-project drupal-composer/drupal-project:~8.0 /var/www/drupal --stability dev --no-interaction --no-install"

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

#   cp /var/www/sites/default/default.settings.php /var/www/sites/default/settings.php && \
#   cp /var/www/sites/default/default.services.yml /var/www/sites/default/services.yml && \
#   cp /var/www/sites/default/default.settings.php /var/www/sites/default/settings.php && \
#   cp /var/www/sites/default/default.services.yml /var/www/sites/default/services.yml && \
#   chmod 0664 /var/www/sites/default/settings.php && \
#   chmod 0664 /var/www/sites/default/services.yml && \

RUN su drupal -c "/var/www/bin/composer install --working-dir /var/www/drupal"

# RUN su drupal -c "/usr/bin/mysql -h 172.17.0.1 --execute='CREATE DATABASE IF NOT EXISTS drupal;'"

COPY app/run/ /var/www/scripts/
RUN chown -R drupal:drupal /var/www/scripts/ && \
    chmod 700 /var/www/scripts/*




# RUN su drupal -c "/var/www/.composer/vendor/bin/drush site-install standard -y --root=/var/www/drupal/web --db-url='mysql://root:root@db:3306/drupal' --account-name='admin' --account-pass='password' --site-name='drupal-ethereum' --account-mail='email@donkeymedia.eu' --site-mail='email@donkeymedia.eu' --notify='global'"

# RUN su drupal -c "/var/www/.composer/vendor/bin/drush config-import --root=/var/www/drupal/web --partial -y"

# In order to enable Simpletest, we need to download PHPUnit.
# Allow Kernel and Browser tests to be run via PHPUnit.
# RUN sed -i 's/name="SIMPLETEST_DB" value=""/name="SIMPLETEST_DB" value="sqlite:\/\/localhost\/tmp\/db.sqlite"/' /var/www/core/phpunit.xml.dist

# USER root

EXPOSE 80 22 443

# CMD exec supervisord -n

# ENTRYPOINT service ssh restart && service apache2 start && bash
ENTRYPOINT chown -R drupal:www-data /var/www/drupal/web && \
           service ssh restart && \
           service apache2 start && \
           su drupal /var/www/scripts/install-drupal.sh && \
           bash
