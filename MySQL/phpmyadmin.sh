#!/bin/bash
# phpmyadmin.sh

# Leer los datos de configuración
CONFIG_FILE="config.txt"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "El archivo de configuración no existe: $CONFIG_FILE"
  exit 1
fi

source "$CONFIG_FILE"

# Instalar phpMyAdmin
sudo apt update
sudo apt install phpmyadmin -y

# Configurar phpMyAdmin
sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
sudo phpenmod mbstring
sudo systemctl restart php7.4-fpm

# Configurar Nginx para phpMyAdmin
NGINX_CONFIG="/etc/nginx/sites-available/phpmyadmin"

if [[ ! -f "$NGINX_CONFIG" ]]; then
  echo "El archivo de configuración de Nginx no existe: $NGINX_CONFIG"
  exit 1
fi

# Actualizar la configuración de Nginx con los datos del archivo de configuración
sudo sed -i "s/your_db_host/$DB_HOST/g" "$NGINX_CONFIG"
sudo sed -i "s/your_db_user/$DB_USER/g" "$NGINX_CONFIG"
sudo sed -i "s/your_db_password/$DB_PASSWORD/g" "$NGINX_CONFIG"

# Habilitar la configuración de phpMyAdmin
sudo ln -s /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/

# Reiniciar Nginx
sudo systemctl restart nginx

echo "La instalación de phpMyAdmin se ha completado correctamente."
