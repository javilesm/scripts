#!/bin/bash
# react_config.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled/"
HTML_PATH="/var/www"
PARENT_DIR="$( dirname "$CURRENT_PATH" )" # Get the parent directory of the current directory
host="react-app"
server_ip="3.220.58.75"
config_path="/etc/nginx/sites-available/$host"
site_root="$HTML_PATH/$host"
GID="10000"
GID_NAME="www-data"
UID_NAME="www-data"

function create_nginx_configs() {
  # Crear el archivo de configuración
  echo "Creando archivos de configuración para el dominio: $host..."
  if ! sudo touch "$config_path"; then
    echo "Error: No se pudo crear el archivo de configuración de NGINX."
    return 1
  fi
  echo "Archivo de configuración creado: $config_path"
  echo "Editando el archivo de configuración..."
  # Editar el archivo de configuración
  
  echo "server {
  listen 8000;
  server_name $server_ip;
  root $site_root;
  index index.html

  location / {
        try_files $uri $uri/ =404;
    }

}" | sudo tee "$config_path" > /dev/null

  echo "Archivo de configuración creado: $config_path"
}

function test_config() {
  # Comprobar la configuración de Nginx
  echo "Comprobando la configuración de Nginx..."
  if sudo nginx -t; then
    echo "Nginx se ha configurado correctamente."
    sudo service nginx reload
  else
    echo "ERROR: Hubo un problema con la configuración de Nginx."
    exit 1
  fi
}
function webset() {
  # cambiar permisos del subdirectorio
  echo "Cambiando los permisos del subdirectorio '$site_root'..."
  sudo chmod -R 755 "$site_root"
  # cambiar la propiedad del directorio
  echo "Cambiando la propiedad del directorio '$site_root'..."
  sudo chown -R ${UID_NAME//\"/}:${GID_NAME//\"/} "$site_root"
  # create a symbolic link of the site configuration file in the sites-enabled directory.
  echo "Creando un vínculo simbólico del archivo '$config_path' y el archivo '$NGINX_SITES_ENABLED'..."
  if ! sudo ln -s "$config_path" "$NGINX_SITES_ENABLED"; then
    echo "Error: No se pudo crear el enlace simbólico para el archivo de configuración de NGINX."
    return 1
  fi
}

# Función principal
function nextcloud_config() {
  echo "**********NEXTCLOUD CONFIGURATOR***********"
  create_nginx_configs
  test_config
  webset
  echo "**********ALL DONE***********"
}
# Llamar a la función principal
nextcloud_config
