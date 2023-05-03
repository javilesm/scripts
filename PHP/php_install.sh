#! /bin/bash
# php_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PHP_MODULES_FILE="php_modules.txt"
PHP_MODULES_PATH="$CURRENT_PATH/$PHP_MODULES_FILE" # Define la ruta del archivo de texto con los nombres de paquetes PHP
CONFIG_FILE="php_config.sh"
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"
# Función para validar si PHP está instalado
function validate_php() {
  if [ $(dpkg-query -W -f='${Status}' php 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "PHP no está instalado."
    return 1
  else
    echo "PHP ya está instalado."
    return 0
  fi
}
# Función para validar la existencia del archivo con la lista de módulos
function validate_php_modules_file() {
  echo "Validando la existencia de $PHP_MODULES_FILE..."
  if [ ! -f "$PHP_MODULES_PATH" ]; then
    echo "ERROR: no se encontró el archivo '$PHP_MODULES_FILE' en $CURRENT_PATH."
    exit 1
  fi
  echo "$PHP_MODULES_FILE existe."
}
# Función para instalar los módulos PHP del archivo php_modules.txt
function install_php_modules() {
  local php_version=$(php -v | head -n 1 | cut -d ' ' -f 2 | cut -f1-2 -d.)
  echo "Instalando módulos PHP..."
  while read module; do
    local package_name="php-${php_version}-${module}"
    if ! sudo apt-get install "$package_name" -y; then
      echo "ERROR: No se pudo instalar el módulo $module"
    else
      echo "Módulo $module instalado correctamente como $package_name."
    fi
  done < "$PHP_MODULES_PATH"
  php -m
}
# Función para validar la existencia de php_config.sh
function validate_config_file() {
  echo "Validando la existencia de $CONFIG_FILE..."
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "ERROR: no se encontró el archivo de configuración '$CONFIG_FILE' en $CURRENT_PATH."
    exit 1
  fi
  echo "$CONFIG_FILE existe."
}
# Función para ejecutar el configurador de PHP
function php_config() {
  echo "Ejecutar el configurador de PHPL..."
  # Intentar ejecutar el archivo de configuración de PHP
  if sudo bash "$CONFIG_PATH"; then
    echo "El archivo de configuración '$CONFIG_FILE' se ha ejecutado correctamente."
  else
    echo "ERROR: No se pudo ejecutar el archivo de configuración '$CONFIG_FILE'."
    exit 1
  fi
  echo "Configurador de PHP ejecutado."
}
# Función principal
function php_install() {
    echo "*******PHP INSTALL******"
    validate_php
    validate_php_modules_file
    install_php_modules
    validate_config_file
    php_config
    echo "*********ALL DONE********"
}
# Llamar a la funcion principal
php_install
