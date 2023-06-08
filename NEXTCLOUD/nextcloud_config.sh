#!/bin/bash
# nextcloud_config.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_FILE="nextcloud_nginx.conf"
CONFIG_PATH="$CURRENT_PATH/$NGINX_CONFIG_FILE"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled/"
HTML_PATH="/var/www"
PARENT_DIR="$( dirname "$CURRENT_PATH" )" # Get the parent directory of the current directory
host="nextcloud"
NGINX_NEXTCLOUD_CONFIG="/etc/nginx/sites-available/$host"
site_root="$HTML_PATH/$host"
GID="10000"
GID_NAME="www-data"
UID_NAME="www-data"
CERTS_FILE="generate_certs.sh"
CERTS_PATH="$PARENT_DIR/Dovecot/$CERTS_FILE"
PARTITIONS_SCRIPT="nextcloud_partitions.sh"
PARTITIONS_PATH="$CURRENT_PATH/$PARTITIONS_SCRIPT"
# Función para leer la variable KEY_PATH desde el script '$CERTS_PATH'
function read_KEY_PATH() {
    # Verificar si el archivo existe
    if [ -f "$CERTS_PATH" ]; then
        # Cargar el contenido del archivo 'generate_certs.sh' en una variable
        file_contents=$(<"$CERTS_PATH")

        # Evaluar la cadena para expandir las variables
        eval "$file_contents"

        # Imprimir el valor actual de la variable KEY_PATH
        echo "El valor del KEY_PATH definido es: $KEY_PATH"
        echo "El valor del PEM_PATH definido es: $PEM_PATH"
    else
        echo "El archivo '$CERTS_PATH' no existe."
    fi
}
# Función para verificar si el archivo de configuración existe
function validate_script() {
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$PARTITIONS_PATH" ]; then
    echo "ERROR: El archivo '$PARTITIONS_SCRIPT' no se puede encontrar en la ruta '$PARTITIONS_PATH'."
    exit 1
  fi
  echo "El archivo '$PARTITIONS_SCRIPT' existe."
}
# Función para ejecutar el configurador de Postfix
function run_script() {
  echo "Ejecutar el configurador '$PARTITIONS_SCRIPT'..."
    # Intentar ejecutar el archivo de configuración de Postfix
  if sudo bash "$PARTITIONS_PATH"; then
    echo "El archivo '$PARTITIONS_SCRIPT' se ha ejecutado correctamente."
  else
    echo "ERROR: No se pudo ejecutar el archivo '$PARTITIONS_SCRIPT'."
    exit 1
  fi
  echo "Configurador '$PARTITIONS_SCRIPT' ejecutado."
}
function uninstall_apache2() {
  echo "Desintalando apache2 del sistema...."
  sudo systemctl stop apache2
  sudo apt-get remove apache2
  sudo apt-get purge apache2
  echo "Apache2 ha sido desintalado del sistema."
}

function restart_nginx() {
  echo "Reiniciando servicio Nginx..."
  sudo service nginx restart
}
# Funcion para remover el archivo de configuracion
function remove_default_config() {
  # remover el archivo de configuracion
  echo "Removiendo archivo de configuracion..."
  sudo rm "$NGINX_SITES_ENABLED/default"
}
# Funcion para configurar Nginx
function configure_nginx() {
  echo "Configurando NGINX..."
  
  if ! sudo tee "$NGINX_NEXTCLOUD_CONFIG" >/dev/null <<EOF
  server {
    listen 80;
    server_name '$DOMAIN';
    return 301 https://\$host\$request_uri;
  }

  server {
    listen 443 ssl http2;
    server_name '$DOMAIN';

    ssl_certificate /etc/letsencrypt/live/'$DOMAIN'/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/'$DOMAIN'/privkey.pem;

    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";

    location / {
      proxy_pass http://127.0.0.1:80;
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-Proto https;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Host \$server_name;
      proxy_set_header X-Forwarded-Port \$server_port;
      proxy_set_header X-Forwarded-Ssl on;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "Upgrade";
    }

    location = /robots.txt {
      allow all;
      log_not_found off;
      access_log off;
    }

    location ^~ /.well-known {
      allow all;
      log_not_found off;
      access_log off;
    }

    client_max_body_size 0;
  }
EOF
  then
    echo "Error: No se pudo escribir la configuración de NGINX en el archivo."
    return 1
  fi
  echo "Configuración de NGINX exitosa."
}
function create_nginx_configs() {
  # Crear el archivo de configuración
  echo "Creando archivos de configuración para el dominio: $host..."
  if ! sudo touch "$NGINX_NEXTCLOUD_CONFIG"; then
    echo "Error: No se pudo crear el archivo de configuración de NGINX."
    return 1
  fi
  echo "Archivo de configuración creado: $NGINX_NEXTCLOUD_CONFIG"
  # Editar el archivo de configuración
  echo "Editando el archivo de configuración..."
  echo "server {
  listen 80;
  server_name 3.220.58.75;
  root $site_root;
  index index.html index.php;
}" | sudo tee "$NGINX_NEXTCLOUD_CONFIG" > /dev/null

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
  echo "Creando un vínculo simbólico del archivo '$NGINX_NEXTCLOUD_CONFIG' y el archivo '$NGINX_SITES_ENABLED'..."
  if ! sudo ln -s "$NGINX_NEXTCLOUD_CONFIG" "$NGINX_SITES_ENABLED"; then
    echo "Error: No se pudo crear el enlace simbólico para el archivo de configuración de NGINX."
    return 1
  fi
}
# Función para configurar Nextcloud
function configure_nextcloud() {
  echo "Configurando Nextcloud..."
  if ! sudo nextcloud.occ maintenance:install --database "mysql" --database-name "nextcloud" --database-user "nextcloud" --database-pass "65jyykjhvbk46156" --admin-user "root" --admin-pass; then
    echo "Error al configurar Nextcloud."
    return 1
  fi
  echo "Nextcloud se ha configurado correctamente."
  return 0
}
# Función para reiniciar servicios
function restart_services() {
  echo "Reiniciando servicios..."
  if ! sudo service nginx restart; then
    echo "Error al reiniciar el servicio nginx."
    return 1
  fi
  if ! sudo service snap.nextcloud.nginx reload; then
    echo "Error al recargar el servicio de Nextcloud."
    return 1
  fi
  echo "Servicios reiniciados correctamente."
  return 0
}
# Función principal
function nextcloud_config() {
  echo "**********NEXTCLOUD CONFIGURATOR***********"
  read_KEY_PATH
  validate_script
  run_script
  uninstall_apache2
  restart_nginx
  #configure_nginx
  create_nginx_configs
  test_config
  webset
  configure_nextcloud
  restart_services
  echo "**********ALL DONE***********"
}
# Llamar a la función principal
nextcloud_config
