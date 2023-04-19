#!/bin/bash

apt update
apt install -y apache2 mariadb-server mariadb-client php php-mysqli php-gd libapache2-mod-php
cd /var/www/html/
rm index.html 
git clone https://github.com/digininja/DVWA.git .

# Copy the main config file
cp config/config.inc.php.dist config/config.inc.php

# Reconfigure options
sed -i 's/impossible/low/' config.inc.php
sed -i 's/true/false/' config.inc.php

# Make sure the apache user (www-data) owns all files in /var/www/html/
sudo chown -R www-data:www-data /var/www/html/*

#mysql -uroot -pvulnerables -e "CREATE USER app@localhost IDENTIFIED BY 'vulnerables';CREATE DATABASE dvwa;GRANT ALL privileges ON dvwa.* TO 'app'@localhost;"
mysql -uroot -pp@ssw0rd -e "CREATE USER dvwa@localhost IDENTIFIED BY 'p@ssw0rd';CREATE DATABASE dvwa;GRANT ALL privileges ON dvwa.* TO 'dvwa'@localhost;"
