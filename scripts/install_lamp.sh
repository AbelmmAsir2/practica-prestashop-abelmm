#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/.env"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y apache2 mariadb-server libapache2-mod-php php-cli php-mysql php-curl php-gd php-intl php-mbstring php-xml php-zip php-bcmath php-soap php-imagick unzip curl python3 openssl certbot python3-certbot-apache
# phpMyAdmin: configure manually against the existing MariaDB service.
echo 'phpmyadmin phpmyadmin/dbconfig-install boolean false' | debconf-set-selections
echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
apt-get install -y phpmyadmin
[ ! -f /etc/apache2/conf-available/phpmyadmin.conf ] || a2enconf phpmyadmin
a2enmod rewrite ssl headers
cp "$ROOT/conf/000-default.conf" /etc/apache2/sites-available/000-default.conf
for sapi in apache2 cli; do
  mkdir -p "/etc/php/8.2/$sapi/conf.d"
  cat > "/etc/php/8.2/$sapi/conf.d/99-prestashop.ini" <<'INI'
memory_limit=512M
max_input_vars=5000
post_max_size=128M
upload_max_filesize=128M
max_execution_time=300
date.timezone=Europe/Madrid
allow_url_fopen=On
expose_php=Off
INI
done
systemctl enable --now mariadb apache2
curl -fL --retry 3 https://raw.githubusercontent.com/PrestaShop/php-ps-info/master/phppsinfo.php -o /var/www/html/phppsinfo.php
chown www-data:www-data /var/www/html/phppsinfo.php
apache2ctl configtest
systemctl restart apache2
