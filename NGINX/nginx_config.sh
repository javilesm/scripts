#! /bin/bash
# nginx_config.sh
# Variables
HTML_PATH="/var/www"
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
DOMAINS_FILE="domains.txt"
DOMAINS_PATH="$PARENT_DIR/Postfix/$DOMAINS_FILE"
PARTITIONS_SCRIPT="web_partitions.sh"
PARTITIONS_PATH="$CURRENT_DIR/$PARTITIONS_SCRIPT"
INDEX_SAMPLE="index.html"
INDEX_PATH="$CURRENT_DIR/$INDEX_SAMPLE"
GID="10000"
GID_NAME="www-data"
UID_NAME="www-data"
WORDPRESS="$CURRENT_DIR/latest.zip"
# Función para crear el directorio principal de Nginx
function mkdir() {
  # Verificar si el directorio ya existe
  echo "Verificando si el directorio padre '$HTML_PATH' existe..."
  if [ -d "$HTML_PATH" ]; then
    echo "El directorio padre '$HTML_PATH' ya existe en la ruta especificada."
  else
    # crear el directorio principal de Nginx
    echo "Creando el directorio principal de Nginx..."
    if sudo mkdir -p "$HTML_PATH"; then
      echo "El directorio padre '$HTML_PATH' se ha creado correctamente."
    else
      echo "Error: No se pudo crear el directorio principal de Nginx en la ruta especificada. Ruta: '$HTML_PATH'"
      exit 1
    fi
  fi
  # cambiar permisos del directorio padre
   echo "Cambiando los permisos del directorio padre '$HTML_PATH'..."
   sudo chmod -R 755 "$HTML_PATH"
}
# Función para leer la lista de direcciones de dominios y mapear  las direcciones y destinos
function read_domains() {
    # leer la lista de dominios
    echo "Leyendo la lista de dominios: '$DOMAINS_PATH'..."
    while read -r hostname; do
      local host="${hostname#*@}"
      host="${host%%.*}"
      echo "Hostname: $host"
      # crear subdirectorios para cada dominio
      echo "Creando el subdirectorio: '$HTML_PATH/$host'..."
      sudo mkdir -p "$HTML_PATH/$host"
      # cambiar permisos del subdirectorio
      echo "Cambiando los permisos del subdirectorio '$HTML_PATH/$host'..."
      sudo chmod -R 755 "$HTML_PATH/$host"
    done < <(grep -v '^$' "$DOMAINS_PATH")
    echo "Todas los permisos y propiedades han sido actualizados."
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
# Función para leer la lista de direcciones de dominios y mapear  las direcciones y destinos
function create_webdirs() {
    # leer la lista de dominios
    echo "Leyendo la lista de dominios: '$DOMAINS_PATH'..."
    while read -r hostname; do
      local host="${hostname#*@}"
      host="${host%%.*}"
      echo "Hostname: $host"
       # crear directorio web
      echo "Creando el directorio web: '$HTML_PATH/$host/html'..."
      sudo mkdir -p "$HTML_PATH/$host/html"
      # cambiar permisos del subdirectorio
      echo "Cambiando los permisos del subdirectorio '$HTML_PATH/$host/html'..."
      sudo chmod -R 755 "$HTML_PATH/$host/html"
      # cambiar la propiedad del directorio
      echo "Cambiando la propiedad del directorio '$HTML_PATH/$host/html'..."
      sudo chown -R ${UID_NAME//\"/}:${GID_NAME//\"/} "$HTML_PATH/$host/html"
      # Copiar plantilla index
      echo "Copiando plantilla '$INDEX_PATH' al directorio web '$HTML_PATH/$host/html'..."
      sudo cp "$INDEX_PATH" "$HTML_PATH/$host/html"
      # Copiar WordPress
      echo "Copiando plantilla '$WORDPRESS' al directorio web '$HTML_PATH/$host'..."
      sudo cp "$WORDPRESS" "$HTML_PATH/$host"
      # Desempaquietar WordPress
      echo "Desempaquetando plantilla '$HTML_PATH/$host/latest.zip' en el directorio '$HTML_PATH/$host/html'..."
      if ! unzip -j "$HTML_PATH/$host/latest.zip" -d "$HTML_PATH/$host/html"; then
          echo "ERROR: Ha ocurrido un error al desempaquetar '$HTML_PATH/$host/latest.zip'."
          return 1
      fi
      echo "El archivo '$HTML_PATH/$host/latest.zip' se ha desempaquetado correctamente en el directorio '$HTML_PATH/$host'."
      echo "$HTML_PATH/$host:"
      ls "$HTML_PATH/$host"
      # Eliminar el archivo comprimido
      echo "Eliminando el archivo comprimido '$HTML_PATH/$host/latest.zip'..."
      if sudo rm "$HTML_PATH/$host/latest.zip"; then
        echo "El archivo comprimido '$HTML_PATH/$host/latest.zip' se eliminó correctamente."
      else
        echo "ERROR: Error al eliminar el archivo comprimido '$HTML_PATH/$host/latest.zip'."
        return
      fi
      echo "$HTML_PATH/$host:"
      ls "$HTML_PATH/$host"
      cd "$HTML_PATH/$host/html"
      sudo mv wp-config-sample.php wp-config.php
    done < <(grep -v '^$' "$DOMAINS_PATH")
    echo "Todas los permisos y propiedades han sido actualizados."
}
function get_php_version() {
    php_version=$(php -r "echo PHP_VERSION;")
    version_number=$(echo "$php_version" | cut -d '.' -f 1,2)
    echo "PHP version: $version_number"
}

function create_nginx_configs() {
  local sites_enabled="/etc/nginx/sites-enabled/"
  echo "Creando archivos de configuración de Nginx..."
  
  while read -r hostname; do
    local host="${hostname#*@}"
    host="${host%%.*}"
    
    echo "Creando archivo de configuración para el dominio: $host"
    config_path="/etc/nginx/sites-available/$host"
    site_root="$HTML_PATH/$host/html"
    
    # Crear el archivo de configuración
    echo "server {
    listen 80;
    server_name $hostname *.$hostname;
    root $site_root;
    index index.php;

    location / {
    try_files $uri $uri/ /index.php?q=$uri&$args;
}

    location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/var/run/php/php$version_number-fpm.sock;
}

    location ~ /\.ht {
    deny all;
}

}" | sudo tee "$config_path" > /dev/null
    
    echo "Archivo de configuración creado: $config_path"
    # create a symbolic link of the site configuration file in the sites-enabled directory.
    echo "Creando un vínculo simbólico del archivo '$config_path' y el archivo '$sites_enabled'..."
    sudo ln -s $config_path $sites_enabled
  done < <(grep -v '^$' "$DOMAINS_PATH")
  echo "Todos los archivos de configuración de Nginx han sido creados."

}
function test_config() {
  # Comprobar la configuración de Nginx
  echo "Comprobando la configuración de Nginx..."
  if sudo nginx -t; then
    echo "Nginx se ha configurado correctamente."
    sudo service apache2 stop
    sudo service nginx restart
    sudo service php"$version_number"-fpm restart
  else
    echo "ERROR: Hubo un problema con la configuración de Nginx."
    exit 1
  fi
}
# Función principal
function nginx_config() {
  echo "**********NGINX CONFIG***********"
  mkdir
  read_domains
  validate_script
  run_script
  create_webdirs
  get_php_version
  create_nginx_configs
  test_config
  echo "*************ALL DONE**************"
}
# Llamar a la funcion princial
nginx_config
