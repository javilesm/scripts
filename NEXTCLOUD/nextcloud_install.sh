#!/bin/bash
# nextcloud_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_FILE="nextcloud_config.sh" # Script configurador
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"
HTML_PATH="/var/www/html/"
NEXTCLOUD="nextcloud"
# Función para verificar si el paquete ya está instalado
function verify_nextcloud() {
    # Verifica si el paquete de Nextcloud está instalado usando dpkg
    if dpkg -s nextcloud &> /dev/null; then
        echo "Nextcloud está instalado en este sistema."
    else
        echo "Nextcloud no está instalado en este sistema."
    fi
}
# Función para descargar la última versión de Nextcloud
function download_nextcloud() {
    local version="26.0.1"
    local url="https://download.nextcloud.com/server/releases/nextcloud-$version.zip"
    echo "Descargando '$NEXTCLOUD' en su versión : $version..."
    if ! sudo wget -q --show-progress "$url" -O "$NEXTCLOUD".zip; then
        echo "Ha ocurrido un error al descargar $NEXTCLOUD-$version."
        return 1
    fi
    echo "$NEXTCLOUD-$version se ha descargado con éxito."
}
# Función para desempaquetar el archivo descargado
function unpack_nextcloud() {
    echo "Desempaquetando el archivo descargado..."
    if ! unzip -q "$NEXTCLOUD".zip; then
        echo "Ha ocurrido un error al desempaquetar "$NEXTCLOUD".zip."
        return 1
    fi
    echo "Verificando el directorio '$NEXTCLOUD'..."
    if [[ ! -d "$NEXTCLOUD" ]]; then
        echo "No se ha encontrado el directorio '$NEXTCLOUD' después de desempaquetar "$NEXTCLOUD".zip."
        return 1
    fi
    echo "El archivo "$NEXTCLOUD".zip se ha desempaquetado correctamente en el directorio '$NEXTCLOUD'."
}
# Función para mover el directorio de Nextcloud a la raíz de NGINX
function move_nextcloud() {
    # Mover el directorio de Nextcloud a la raíz de NGINX
    echo "Moviendo el directorio '$NEXTCLOUD' a la raíz de NGINX.."
    sudo mv "$NEXTCLOUD" "$HTML_PATH" || { echo "Ha ocurrido un error al mover el directorio de Nextcloud."; exit 1; }
    if [ ! -d "$HTML_PATH/$NEXTCLOUD" ]; then
        echo "Ha ocurrido un error al mover el directorio de Nextcloud."
        exit 1
    fi
    echo "El directorio '$NEXTCLOUD' se ha movido correctamente."
}
# Función para darle al directorio de Nextcloud los permisos necesarios
function set_nextcloud_permissions() {
    echo "Dando al directorio '$NEXTCLOUD' los permisos necesarios..."
    if sudo chown -R www-data:www-data "$HTML_PATH/$NEXTCLOUD"; then
        echo "Los permisos se han establecido correctamente."
    else
        echo "Ha ocurrido un error al establecer los permisos al directorio '$NEXTCLOUD'."
        exit 1
    fi
}
# Función para iniciar Nextcloud como servicio
function start_service() {
    # Iniciar Nextcloud como servicio
    echo "Iniciando Nextcloud como servicio..."
    if ! sudo service snap.nextcloud.nginx start; then
        echo "Error al iniciar Nextcloud como servicio."
        return 1
    fi

    echo "Nextcloud se ha iniciado correctamente."
    return 0
}
# Función para verificar si el archivo de configuración existe
function validate_config_file() {
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "El archivo de configuración de Nextcloud no se puede encontrar."
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
    echo "No se pudo ejecutar el archivo de configuración '$CONFIG_FILE'."
    exit 1
  fi
  echo "Configurador '$CONFIG_FILE' ejecutado."
}
# Función principal
function main () {
  echo "**********NEXTCLOUD INSTALL***********"
  download_nextcloud
  unpack_nextcloud
  move_nextcloud
  set_nextcloud_permissions
  start_service
  validate_config_file
  nextcloud_config
  echo "*************ALL DONE**************"
}
# Llamar a la función principal
main
