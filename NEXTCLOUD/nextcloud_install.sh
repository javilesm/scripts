#!/bin/bash
# nextcloud_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_FILE="nextcloud_config.sh" # Script configurador
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"
# Función para descargar la última versión de Nextcloud
function download_nextcloud() {
    local version="22.0.0"
    local url="https://download.nextcloud.com/server/releases/nextcloud-$version.zip"
    echo "Descargando la última versión de Nextcloud ($version)..."
    if ! wget -q --show-progress "$url" -O nextcloud.zip; then
        echo "Ha ocurrido un error al descargar Nextcloud."
        return 1
    fi
    echo "Nextcloud se ha descargado con éxito."
}

# Función para desempaquetar el archivo descargado
function unpack_nextcloud() {
    echo "Desempaquetando el archivo descargado..."
    if ! unzip -q nextcloud.zip; then
        echo "Ha ocurrido un error al desempaquetar Nextcloud."
        return 1
    fi
    
    if [[ ! -d "nextcloud" ]]; then
        echo "No se ha encontrado el directorio 'nextcloud' después de desempaquetar Nextcloud."
        return 1
    fi
    
    echo "El archivo se ha desempaquetado correctamente."
}
# Función para mover el directorio de Nextcloud a la raíz de Apache
function move_nextcloud() {
    echo "Moviendo el directorio de Nextcloud a la raíz de NGINX.."
    sudo mkdir -p /var/www/html/ || { echo "Ha ocurrido un error al crear el directorio de NGINX."; exit 1; }
    sudo mv nextcloud /var/www/html/ || { echo "Ha ocurrido un error al mover el directorio de Nextcloud."; exit 1; }
    if [ ! -d /var/www/html/nextcloud ]; then
        echo "Ha ocurrido un error al mover el directorio de Nextcloud."
        exit 1
    fi
    echo "El directorio de Nextcloud se ha movido correctamente."
}

# Función para darle al directorio de Nextcloud los permisos necesarios
function set_nextcloud_permissions() {
    echo "Dando al directorio de Nextcloud los permisos necesarios..."
    if sudo chown -R www-data:www-data /var/www/html/nextcloud; then
        echo "Los permisos se han establecido correctamente."
    else
        echo "Ha ocurrido un error al establecer los permisos para Nextcloud."
        exit 1
    fi
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
  validate_config_file
  nextcloud_config
  echo "*************ALL DONE**************"
}
# Llamar a la función principal
main
