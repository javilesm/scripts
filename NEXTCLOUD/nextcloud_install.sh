#!/bin/bash
# nextcloud_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_FILE="nextcloud_config.sh" # Script configurador
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"
HTML_PATH="/var/www/samava-cloud"
NEXTCLOUD_DIR="nextcloud"
NEXTCLOUD_HTML_PATH="$HTML_PATH/$NEXTCLOUD_DIR"
PARTITIONS_SCRIPT="nextcloud_partitions.sh"
PARTITIONS_PATH="$CURRENT_PATH/$PARTITIONS_SCRIPT"

function make_root_dir() {
  sudo mkdir -p "$NEXTCLOUD_HTML_PATH"
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
# Funcion para descargar Nextcloud
function download_nextcloud() {
  local version="26.0.1"
  local url="https://download.nextcloud.com/server/releases/nextcloud-$version.zip"
  echo "Descargando '$NEXTCLOUD_DIR' en su versión : $version en el directorio '$HTML_PATH' ..."
  if sudo wget -q "$url" -O "$HTML_PATH/$NEXTCLOUD_DIR.zip"; then
    sleep 5
    echo "$NEXTCLOUD_DIR-$version se ha descargado con éxito en el directorio '$HTML_PATH'."
    echo "$HTML_PATH:"
    ls "$HTML_PATH"
  else
    echo "ERROR: Ha ocurrido un error al descargar $NEXTCLOUD_DIR-$version."
    return 1
  fi
}
# Función para desempaquetar el archivo descargado
function unpack_nextcloud() {
    echo "Desempaquetando el archivo descargado '$HTML_PATH/$NEXTCLOUD_DIR.zip' en el directorio '$HTML_PATH'..."
    if ! unzip -oq "$HTML_PATH/$NEXTCLOUD_DIR.zip" -d "$HTML_PATH"; then
        echo "ERROR: Ha ocurrido un error al desempaquetar $NEXTCLOUD_DIR.zip."
        return 1
    fi
    echo "El archivo $NEXTCLOUD_DIR.zip se ha desempaquetado correctamente en el directorio '$HTML_PATH."
    echo "$HTML_PATH:"
    ls "$HTML_PATH"
}

function rm_zip() {
   # Eliminar el archivo de descarga
  echo "Eliminando el archivo de descarga..."
  if sudo rm "$HTML_PATH/$NEXTCLOUD_DIR.zip"; then
    echo "El archivo de descarga se eliminó correctamente."
  else
    echo "ERROR: Error al eliminar el archivo de descarga."
    return
  fi
  echo "$HTML_PATH:"
  ls "$HTML_PATH"
}

# Función para darle al directorio de Nextcloud los permisos necesarios
function set_nextcloud_permissions() {
    echo "Dando al directorio '$NEXTCLOUD_HTML_PATH' los permisos necesarios..."
    if sudo chown -R www-data:www-data "$NEXTCLOUD_HTML_PATH"; then
        echo "Los permisos se han establecido correctamente al directorio '$NEXTCLOUD_HTML_PATH'."
    else
        echo "ERROR: Ha ocurrido un error al establecer los permisos al directorio '$NEXTCLOUD_HTML_PATH'."
        exit 1
    fi
}
# Función para verificar si el archivo de configuración existe
function validate_script2() {
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "ERROR: El archivo de configuración de Nextcloud no se puede encontrar."
    exit 1
  fi
  echo "El archivo de configuración de Nextcloud existe."
}
# Función para ejecutar el configurador de Nextcloud
function run_script2() {
  echo "Ejecutar el configurador de Nextcloud..."
    # Intentar ejecutar el archivo de configuración de Nextcloud
  if sudo bash "$CONFIG_PATH"; then
    echo "El archivo de configuración '$CONFIG_FILE' se ha ejecutado correctamente."
  else
    echo "ERROR: No se pudo ejecutar el archivo de configuración '$CONFIG_FILE'."
    exit 1
  fi
  echo "Configurador '$CONFIG_FILE' ejecutado."
}
# Función para reiniciar servicios
function restart_services() {
  echo "Reiniciando servicios..."
  if ! sudo service nginx restart; then
    echo "Error al reiniciar el servicio nginx."
    return 1
  fi
  sudo service nginx status
  sleep 2
  clear
  if ! sudo service php"$version_number"-fpm restart; then
    echo "Error al reiniciar el servicio php"$version_number"-fpm ."
    return 1
  fi
    sudo service php"$version_number"-fpm status
  sleep 2
  clear
  if ! sudo service snap.nextcloud.nginx reload; then
    echo "Error al recargar el servicio de Nextcloud."
    return 1
  fi
  echo "Servicios reiniciados correctamente."
  return 0
  
}
# Función principal
function nextcloud_install() {
  echo "**********NEXTCLOUD INSTALL***********"
  make_root_dir
  validate_script
  run_script
  download_nextcloud
  unpack_nextcloud
  rm_zip
  set_nextcloud_permissions
  validate_script2
  run_script2
  restart_services
  echo "*************ALL DONE**************"
}
# Llamar a la función principal
nextcloud_install
