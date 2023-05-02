#!/bin/bash
# php_config.sh
# Variables
# Configurar PHP
function configure_php() {
  php_version=$(php -v | head -n 1 | cut -d " " -f 2 | cut -f1-2 -d".")
  if [ -z "$php_version" ]; then
    echo "Error: Unable to determine PHP version."
    return 1
  fi

  echo "Configurando PHP version: $php_version..."
  if sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/$php_version/fpm/php.ini &&
     sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100G/" /etc/php/$php_version/fpm/php.ini &&
     sudo sed -i "s/post_max_size = .*/post_max_size = 100G/" /etc/php/$php_version/fpm/php.ini &&
     sudo sed -i "s/max_execution_time = .*/max_execution_time = 3600/" /etc/php/$php_version/fpm/php.ini &&
     sudo sed -i "s/;date.timezone.*/date.timezone = America\/Mexico_City/" /etc/php/$php_version/fpm/php.ini; then
    echo "PHP configurado con éxito."
  else
    echo "Error al configurar PHP."
    return 1
  fi
}
# Reiniciar servicios
function restart_services() {
  sudo systemctl restart php$php_version-fpm
}
# Función principal
function php_config() {
  echo "**********PHP CONFIGURATOR***********"
  configure_php
  restart_services
  echo "**********ALL DONE***********"
}
# Llamar a la función principal
php_config
