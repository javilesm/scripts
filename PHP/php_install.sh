#! /bin/bash
# php_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PHP_MODULES_FILE="php_modules.txt"
PHP_MODULES_PATH="$CURRENT_PATH/$PHP_MODULES_FILE" # Define la ruta del archivo de texto con los nombres de paquetes PHP
CONFIG_FILE="php_config.sh"
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"
# Función para validar si PHP está instalado y obtener la versión instalada
function validate_php() {
  echo "Validando si PHP está instalado..."
  if [ $(dpkg-query -W -f='${Status}' php 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "PHP no está instalado."
    return 1
  else
    php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    echo "PHP $php_version ya está instalado."
    php -v
    return 0
  fi
}
# Función para instalar PHP
function install_php() {
   if sudo apt install php; then
    # Verifica que PHP se haya instalado correctamente
    if php -v; then
      echo "PHP instalado exitosamente."
      php -v
      return 0
    else
      echo "ERROR: no se pudo verificar la instalación de PHP."
      return 1
    fi
  else
    echo "ERROR: no se pudo instalar PHP."
    return 1
  fi
}
# Función para instalar php-common
function install_php_common() {
  # Verifica si php-common ya está instalado
  echo "Verificando si php-common ya está instalado..."
  php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
  php_common_package="php${php_version}-common"
  if dpkg -s $php_common_package > /dev/null 2>&1; then
    echo "$php_common_package ya está instalado."
    return 0
  fi
  # Instala php-common
  echo "Instalando php-common..."
  if sudo apt install -y $php_common_package; then
    echo "$php_common_package instalado exitosamente."
    return 0
  else
    echo "Error: no se pudo instalar $php_common_package."
    return 1
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
  if [ ! -f "$PHP_MODULES_PATH" ]; then
    echo "ERROR: No se encontró el archivo $PHP_MODULES_PATH."
    return 1
  fi

  echo "Instalando módulos PHP..."
  failed_modules=()

  while read module; do
    local package_name="php-${module}"
    if ! sudo apt-get install "$package_name" -y; then
      echo "ERROR: No se pudo instalar el módulo $module como $package_name."
      failed_modules+=("$module")
    else
      echo "Módulo $module instalado correctamente como $package_name."
    fi
  done < "$PHP_MODULES_PATH"

  if [ ${#failed_modules[@]} -gt 0 ]; then
    echo "Los siguientes módulos no pudieron instalarse: ${failed_modules[*]}"
    return 1
  else
    echo "Todos los módulos se instalaron correctamente."
    return 0
  fi
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
    install_php
    install_php_common
    validate_php_modules_file
    install_php_modules
    validate_config_file
    php_config
    echo "*********ALL DONE********"
}
# Llamar a la funcion principal
php_install
