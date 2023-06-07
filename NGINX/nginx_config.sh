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
GID_NAME="$USER"
UID_NAME="$USER"
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
      echo "Creando el subdirectorio: '$HTML_PATH/$host/html'..."
      sudo mkdir -p "$HTML_PATH/$host/html"
      # cambiar permisos del subdirectorio
      echo "Cambiando los permisos del subdirectorio '$HTML_PATH/$host/html'..."
      sudo chmod -R 755 "$HTML_PATH/$host/html"
      # cambiar la propiedad del directorio
      echo "Cambiando la propiedad del directorio '$HTML_PATH/$host/html'..."
      sudo chown -R ${UID_NAME//\"/}:${GID_NAME//\"/} "$HTML_PATH/$host/html"
      # Copiar plantilla index
      echo "Copiando plantilla index..."
      sudo cp "$INDEX_PATH" "$HTML_PATH/$host/html/$INDEX_PATH"
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
function create_nginx_configs() {
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
    server_name $host;
    root $site_root;
    index index.html;
}" | sudo tee "$config_path" > /dev/null
    
    echo "Archivo de configuración creado: $config_path"
  done < <(grep -v '^$' "$DOMAINS_PATH")
  echo "Todos los archivos de configuración de Nginx han sido creados."
  sudo nginx -t
}
# Función principal
function nginx_config() {
  echo "**********NGINX CONFIG***********"
  mkdir
  validate_script
  run_script
  create_nginx_configs
  echo "*************ALL DONE**************"
}
# Llamar a la funcion princial
nginx_config
