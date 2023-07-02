#!/bin/bash
# phpmyadmin_install.sh
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Obtener el directorio padre del directorio actual
CONFIG_FILE="$CURRENT_DIR/phpmyadmin_config.txt"
PHPMYADMIN_PATH="/usr/share/phpmyadmin"
WEB_DIR="/var/www/samava-cloud/phpmyadmin"
USERS_FILE="$CURRENT_DIR/mysql_users.csv"

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

# Reiniciar servicios
function restart_services() {
  sudo systemctl restart nginx
  sudo systemctl restart php$PHP_VERSION-fpm
}

function get_phpmyadmin_password() {
  # Leer la contraseña de phpmyadmin desde el archivo de usuarios
  if [[ -f $USERS_FILE ]]; then
    while IFS=',' read -r usuario password host database privilege; do
      if [[ $usuario == "phpmyadmin" ]]; then
        echo "Contraseña de phpMyAdmin: $password"
        break
      fi
    done < "$USERS_FILE"
  else
    echo "El archivo de usuarios no existe."
  fi
}

function phpmyadmin_install() {
  get_php_fpm_version

  # Obtener la contraseña de phpMyAdmin
  password=$(get_phpmyadmin_password)

  # Preseleccionar el servidor Apache
  sudo echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
  sudo echo "phpmyadmin phpmyadmin/app-password-confirm password your-app-password" | sudo debconf-set-selections
  sudo echo "phpmyadmin phpmyadmin/mysql/admin-pass password $password" | sudo debconf-set-selections
  sudo echo "phpmyadmin phpmyadmin/mysql/app-pass password $password" | sudo debconf-set-selections
  sudo echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections

  install_phpmyadmin
  config_phpmyadmin
  restart_services
  get_phpmyadmin_password
}
phpmyadmin_install
