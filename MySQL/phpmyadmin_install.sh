#!/bin/bash
# phpmyadmin_install.sh
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
CONFIG_FILE="$CURRENT_DIR/config.txt"
PHPMYADMIN_PATH="/usr/share/phpmyadmin"
WEB_DIR="/var/www/samava-cloud/phpmyadmin"

function get_php_fpm_version() {
    # Obtener la versión de PHP-FPM
    version_output=$(php -v 2>&1)
    regex="PHP ([0-9]+\.[0-9]+)"

    if [[ $version_output =~ $regex ]]; then
        version_number="${BASH_REMATCH[1]}"
        PHP_VERSION=$version_number  # Asignar la versión a la variable PHP_VERSION
        echo "Versión de PHP-FPM instalada: $PHP_VERSION"
    else
        echo "No se pudo obtener la versión de PHP-FPM."
    fi
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
  sudo systemctl restart php$PHP_VERSION-fpm
}
function phpmyadmin_install() {
  get_php_fpm_version
  read_config
  install_phpmyadmin
  config_phpmyadmin
  update_config
  restart_services
}
phpmyadmin_install
