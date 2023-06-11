#! /bin/bash
# nginx_config.sh
# Variables
HTML_PATH="/var/www"
WEB_DIR="html"
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
WP_CONFIG_FILE="wp-config.php"
WP_CONFIG_PATH="$CURRENT_DIR/$WP_CONFIG_FILE"
MYSQL_USERS_FILE="mysql_users.csv"
MYSQL_USERS_PATH="$PARENT_DIR/MySQL/$MYSQL_USERS_FILE"
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
# Función para leer la lista de dominios y crear los directorios web
function create_webdirs() {
    # leer la lista de dominios
    echo "Leyendo la lista de dominios: '$DOMAINS_PATH'..."
    while read -r hostname; do
      local host="${hostname#*@}"
      host="${host%%.*}"
      echo "Hostname: $host"
       # crear directorio web
      echo "Creando el directorio web: '$HTML_PATH/$host/$WEB_DIR'..."
      sudo mkdir -p "$HTML_PATH/$host/$WEB_DIR"
      # cambiar permisos del subdirectorio
      echo "Cambiando los permisos del subdirectorio '$HTML_PATH/$host/$WEB_DIR'..."
      sudo chmod -R 755 "$HTML_PATH/$host/$WEB_DIR"
      # cambiar la propiedad del directorio
      echo "Cambiando la propiedad del directorio '$HTML_PATH/$host/$WEB_DIR'..."
      sudo chown -R ${UID_NAME//\"/}:${GID_NAME//\"/} "$HTML_PATH/$host/$WEB_DIR"
      # Copiar plantilla index
      echo "Copiando plantilla '$INDEX_PATH' al directorio web '$HTML_PATH/$host/$WEB_DIR'..."
      sudo cp "$INDEX_PATH" "$HTML_PATH/$host/$WEB_DIR"
    done < <(grep -v '^$' "$DOMAINS_PATH")
    echo "Todas los permisos y propiedades han sido actualizados."
}
function get_php_fpm_version() {
    # Obtener la versión de PHP-FPM
    version_output=$(php -v 2>&1)
    regex="PHP ([0-9]+\.[0-9]+)"

    if [[ $version_output =~ $regex ]]; then
        version_number="${BASH_REMATCH[1]}"
        echo "Versión de PHP-FPM instalada: $version_number"
    else
        echo "No se pudo obtener la versión de PHP-FPM."
    fi
}

# Función para leer la lista de dominios y crear archivos de configuracion nginx
function create_nginx_configs() {
  local sites_enabled="/etc/nginx/sites-enabled/"
  echo "Creando archivos de configuración de Nginx..."

  while read -r hostname; do
    local host="${hostname#*@}"
    host="${host%%.*}"

    echo "Creando archivo de configuración para el dominio: $host"
    config_path="/etc/nginx/sites-available/$host"
    site_root="$HTML_PATH/$host/$WEB_DIR"

    # Crear el archivo de configuración
    echo "server {
  listen 80;
  server_name $hostname *.$hostname;
  root $site_root;
  index index.html index.php;

location / {
  try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
}

location ~ \.php$ {
  include snippets/fastcgi-php.conf;
  fastcgi_pass unix:/run/php/php$version_number-fpm.sock;
}

location = /favicon.ico {
  log_not_found off;
  access_log off;
}

location = /robots.txt {
  access_log off;
  log_not_found off;
}

location ~ /\.ht {
  deny all;
  access_log off;
  log_not_found off;
}
    
}" | sudo tee "$config_path" > /dev/null

    echo "Archivo de configuración creado: $config_path"
    echo "Creando un vínculo simbólico del archivo '$config_path' y el archivo '$sites_enabled'..."
    sudo ln -s "$config_path" "$sites_enabled"
  done < <(grep -v '^$' "$DOMAINS_PATH")

  echo "Todos los archivos de configuración de Nginx han sido creados."
}

