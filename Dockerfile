FROM l3iggs/lamp
MAINTAINER l3iggs <l3iggs@live.com>
# Report issues here: https://github.com/l3iggs/docker-owncloud/issues
# Say thanks by adding a comment here: https://registry.hub.docker.com/u/l3iggs/owncloud/

# remove info.php
RUN rm /srv/http/info.php

RUN pacman -Sy --noconfirm

# to mount SAMBA shares: 
RUN pacman -S --noconfirm --needed smbclient

# for video file previews
RUN pacman -S --noconfirm --needed ffmpeg

# for document previews
RUN pacman -S --noconfirm --needed libreoffice-fresh
RUN pacman -R mariadb --noconfirm

# Install owncloud
RUN pacman -S --noconfirm --needed owncloud

# Install owncloud addons
RUN pacman -S --noconfirm --needed owncloud-app-bookmarks
RUN pacman -S --noconfirm --needed owncloud-app-calendar
RUN pacman -S --noconfirm --needed owncloud-app-contacts
RUN pacman -S --noconfirm --needed owncloud-app-documents
RUN pacman -S --noconfirm --needed owncloud-app-gallery

#cache
RUN pacman -S --noconfirm --needed php-apcu
RUN sed -i 's,;zend_extension=opcache.so,zend_extension=opcache.so,g' /etc/php/php.ini
RUN sed -i 's,;extension=tidy.so,extension=apcu.so,g' /etc/php/php.ini
RUN sed -i 's,memory_limit = 128M,memory_limit = 512M,g' /etc/php/php.ini 

RUN sed -i 's,open_basedir = /srv/http/:/home/:/tmp/:/usr/share/pear/:/usr/share/webapps/,open_basedir = /srv/http/:/home/:/tmp/:/usr/share/pear/:/usr/share/webapps/:/dev,g' /etc/php/php.ini 


# enable large file uploads
RUN sed -i 's,php_value upload_max_filesize 513M,php_value upload_max_filesize 30G,g' /usr/share/webapps/owncloud/.htaccess
RUN sed -i 's,php_value post_max_size 513M,php_value post_max_size 30G,g' /usr/share/webapps/owncloud/.htaccess
RUN sed -i 's,<IfModule mod_php5.c>,<IfModule mod_php5.c>\nphp_value output_buffering Off,g' /usr/share/webapps/owncloud/.htaccess

# setup Apache for owncloud
ADD owncloud.conf /etc/httpd/conf/extra/owncloud.conf
RUN sed -i 's,Options Indexes FollowSymLinks,Options -Indexes,g' /etc/httpd/conf/httpd.conf
RUN sed -i '$a Include conf/extra/owncloud.conf' /etc/httpd/conf/httpd.conf
RUN chown -R http:http /usr/share/webapps/owncloud/

RUN sed -i 's,;extension=posix.so,extension=posix.so,g' /etc/php/php.ini

#ssl
RUN sed -i 's,#SSLCertificateChainFile,SSLCertificateChainFile,g' /etc/httpd/conf/extra/httpd-ssl.conf
RUN sed -i 's,/etc/httpd/conf/server-ca.crt,/https/server-ca.crt,g' /etc/httpd/conf/extra/httpd-ssl.conf
RUN sed -i 's,SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5,SSLCipherSuite EECDH+ECDSA+AESGCM:EECDH+aRSA+AESGCM:EECDH+ECDSA+SHA384:EECDH+ECDSA+SHA256:EECDH+aRSA+SHA384:EECDH+aRSA+SHA256:EECDH+aRSA+RC4:EECDH:EDH+aRSA:RC4:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS,g' /etc/httpd/conf/extra/httpd-ssl.conf
RUN sed -i 's,#SSLCARevocationCheck chain,SSLProtocol all -SSLv2 -SSLv3,g' /etc/httpd/conf/extra/httpd-ssl.conf
RUN sed -i 's,#SSLHonorCipherOrder on,SSLHonorCipherOrder on,g' /etc/httpd/conf/extra/httpd-ssl.conf

RUN sed -i 's,#SSLCipherSuite RC4-SHA:AES128-SHA:HIGH:MEDIUM:!aNULL:!MD5,Header always add Strict-Transport-Security "max-age=15768000; includeSubDomains; preload",g' /etc/httpd/conf/extra/httpd-ssl.conf

# expose web server ports
EXPOSE 80
EXPOSE 443

# expose some important directories as volumes
VOLUME ["/usr/share/webapps/owncloud/data"]
VOLUME ["/etc/webapps/owncloud/config"]

# place your ssl cert files in here. name them server.key and server.crt
VOLUME ["/https"]

# TODO: figure out why this directory does not already exist
# RUN mkdir /run/httpd

# start apache and mysql servers
CMD cd /usr; /usr/bin/mysqld_safe --datadir=/var/lib/mysql& /usr/bin/apachectl -DFOREGROUND

