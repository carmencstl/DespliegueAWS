#!/bin/bash
apt-get update
apt-get install -y php libapache2-mod-php

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html