function test_config() {
  # Comprobar la configuración de Nginx
  echo "Comprobando la configuración de Nginx..."
  if sudo nginx -t; then
    echo "Nginx se ha configurado correctamente."
    restart_services
    install_wp
    edit_wp_config
  else
    echo "ERROR: Hubo un problema con la configuración de Nginx."
    exit 1
  fi
}
# Función para leer la lista de dominios e instalar wordpress en cada sitio
function install_wp() {
    # leer la lista de dominios
    echo "Leyendo la lista de dominios: '$DOMAINS_PATH'..."
    while read -r hostname; do
      local host="${hostname#*@}"
      host="${host%%.*}"
      echo "Hostname: $host"
      sudo rm "$HTML_PATH/$host/$WEB_DIR/$INDEX_SAMPLE"
      # Copiar WordPress
      echo "Copiando plantilla '$WORDPRESS' al directorio web '$HTML_PATH/$host'..."
      sudo cp "$WORDPRESS" "$HTML_PATH/$host"
      # Desempaquietar WordPress
      echo "Desempaquetando plantilla '$HTML_PATH/$host/latest.zip' en el directorio '$HTML_PATH/$host/$WEB_DIR'..."
      if ! unzip -joq "$HTML_PATH/$host/latest.zip" -d "$HTML_PATH/$host/$WEB_DIR"; then
          echo "ERROR: Ha ocurrido un error al desempaquetar '$HTML_PATH/$host/latest.zip'."
          return 1
      fi
      echo "El archivo '$HTML_PATH/$host/latest.zip' se ha desempaquetado correctamente en el directorio '$HTML_PATH/$host/$WEB_DIR'."
      echo "$HTML_PATH/$host:"
      ls "$HTML_PATH/$host"
      # cambiar permisos del subdirectorio
      echo "Cambiando los permisos del subdirectorio '$HTML_PATH/$host/$WEB_DIR'..."
      sudo chmod -R a=r,u+w,a+X "$HTML_PATH/$host/$WEB_DIR"
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
    done < <(grep -v '^$' "$DOMAINS_PATH")
    echo "Todas los permisos y propiedades han sido actualizados."
}
# Función para leer la lista de dominios y editar el archivo wp-config.php de cada sitio
function edit_wp_config() {
  target_dir="$HTML_PATH"
  # Leer la lista de dominios
  IFS=$'\n' read -d '' -r -a dominios < "$DOMAINS_PATH"

  # Leer el archivo de usuarios de MySQL
  IFS=$'\n' read -d '' -r -a usuarios < "$MYSQL_USERS_PATH"

  # Iterar sobre la lista de dominios y usuarios
  contador=0
  for ((i=0; i<${#dominios[@]}; i++)); do
    dominio="${dominios[i]}"
    host="${dominio%%.*}"
    mounting_point="$target_dir/$host"

    # Verificar que el dominio tenga un usuario correspondiente
    if (( i >= ${#usuarios[@]} )); then
      echo "No hay suficientes usuarios de MySQL disponibles para todos los dominios."
      break
    fi

    # Obtener los datos del usuario de MySQL correspondiente al dominio actual
    usuario="${usuarios[i]}"
    IFS=',' read -r username password mysql_host database privileges <<< "$usuario"

    echo "Dominio: $host"
    echo "User: $username"
    echo "Password: $password"
    echo "MySQL Host: $mysql_host"
    echo "Database: $database"

    # Copiar plantilla wp-config.php
    echo "Copiando plantilla '$WP_CONFIG_PATH' a '$mounting_point/$WEB_DIR/$WP_CONFIG_FILE'..."
    sudo cp "$WP_CONFIG_PATH" "$mounting_point/$WEB_DIR/$WP_CONFIG_FILE"

    # Configurar wp-config.php
    echo "Configurando '$mounting_point/$WEB_DIR/$WP_CONFIG_FILE' para el dominio $host..."
    sudo sed -i "s/database_name_here/$database/g" "$mounting_point/$WEB_DIR/$WP_CONFIG_FILE"
    sudo sed -i "s/username_here/$username/g" "$mounting_point/$WEB_DIR/$WP_CONFIG_FILE"
    sudo sed -i "s/password_here/$password/g" "$mounting_point/$WEB_DIR/$WP_CONFIG_FILE"
    sudo sed -i "s/localhost/$mysql_host/g" "$mounting_point/$WEB_DIR/$WP_CONFIG_FILE"

    contador=$((contador + 1))
  done

  echo "La plantilla '$WP_CONFIG_PATH' ha sido copiada en '$contador' directorios."
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
function nginx_config() {
  echo "**********NGINX CONFIG***********"
  mkdir
  read_domains
  validate_script
  run_script
  create_webdirs
  get_php_fpm_version
  create_nginx_configs
  test_config
  restart_services
  echo "*************ALL DONE**************"
}
# Llamar a la funcion princial
nginx_config
