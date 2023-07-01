#!/bin/bash
# phpmyadmin_install.sh
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
CONFIG_FILE="$CURRENT_DIR/config.txt"
PHPMYADMIN_PATH="/usr/share/phpmyadmin"
WEB_DIR="/var/www/samava-cloud/phpmyadmin"

function get_php_version() {

}
# Leer los datos de configuración
function read_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "El archivo de configuración no existe: $CONFIG_FILE"
    exit 1
  fi
  source "$CONFIG_FILE"

}
# Instalar phpMyAdmin
function install_phpmyadmin() {
  sudo apt update
  sudo apt install phpmyadmin -y
}

# Configurar phpMyAdmin
function config_phpmyadmin() {
  sudo ln -s "$PHPMYADMIN_PATH" "$WEB_DIR"
  sudo phpenmod mbstring
  sudo systemctl restart php7.4-fpm
}

# Actualizar la configuración de Nginx con los datos del archivo de configuración
function update_config() {
  sudo sed -i "s/your_db_host/$DB_HOST/g" "$NGINX_CONFIG"
  sudo sed -i "s/your_db_user/$DB_USER/g" "$NGINX_CONFIG"
  sudo sed -i "s/your_db_password/$DB_PASSWORD/g" "$NGINX_CONFIG"
}

# Reiniciar servicios
function restart_services() {
  sudo systemctl restart nginx
}
function phpmyadmin_install() {
  get_php_version
  read_config
  install_phpmyadmin
  config_phpmyadmin
  update_config
  restart_services
}
phpmyadmin_install
