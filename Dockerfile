FROM debian:wheezy
MAINTAINER Ramin Banihashemi <a@ramin.it>

LABEL \
    name="Feries's LAMP5.3-Dev Image" \
    image="lamp-5.3-dev" \
    vendor="feries" \
    license="GPLv3" \
    build-date="2018-05-17"

ENV DEBIAN_FRONTEND noninteractive

ENV TERM xterm-256color
ENV APACHE_RUN_USER "www-data"
ENV APACHE_RUN_GROUP "www-data"
ENV APACHE_CONF_DIR "/etc/apache2/conf.d"
ENV APACHE_LOG_DIR "/var/log/apache2"

ADD config/90-ignore-release-date /etc/apt/apt.conf.d/
ADD config/snapshot.list /etc/apt/sources.list.d/
ADD config/preferences /etc/apt/preferences.d/

# Install all the packages
RUN apt-get update && apt-get --force-yes -y install \
    git-core \
    vim \
    wget \
    curl \
    debconf \
    htop \
    iotop \
    openssl \
    telnet \
    net-tools \
    apache2 \
    php5 \
    php5-cli \
    php5-intl \
    php5-gd \
    php5-mysql \
    php5-curl \
    php5-dev \
    php5-memcache=3.0.4-4+squeeze1 \
    php5-xsl \
    php5-xdebug=2.1.0-1 \
    php5-recode \
    php-xml-parser \
    php5-mcrypt \
    php-pear \
    mysql-client \
    locales \
    apt-transport-https \
    libxml2 \
    libxml2-utils \
    imagemagick \
    libmagickwand-dev \
    make \
    build-essential \
    g++

# Install Imagemagick
RUN pecl install -f imagick-3.1.2
RUN echo "extension=imagick.so" >> /etc/php5/apache2/php.ini

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
ADD config/yarn.list /etc/apt/sources.list.d/
RUN apt-get update
RUN apt-get --force-yes -y install yarn

# Enable php5 modules and apache rewrite
RUN a2enmod rewrite

# Clean APT
RUN apt-get -y autoremove && apt-get clean && apt-get autoclean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# SSL/HTTPS
RUN mkdir -p /etc/ssl/localcerts
RUN a2enmod ssl

# Configure timezone and locale
RUN echo "Europe/Rome" > /etc/timezone && \
	dpkg-reconfigure -f noninteractive tzdata
RUN cat /usr/share/i18n/SUPPORTED | grep -E "it_IT" > /etc/locale.gen && locale-gen && dpkg-reconfigure locales
RUN sed -i 's/\;date\.timezone\ \=/date\.timezone\ \=\ Europe\/Rome/g' /etc/php5/cli/php.ini
RUN sed -i 's/\;date\.timezone\ \=/date\.timezone\ \=\ Europe\/Rome/g' /etc/php5/apache2/php.ini

# Configure php
RUN sed -i 's/short_open_tag = On/short_open_tag = Off/g' /etc/php5/cli/php.ini
RUN sed -i 's/short_open_tag = On/short_open_tag = Off/g' /etc/php5/apache2/php.ini

RUN sed -i 's/memory_limit = -1/memory_limit = 4024M/g' /etc/php5/cli/php.ini
RUN sed -i 's/memory_limit = 128M/memory_limit = 1024M/g' /etc/php5/apache2/php.ini

RUN sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 24M/g' /etc/php5/apache2/php.ini

RUN sed -i 's/post_max_size = 8M/post_max_size = 36M/g' /etc/php5/apache2/php.ini

# Enable php html errors
RUN sed -i 's/html_errors = Off/html_errors = On/g' /etc/php5/apache2/php.ini

# Enable Xdebug
ADD config/xdebug.ini /etc/php5/conf.d/
ADD config/xdebug.ini /etc/php5/cli/conf.d/

# Load custom bashrc
RUN mv /root/.bashrc /root/.bashrc.backup
ADD config/bashrc /root/.bashrc

# Load git configuration
ADD config/gitconfig /root/.gitconfig
ADD config/gitignore_global /root/.gitignore_global

# uid 1000 workaround
# vd. https://github.com/boot2docker/boot2docker/issues/581
RUN usermod -u 1000 www-data
RUN chown -R www-data:www-data /var/lock/apache2/

RUN echo "suhosin.executor.include.whitelist = phar" >> /etc/php5/cli/conf.d/suhosin.ini

RUN mkdir -p /var/run/apache2

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set timezone
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Rome /etc/localtime
RUN "date"

# Install NVM/Node/Grunt
ENV NODE_VERSION "8.9.4"
RUN rm /bin/sh && ln -s /bin/bash /bin/sh # Replace shell with bash so we can source files
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash \
    && source /root/.nvm/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \
    && npm install -g grunt

# Aggiungo il servername fqdn
RUN echo "ServerName localhost" > "${APACHE_CONF_DIR}"/fqdn

# Run Apache
CMD [ "/usr/sbin/apache2ctl", "-D", "FOREGROUND" ]

EXPOSE 80
EXPOSE 443