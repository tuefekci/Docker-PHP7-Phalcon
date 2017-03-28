FROM ubuntu:latest
MAINTAINER Giacomo Tüfekci <kontakt@tuefekci.de>

# software-properties-common curl lynx-cur sudo
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common curl lynx-cur sudo

# Shady way of getting sudo available :/
RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo
RUN su - docker -c "touch me"

# add phalcon deb
RUN curl -s https://packagecloud.io/install/repositories/phalcon/stable/script.deb.sh | sudo bash

# Install apache, PHP, and supplimentary programs for debugging.
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install \
    apache2 php7.0 php7.0-mysql php-xdebug php7.0-xml php7.0-curl php7.0-mbstring php7.0-gd php7.0-phalcon libapache2-mod-php7.0

# Enable apache mods.
RUN a2enmod php7.0
RUN a2enmod rewrite

# Update the PHP.ini file, enable <? ?> tags and quieten logging.
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/7.0/apache2/php.ini
RUN sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 200M/" /etc/php/7.0/apache2/php.ini
RUN sed -i "s/post_max_size = 8M/post_max_size = 200M/" /etc/php/7.0/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php/7.0/apache2/php.ini

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Expose apache.
EXPOSE 80

# Copy this repo into place.
ADD public /var/www/public

# Update the default apache site with the config we created.
ADD apache-config.conf /etc/apache2/sites-enabled/000-default.conf

# By default start up apache in the foreground, override with /bin/bash for interative.
CMD /usr/sbin/apache2ctl -D FOREGROUND
