# Practica 1.8 - PrestaShop con Vagrant

Adaptacion local del enunciado AWS. No implementa EC2, IP elastica ni DNS publico.
Debian 12, Apache, MariaDB, PHP 8.2 y phpMyAdmin. VM con 3 GB RAM y 2 CPU.

## Ejecucion

Desde la raiz: `vagrant up --provision`.
Los scripts se ejecutan en orden: LAMP, HTTPS y despliegue CLI.
La ultima release estable se consulta en la API de GitHub; la version instalada
queda registrada en `/var/lib/prestashop-installed`.

## Acceso local

- Tienda: http://127.0.0.1:18080/
- Diagnostico: http://127.0.0.1:18080/phppsinfo.php
- phpMyAdmin: http://127.0.0.1:18080/phpmyadmin/
- HTTPS de Apache: https://127.0.0.1:18443/
- Credenciales de laboratorio: scripts/.env. No reutilizarlas fuera del laboratorio.
- Administracion: consultar `ls -d /var/www/html/admin*` en la VM.

## HTTPS y limitaciones

TLS_MODE=local genera un certificado autofirmado. El navegador mostrara aviso:
no es un certificado valido de Let's Encrypt. La tienda se instala con HTTP
como URL canonica; configurar Apache TLS no fuerza HTTPS en PrestaShop.
El modo letsencrypt del script requiere un dominio publico real que resuelva
al servidor y acceso exterior adecuado para la validacion ACME.

## Verificacion

`vagrant ssh prestashop`

- `systemctl is-active apache2 mariadb`
- `cat /var/lib/prestashop-installed`
- `sudo cat /var/log/prestashop-install.log`
- `ls -d /var/www/html/admin*`

Antes de exponer el servidor, eliminar phppsinfo.php y restringir phpMyAdmin.
No publicar claves privadas, .vagrant ni credenciales reales.

## Evidencias

Pendiente de incorporar capturas del despliegue real. Este documento describe
la configuracion prevista y no acredita por si solo una instalacion exitosa.
