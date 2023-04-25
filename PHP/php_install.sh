#! /bin/bash
# php_install.sh
# Variables
PHP_MODULES_FILE="php_modules.txt"
PHP_MODULES_PATH="$(dirname "$0")/$PHP_MODULES_FILE" # Define la ruta del archivo de texto con los nombres de paquetes PHP
# Función para instalar PHP si no está instalado
function install_php () {
  if [ $(dpkg-query -W -f='${Status}' php 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Instalando PHP..."
    if ! sudo apt install $(cat "$PHP_MODULES_PATH") -yqq; then
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
# Llamar a la funcion principal
php_install
