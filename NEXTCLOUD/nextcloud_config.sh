#!/bin/bash
# nextcloud_config.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled/"
HTML_PATH="/var/www"
PARENT_DIR="$( dirname "$CURRENT_PATH" )" # Get the parent directory of the current directory
host="nextcloud"
server_ip="3.220.58.75"
config_path="/etc/nginx/sites-available/$host"
site_root="$HTML_PATH/$host"
GID="10000"
GID_NAME="www-data"
UID_NAME="www-data"
CERTS_FILE="generate_certs.sh"
CERTS_PATH="$PARENT_DIR/Dovecot/$CERTS_FILE"

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

function uninstall_apache2() {
  echo "Desintalando apache2 del sistema...."
  sudo systemctl stop apache2
  sudo apt-get remove apache2 -y
  sudo apt-get purge apache2 -y
  echo "Apache2 ha sido desintalado del sistema."
}

function restart_nginx() {
  echo "Reiniciando servicio Nginx..."
  sudo service nginx restart
}

function get_php_fpm_version() {
    # Buscar la ubicación del binario de php-fpm
    php_fpm_path=$(whereis -b php-fpm | awk '{print $2}')

    if [ -z "$php_fpm_path" ]; then
        echo "PHP-FPM no encontrado en el sistema."
        return
    fi

    # Obtener la versión de PHP-FPM
    version_output=$("$php_fpm_path" -v 2>&1)
    regex="PHP ([0-9]+\.[0-9]+)"

    if [[ $version_output =~ $regex ]]; then
        version_number="${BASH_REMATCH[1]}"
        echo "Versión de PHP-FPM: $version_number"
    else
        echo "No se pudo obtener la versión de PHP-FPM."
    fi
}
# Funcion para configurar Nginx
function configure_nginx() {
  echo "Configurando NGINX..."
  
  if ! sudo tee "$config_path" >/dev/null <<EOF
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
  if ! sudo touch "$config_path"; then
    echo "Error: No se pudo crear el archivo de configuración de NGINX."
    return 1
  fi
  echo "Archivo de configuración creado: $config_path"
  echo "Editando el archivo de configuración..."
  # Editar el archivo de configuración
  
  echo "server {
  listen 80;
  server_name $server_ip;
  root $site_root;
  index index.php;
  #return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    server_name $server_ip;

    # Configura los certificados SSL
    ssl_certificate $PEM_PATH;
    ssl_certificate_key $KEY_PATH;

    # Configura la ubicación de los archivos de Nextcloud
    root $site_root;
    index index.php;

    # Configura las reglas de reescritura de URL
    rewrite ^/.well-known/carddav /remote.php/dav/ permanent;
    rewrite ^/.well-known/caldav /remote.php/dav/ permanent;
    rewrite ^(/core/doc/[^\/]+/)$ \$1/index.html;

    # Configura la ubicación de los archivos de registro
    access_log /var/log/nginx/nextcloud.access.log;
    error_log /var/log/nginx/nextcloud.error.log;  

    # Configura la ubicación de los archivos de caché
location = /robots.txt {
  allow all;
  log_not_found off;
  access_log off;
}

    # Configura la ubicación de los archivos de caché
location ~ ^/(?:\.htaccess|data|config|db_structure\.xml|README) {
  deny all;
}

    # Configura las reglas de reescritura de URL para PHP
location ~ ^\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+)\.php(?:$|\/) {
  fastcgi_split_path_info ^(.+\.php)(\/.+)$;
  fastcgi_pass unix:/var/run/php/php$version_number-fpm.sock;
  fastcgi_index index.php;
  include fastcgi_params;
  fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
  fastcgi_param PATH_INFO \$fastcgi_path_info;
  fastcgi_param HTTPS on;
}

 # Configura las reglas de reescritura de URL para otros archivos PHP
location ~ ^\/(?:updater|oc[ms]-provider)(?:$|\/) {
  try_files \$uri/ =404;
  index index.php;
}

  # Configura las reglas de reescritura de URL para otros archivos
location ~ \.(?:css|js|svg|gif|png|html|ttf|woff|ico|jpg|jpeg)$ {
  try_files \$uri /index.php\$request_uri;
  expires 30d;
  access_log off;
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
    sudo service php"$version_number"-fpm stop
    sudo service php"$version_number"-fpm start
    sudo service php"$version_number"-fpm status
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
  if ! sudo service php"$version_number"-fpm restart; then
    echo "Error al reiniciar el servicio php"$version_number"-fpm ."
    return 1
  fi
    if ! sudo service snap.nextcloud.nginx reload; then
    echo "Error al recargar el servicio de Nextcloud."
    return 1
  fi
  echo "Servicios reiniciados correctamente."
  return 0
  sudo service nginx status
  sudo service php"$version_number"-fpm status
}
# Función principal
function nextcloud_config() {
  echo "**********NEXTCLOUD CONFIGURATOR***********"
  read_KEY_PATH
  uninstall_apache2
  restart_nginx
  get_php_fpm_version
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
