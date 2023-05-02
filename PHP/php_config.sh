#!/bin/bash
# php_config.sh
# Variables
php_version="$(php -v | head -n 1 | cut -d " " -f 2 | cut -f1-2 -d".")"
PHP_PATH="/etc/php/$php_version/fpm"
PHP_INI_FILE="php.ini"
PHP_INI_PATH="$PHP_PATH/$PHP_INI_FILE"
# Función para verificar si el archivo php.ini existe para la versión actual de PHP
function check_php_ini_exists() {
  # Verificar si el archivo php.ini existe para la versión actual de PHP
  echo "Verificando si el archivo '$PHP_INI_FILE' existe para la versión actual de PHP: $php_version..."
  if [ ! -f "$PHP_INI_PATH" ]; then
    echo "Error: '$PHP_INI_PATH' no existe. Verifique que PHP esté instalado y que la versión sea correcta."
    return 1
  fi
}
# Función para configurar PHP
function configure_php() {
  # Configurar PHP
  echo "Configurando PHP-$php_version en '$PHP_INI_PATH'..."
  if sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" $PHP_INI_PATH &&
     sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100G/" $PHP_INI_PATH &&
     sudo sed -i "s/post_max_size = .*/post_max_size = 100G/" $PHP_INI_PATH &&
     sudo sed -i "s/max_execution_time = .*/max_execution_time = 3600/" $PHP_INI_PATH &&
     sudo sed -i "s/;date.timezone.*/date.timezone = America\/Mexico_City/" $PHP_INI_PATH; then
    echo "PHP configurado con éxito."
  else
    echo "Error al configurar PHP-$php_version."
    return 1
  fi
}
# Función para reiniciar servicios de PHP
function restart_php_service() {
  # Verificar si el servicio está activo
  if sudo service --status-all | grep -i "php${php_version}-fpm" > /dev/null; then
    # Reiniciar servicios de PHP
    echo "Reiniciando servicios de PHP..."
    if sudo service "php${php_version}-fpm" restart; then
      echo "Servicio de PHP reiniciado con éxito."
    else
      echo "Error al reiniciar el servicio de PHP."
      return 1
    fi
  else
    echo "Error: El servicio de PHP-FPM no está activo en el sistema."
    return 1
  fi
}
# Función principal
function php_config() {
  echo "**********PHP CONFIGURATOR***********"
  check_php_ini_exists
  configure_php
  restart_php_service
  echo "**********ALL DONE***********"
}
# Llamar a la función principal
php_config
