FROM l3iggs/lamp
MAINTAINER l3iggs <l3iggs@live.com>

# remove info.php
RUN sudo rm /srv/http/info.php

# install some owncloud optional deps
RUN sudo pacman -Suy --noconfirm --needed smbclient
#RUN pacman -Suy --noconfirm --needed ffmpeg
RUN pacman -Suy --noconfirm --needed  libreoffice-still

# Install owncloud
RUN sudo pacman -Suy --noconfirm --needed owncloud

# enable large file uploads
RUN sudo sed -i 's,;php_value upload_max_filesize 513M,php_value upload_max_filesize 30G,g' /usr/share/webapps/owncloud/.htaccess
RUN sudo sed -i 's,;php_value post_max_size 513M,php_value post_max_size 30G,g' /usr/share/webapps/owncloud/.htaccess
RUN sudo sed -i '$a php_value output_buffering Off' /usr/share/webapps/owncloud/.htaccess

# setup Apache for owncloud
RUN sudo cp /etc/webapps/owncloud/apache.example.conf /etc/httpd/conf/extra/owncloud.conf
RUN sudo sed -i '$a Include conf/extra/owncloud.conf' /etc/httpd/conf/httpd.conf
RUN sudo chown -R http:http /usr/share/webapps/owncloud/

RUN sudo sed -i 's,#SSLCertificateChainFile,SSLCertificateChainFile,g' /etc/httpd/conf/extra/httpd-ssl.conf
RUN sudo sed -i 's,/etc/httpd/conf/server-ca.crt,/https/server-ca.crt,g' /etc/httpd/conf/extra/httpd-ssl.conf
RUN sudo sed -i 's,SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5,SSLCipherSuite EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS,g' /etc/httpd/conf/extra/httpd-ssl.conf
RUN sudo sed -i 's,#SSLCARevocationCheck chain,SSLProtocol all -SSLv2 -SSLv3,g' /etc/httpd/conf/extra/httpd-ssl.conf
RUN sudo sed -i 's,#SSLHonorCipherOrder on,SSLHonorCipherOrder on,g' /etc/httpd/conf/extra/httpd-ssl.conf

RUN sudo sed -i 's,/etc/webapps/owncloud,/etc/webapps/owncloud:/dev/urandom,g' /etc/httpd/conf/extra/owncloud.conf 


# start apache and mysql
CMD cd '/usr'; sudo /usr/bin/mysqld_safe --datadir='/var/lib/mysql'& sudo apachectl -DFOREGROUND



