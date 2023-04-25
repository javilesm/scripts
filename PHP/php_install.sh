#! /bin/bash
# php_install.sh
# Función para instalar PHP si no está instalado
function install_php () {
  if [ $(dpkg-query -W -f='${Status}' php 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Instalando PHP..."
    if ! sudo apt install php-fpm php-cli php-common php-mysql php-mcrypt php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip php-pear php-imagick php-imap php-ldap php-tidy php-json php-bcmath php-apcu -yqq; then
      echo "No se pudo instalar PHP"
      exit 1
    fi
  else
    echo "PHP ya está instalado."
  fi
}
# Función principal
function php_install() {
    echo "*******PHP INSTALL******"
    install_php
    echo "*********ALL DONE********"
}
# Llamar a la funcion princial
php_install
