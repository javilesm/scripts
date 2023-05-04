#! /bin/bash
# php_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PHP_MODULES_FILE="php_modules.txt"
PHP_VIRTUALS_FILE="php_virtuals.txt"
PHP_PACKAGES_FILE="php_packages.txt"
CONFIG_FILE="php_config.sh"
PHP_MODULES_PATH="$CURRENT_PATH/$PHP_MODULES_FILE" # Define la ruta del archivo de texto con los nombres de paquetes PHP
PHP_VIRTUALS_PATH="$CURRENT_PATH/$PHP_VIRTUALS_FILE"
PHP_PACKAGES_PATH="$CURRENT_PATH/$PHP_PACKAGES_FILE"
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
# Función para validar si PHP está instalado y obtener la versión instalada
function validate_php() {
  echo "Validando si PHP está instalado..."
  if [ $(dpkg-query -W -f='${Status}' php 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "PHP no está instalado."
    return 1
  else
    echo "PHP $PHP_VERSION ya está instalado."
    php -v
    return 0
  fi
}
# Función para instalar PHP
function install_php() {
   if sudo apt install php -y; then
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
# Función para validar la existencia del archivo con la lista de módulos
function validate_php_modules_file() {
  echo "Validando la existencia de $PHP_MODULES_FILE..."
  if [ ! -f "$PHP_MODULES_PATH" ]; then
    echo "ERROR: no se encontró el archivo '$PHP_MODULES_FILE' en $CURRENT_PATH."
    exit 1
  fi
  echo "$PHP_MODULES_FILE existe."
}
# Función para validar la existencia del archivo con la lista de virtuales
function validate_php_virtuals_file() {
  echo "Validando la existencia de $PHP_VIRTUALS_FILE..."
  if [ ! -f "$PHP_VIRTUALS_PATH" ]; then
    echo "ERROR: no se encontró el archivo '$PHP_VIRTUALS_FILE' en $CURRENT_PATH."
    exit 1
  fi
  echo "$PHP_VIRTUALS_FILE existe."
}
# Función para validar la existencia del archivo con la lista de paquetes
function validate_php_packages_file() {
  echo "Validando la existencia de $PHP_PACKAGES_FILE..."
  if [ ! -f "$PHP_PACKAGES_PATH" ]; then
    echo "ERROR: no se encontró el archivo '$PHP_PACKAGES_FILE' en $CURRENT_PATH."
    exit 1
  fi
  echo "$PHP_PACKAGES_FILE existe."
}
# Función para instalar los módulos PHP del archivo php_modules.txt
function install_php_modules() {
  # instalar los módulos PHP del archivo php_modules.txt
  echo "Instalando módulos PHP..."
  failed_modules=()

  while read module; do
    local module_name="php-${module}"
    # Verificar si el módulo ya está instalado
    if dpkg -l | grep -q "^ii.*$module_name"; then
      echo "El módulo '$module_name' ya está instalado."
    else
      echo "Instalando módulo: '$module_name'..."
      if ! sudo apt-get install "$module_name" -y; then
        echo "ERROR: No se pudo instalar el módulo '$module' como '$module_name'."
        failed_modules+=("$module")
      else
        echo "Módulo '$module' instalado correctamente como '$module_name'."
      fi
    fi
  done < <(sed -e '$a\' "$PHP_MODULES_PATH")
}
# Función para instalar los módulos virtuales PHP del archivo php_virtuals.txt
function install_php_virtuals() {
  # instalar los módulos virtuales PHP del archivo php_virtuals.txt
  echo "Instalando módulos virtuales PHP..."
  failed_virtuals=()

  while read virtual; do
    echo "Instalando módulo: '$virtual_name'..."
    local virtual_name="php${PHP_VERSION}-${virtual}"
    if ! sudo apt-get install "$virtual_name" -y; then
      echo "ERROR: No se pudo instalar el módulo '$virtual' como '$virtual_name'."
      failed_virtuals+=("$virtual")
    else
      echo "Módulo virtual '$virtual' instalado correctamente como '$virtual_name'."
    fi
  done < <(sed -e '$a\' "$PHP_VIRTUALS_PATH")
}
# Función para instalar los paquetes PHP del archivo php_packages.txt
function install_php_packages() {
  # instalar los paquetes PHP del archivo php_packages.txt
  echo "Instalando paquetes PHP..."
  failed_packages=()

  while read package; do
    echo "Verificando si el paquete '$package' ya está instalado..."
    if dpkg -s "$package" >/dev/null 2>&1; then
      echo "Paquete '$package' ya está instalado."
    else
      echo "Instalando paquete: '$package'..."
      if ! sudo apt-get install "$package" -y; then
        echo "ERROR: No se pudo instalar el paquete '$package'."
        failed_packages+=("$package")
      else
        echo "Paquete '$package' instalado correctamente."
      fi
    fi
  done < <(sed -e '$a\' "$PHP_PACKAGES_PATH")
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
# Función para generar un reporte de instalaciones
function report() {
  if [ ${#failed_modules[@]} -gt 0 ]; then
    echo "Los siguientes módulos no pudieron instalarse: ${failed_modules[*]}"
    return 1
  else
    echo "Todos los módulos se instalaron correctamente."
    return 0
  fi

  if [ ${#failed_virtuals[@]} -gt 0 ]; then
    echo "Los siguientes módulos virtuales no pudieron instalarse: ${failed_virtuals[*]}"
    return 1
  else
    echo "Todos los módulos virtuales se instalaron correctamente."
    return 0
  fi

  if [ ${#failed_packages[@]} -gt 0 ]; then
    echo "Los siguientes paquetes no pudieron instalarse: ${failed_packages[*]}"
    return 1
  else
    echo "Todos los paquetes se instalaron correctamente."
    return 0
  fi
}
# Función principal
function php_install() {
    echo "*******PHP INSTALL******"
    validate_php
    install_php
    validate_php_modules_file
    validate_php_virtuals_file
    validate_php_packages_file
    install_php_modules
    install_php_virtuals
    install_php_packages
    validate_config_file
    php_config
    report
    echo "*********ALL DONE********"
}
# Llamar a la funcion principal
php_install

