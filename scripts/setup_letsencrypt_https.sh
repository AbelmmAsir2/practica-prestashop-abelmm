#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/.env"
export DEBIAN_FRONTEND=noninteractive
if [ "$TLS_MODE" = "letsencrypt" ]; then
  certbot --apache --non-interactive --agree-tos --email "$CERT_EMAIL" -d "$DOMAIN" --no-redirect
else
  mkdir -p /etc/ssl/prestashop
  if [ ! -s /etc/ssl/prestashop/local.crt ]; then
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
      -keyout /etc/ssl/prestashop/local.key -out /etc/ssl/prestashop/local.crt \
      -subj "/C=ES/O=ASIR/CN=127.0.0.1" -addext "subjectAltName=IP:127.0.0.1,DNS:localhost"
    chmod 600 /etc/ssl/prestashop/local.key
  fi
  cat > /etc/apache2/sites-available/prestashop-ssl.conf <<'CONF'
<VirtualHost *:443>
    ServerName 127.0.0.1
    DocumentRoot /var/www/html
    SSLEngine on
    SSLCertificateFile /etc/ssl/prestashop/local.crt
    SSLCertificateKeyFile /etc/ssl/prestashop/local.key
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
        DirectoryIndex index.php index.html
    </Directory>
</VirtualHost>
CONF
  a2ensite prestashop-ssl
  echo "TLS local: certificado AUTOFIRMADO, no emitido por Let's Encrypt."
fi
apache2ctl configtest
systemctl reload apache2
