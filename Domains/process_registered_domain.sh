#!/bin/bash
# process_registered_domain.sh

# Obtener el valor de REGISTERED_DOMAIN como argumento
host="$1"
NGINX_DIR="/var/www"
WEB_DIR="html"
WORDPRESS_DIR="$NGINX_DIR/wp_template"
WORDPRESS="$WORDPRESS_DIR/latest.zip"
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
site_root="$NGINX_DIR/$host/$WEB_DIR"
CLONE_REPO_SCRIPT="$PARENT_DIR/utilities/clone_repo.sh"
PUSH_REPO_SCRIPT="$PARENT_DIR/utilities/push_repo.sh"

# Función para obtener la versión de PHP-FPM
function get_php_fpm_version() {
    # Obtener la versión de PHP-FPM
    echo "Obteniendo la versión de PHP-FPM..."
    version_output=$(php -v 2>&1)
    regex="PHP ([0-9]+\.[0-9]+)"

    if [[ $version_output =~ $regex ]]; then
        version_number="${BASH_REMATCH[1]}"
        echo "Versión de PHP-FPM instalada: $version_number"
    else
        echo "No se pudo obtener la versión de PHP-FPM."
    fi
}

# Función para eliminar el directorio /var/html
function rm_html_dir() {
  # eliminar el directorio '$NGINX_DIR/$WEB_DIR'
  echo "Eliminando el directorio '$NGINX_DIR/$WEB_DIR'..."
  sudo rm -rf "$NGINX_DIR/$WEB_DIR"
}

# Función para ejecutar el script de clonado de repositorio Git
function clone_repo() {
  echo "Ejecutando el script '$CLONE_REPO_SCRIPT'..."
    # Intentar ejecutar el script de clonado de repositorio Git
  if sudo bash "$CLONE_REPO_SCRIPT"; then
    echo "El script '$CLONE_REPO_SCRIPT' se ha ejecutado correctamente."
  else
    echo "ERROR: No se pudo ejecutar el script '$CLONE_REPO_SCRIPT'."
    exit 1
  fi
  echo "Script '$CLONE_REPO_SCRIPT' ejecutado."
}
# Función para ejecutar el script de commit de repositorio Git
function push_repo() {
  echo "Ejecutando el script '$PUSH_REPO_SCRIPT'..."
    # Intentar ejecutar el script de commit de repositorio Git
  if sudo bash "$PUSH_REPO_SCRIPT"; then
    echo "El script '$PUSH_REPO_SCRIPT' se ha ejecutado correctamente."
  else
    echo "ERROR: No se pudo ejecutar el script '$PUSH_REPO_SCRIPT'."
    exit 1
  fi
  echo "Script '$PUSH_REPO_SCRIPT' ejecutado."
}
function make_dir(){
    # Realizar acciones con el valor DOMAIN
    echo "El valor de DOMAIN es: $host"
    # crear subdirectorios para cada dominio
    echo "Creando el subdirectorio: '$NGINX_DIR/$host'..."
    sudo mkdir -p "$NGINX_DIR/$host"
    # cambiar permisos del subdirectorio
    echo "Cambiando los permisos del subdirectorio '$NGINX_DIR/$host'..."
    sudo chmod -R 755 "$NGINX_DIR/$host"
    
    # crear directorio web
    echo "Creando el directorio web: '$site_root'..."
    sudo mkdir -p "$site_root"

  # Copiar WordPress
  echo "Copiando plantilla '$WORDPRESS' al directorio web '$NGINX_DIR/$host'..."
  sudo cp "$WORDPRESS" "$NGINX_DIR/$host"

  # Desempaquietar WordPress
  echo "Desempaquetando plantilla '$NGINX_DIR/$host/latest.zip' en el directorio '$NGINX_DIR/$host'..."
        if ! unzip -oq "$NGINX_DIR/$host/latest.zip" -d "$site_root"; then
            echo "ERROR: Ha ocurrido un error al desempaquetar '$NGINX_DIR/$host/latest.zip'."
            return 1
        fi
  echo "El archivo '$NGINX_DIR/$host/latest.zip' se ha desempaquetado correctamente en el directorio '$NGINX_DIR/$host'."
  echo "$NGINX_DIR/$host:"
  ls "$NGINX_DIR/$host"

  # Eliminar el archivo comprimido
  echo "Eliminando el archivo comprimido '$NGINX_DIR/$host/latest.zip'..."
        if sudo rm "$NGINX_DIR/$host/latest.zip"; then
          echo "El archivo comprimido '$NGINX_DIR/$host/latest.zip' se eliminó correctamente."
        else
          echo "ERROR: Error al eliminar el archivo comprimido '$NGINX_DIR/$host/latest.zip'."
          return
        fi
  echo "$NGINX_DIR/$host:"
  ls "$NGINX_DIR/$host"
}

# Función para crear archivos de configuracion nginx
function create_nginx_configs() {
    local sites_enabled="/etc/nginx/sites-enabled/"
    echo "Creando archivos de configuración de Nginx..."

    local site_root="$NGINX_DIR/$host/$WEB_DIR"
    echo "Creando archivo de configuración para el dominio: $host"
    config_path="/etc/nginx/sites-available/$host"
    # Crear el archivo de configuración

    echo "server {
    server_name $host *.$host;
    root $site_root;
    index index.php;

    location / {
        #try_files \$uri \$uri/ =404;
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php$version_number-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}" | sudo tee "$config_path" > /dev/null

    echo "Archivo de configuración creado: $config_path"
    echo "Creando un vínculo simbólico del archivo '$config_path' y el archivo '$sites_enabled'..."
    sudo ln -s "$config_path" "$sites_enabled"


  echo "Todos los archivos de configuración de Nginx han sido creados."
}

function test_config() {
  # Comprobar la configuración de Nginx
  echo "Comprobando la configuración de Nginx..."
  if sudo nginx -t; then
    echo "Nginx se ha configurado correctamente."
    restart_services
  else
    echo "ERROR: Hubo un problema con la configuración de Nginx."
    exit 1
  fi
}

function restart_services() {
  echo "Deteniendo el servicio apache2..."
  sudo service apache2 stop
  echo "Reiniciando el servicio nginx..."
  sudo service nginx restart
  echo "Reiniciando el servicio php$version_number-fpm..."
  sudo service php"$version_number"-fpm stop
  sudo service php"$version_number"-fpm start
  echo "Reiniciando el servicio mysql..."
  sudo service mysql restart
  sudo service nginx status
  sleep 2
  clear
  sudo service mysql status
  sleep 2
  clear
  sudo service php"$version_number"-fpm status
  sleep 2
  clear
}

# Función principal
function process_registered_domain() {
    echo "**********PROCESS REGISTERED DOMAINS**********"
    get_php_fpm_version
    rm_html_dir
    clone_repo
    make_dir
    create_nginx_configs
    test_config
    restart_services
    push_repo
    echo "*************ALL DONE**************"
}
# Llamar a la funcion princial
process_registered_domain
