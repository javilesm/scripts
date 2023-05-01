#! /bin/bash
# php_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PHP_MODULES_FILE="php_modules.txt"
PHP_MODULES_PATH="$CURRENT_PATH/$PHP_MODULES_FILE" # Define la ruta del archivo de texto con los nombres de paquetes PHP
CONFIG_FILE="postgresql_config.sh"
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"
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
# Función para validar la existencia de php_config.sh
function validate_config_file() {
  echo "Validando la existencia de $CONFIG_FILE..."
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "Error: no se encontró el archivo de configuración $CONFIG_FILE en $CURRENT_PATH."
    exit 1
  fi
  echo "$CONFIG_FILE existe."
}
# Función para ejecutar el configurador de PHP
function php_config() {
  echo "Ejecutar el configurador de PHPL..."
  sudo bash "$CONFIG_PATH"
  echo "Configurador de PHP ejecutado."
}
# Función principal
function php_install() {
    echo "*******PHP INSTALL******"
    install_php
    validate_config_file
    php_config
    echo "*********ALL DONE********"
}
# Llamar a la funcion principal
php_install
