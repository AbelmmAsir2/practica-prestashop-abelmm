#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/.env"
export DEBIAN_FRONTEND=noninteractive

if [ -f /var/lib/prestashop-installed ]; then
    echo "Instalacion ya terminada: no se reinstala."
    exit 0
fi

# Crear la base de datos y el usuario de laboratorio.
mariadb <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME}
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost'
IDENTIFIED BY '${DB_PASSWORD}';

ALTER USER '${DB_USER}'@'localhost'
IDENTIFIED BY '${DB_PASSWORD}';

GRANT ALL PRIVILEGES ON ${DB_NAME}.*
TO '${DB_USER}'@'localhost';

FLUSH PRIVILEGES;
SQL

# Preparar un directorio temporal.
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Descargar el paquete instalable.
VERSION="9.2.1"
URL="https://api.prestashop-project.org/assets/prestashop-classic/9.2.1-6.1/prestashop.zip"

echo "Descargando PrestaShop Classic $VERSION"
curl -fL --retry 3 "$URL" -o "$WORK/package.zip"

# Validar y extraer el paquete.
unzip -tq "$WORK/package.zip"

mkdir -p "$WORK/package"
unzip -qo "$WORK/package.zip" -d "$WORK/package"

if [ -f "$WORK/package/prestashop.zip" ]; then
    unzip -qo "$WORK/package/prestashop.zip" -d /var/www/html
elif [ -f "$WORK/package/install/index_cli.php" ]; then
    cp -a "$WORK/package/." /var/www/html/
else
    echo "ERROR: el paquete no contiene el instalador esperado." >&2
    find "$WORK/package" -maxdepth 2 -type f
    exit 1
fi

# Comprobar que existen las dependencias y el instalador.
if [ ! -f /var/www/html/vendor/autoload.php ]; then
    echo "ERROR: falta vendor/autoload.php." >&2
    exit 1
fi

if [ ! -f /var/www/html/install/index_cli.php ]; then
    echo "ERROR: falta install/index_cli.php." >&2
    exit 1
fi

php -r 'require "/var/www/html/vendor/autoload.php";'

rm -f /var/www/html/index.html
chown -R www-data:www-data /var/www/html

# Ejecutar la instalacion por CLI y guardar su salida.
cd /var/www/html/install

runuser -u www-data -- php index_cli.php \
    --domain="${DOMAIN}:${HTTP_PORT}" \
    --db_server=localhost \
    --db_name="$DB_NAME" \
    --db_user="$DB_USER" \
    --db_password="$DB_PASSWORD" \
    --prefix=ps_ \
    --name="$SHOP_NAME" \
    --firstname="$ADMIN_FIRSTNAME" \
    --lastname="$ADMIN_LASTNAME" \
    --email="$ADMIN_EMAIL" \
    --password="$ADMIN_PASSWORD" \
    --language=es \
    --country=es \
    --ssl=0 \
    --rewrite=1 \
    2>&1 | tee /var/log/prestashop-install.log

# Guardar el puerto HTTPS de la adaptacion local.
mariadb "$DB_NAME" <<SQL
UPDATE ps_shop_url
SET domain_ssl='${DOMAIN}:${HTTPS_PORT}';
SQL

# Retirar el instalador solo despues de finalizar correctamente.
cd /
rm -rf /var/www/html/install

if [ -d /var/www/html/admin ]; then
    mv /var/www/html/admin /var/www/html/admin_abel_lab
fi

chown -R www-data:www-data /var/www/html

# Registrar la finalizacion.
printf '%s\n' "$VERSION" > /var/lib/prestashop-installed

echo "Instalacion terminada."
echo "Tienda: http://${DOMAIN}:${HTTP_PORT}/"
echo "Administracion: comprobar ls -d /var/www/html/admin*"