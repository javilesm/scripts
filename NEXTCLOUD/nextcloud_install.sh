#!/bin/bash
# nextcloud_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_FILE="nextcloud_config.sh" # Script configurador
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"
HTML_PATH="/var/www/html"
NEXTCLOUD_DIR="nextcloud"
NEXTCLOUD_HTML_PATH="$HTML_PATH/$NEXTCLOUD_DIR"
# Funcion para crear el directorio Nextcloud
function mkdir_nextcloud() {
  # Verificar si el directorio ya existe
  if [ -d "$NEXTCLOUD_HTML_PATH" ]; then
    echo "El directorio '$NEXTCLOUD_HTML_PATH' ya existe."
    return
  fi
  # Creando el directorio Nextcloud
  echo "Creando el directorio Nextcloud..."
  if sudo mkdir -p "$NEXTCLOUD_HTML_PATH"; then
    echo "El directorio '$NEXTCLOUD_HTML_PATH' se creó correctamente."
  else
    echo "Error al crear el directorio '$NEXTCLOUD_HTML_PATH'."
  fi
}
# Función para descargar la última versión de Nextcloud
function download_nextcloud() {
    local version="26.0.1"
    local url="https://download.nextcloud.com/server/releases/nextcloud-$version.zip"
    echo "Descargando '$NEXTCLOUD_DIR' en su versión : $version..."
    if ! sudo wget -q --show-progress "$url" -O "$NEXTCLOUD_DIR".zip; then
        echo "Ha ocurrido un error al descargar $NEXTCLOUD_DIR-$version."
        return 1
    fi
    echo "$NEXTCLOUD_DIR-$version se ha descargado con éxito."
}
# Función para desempaquetar el archivo descargado
function unpack_nextcloud() {
    echo "Desempaquetando el archivo descargado..."
    if ! unzip -q "$NEXTCLOUD_DIR".zip; then
        echo "Ha ocurrido un error al desempaquetar $NEXTCLOUD_DIR.zip."
        return 1
    fi
    echo "Verificando el directorio '$NEXTCLOUD_DIR'..."
    if [[ ! -d "$NEXTCLOUD_DIR" ]]; then
        echo "No se ha encontrado el directorio '$NEXTCLOUD_DIR' después de desempaquetar $NEXTCLOUD_DIR.zip."
        return 1
    fi
    echo "El archivo $NEXTCLOUD_DIR.zip se ha desempaquetado correctamente en el directorio '$NEXTCLOUD_DIR'."
    ls "$NEXTCLOUD_HTML_PATH"
}
function rm_zip() {
   # Eliminar el archivo de descarga
  echo "Eliminando el archivo de descarga..."
  if sudo rm "$HTML_PATH/$NEXTCLOUD_DIR.zip"; then
    echo "El archivo de descarga se eliminó correctamente."
  else
    echo "Error al eliminar el archivo de descarga."
    return
  fi
  ls "$HTML_PATH"
}
# Función para darle al directorio de Nextcloud los permisos necesarios
function set_nextcloud_permissions() {
    echo "Dando al directorio '$NEXTCLOUD_HTML_PATH' los permisos necesarios..."
    if sudo chown -R www-data:www-data "$NEXTCLOUD_HTML_PATH"; then
        echo "Los permisos se han establecido correctamente al directorio '$NEXTCLOUD_HTML_PATH'."
    else
        echo "Ha ocurrido un error al establecer los permisos al directorio '$NEXTCLOUD_HTML_PATH'."
        exit 1
    fi
}
# Función para verificar si el archivo de configuración existe
function validate_config_file() {
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "ERROR: El archivo de configuración de Nextcloud no se puede encontrar."
    exit 1
  fi
  echo "El archivo de configuración de Nextcloud existe."
}
# Función para ejecutar el configurador de Nextcloud
function nextcloud_config() {
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
# Función principal
function nextcloud_install() {
  echo "**********NEXTCLOUD INSTALL***********"
    mkdir_nextcloud
    download_nextcloud
    unpack_nextcloud
    rm_zip
    set_nextcloud_permissions
    validate_config_file
    nextcloud_config
  echo "*************ALL DONE**************"
}
# Llamar a la función principal
nextcloud_install
