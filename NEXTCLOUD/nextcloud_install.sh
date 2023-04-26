#!/bin/bash
# nextcloud_install.sh
# Variables
NEXTCLOUD_CONFIG="nextcloud_config.sh" # Script configurador
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
# Función para verificar si se ejecuta el script como root
function check_root() {
  if [[ $EUID -ne 0 ]]; then
     echo "Este script debe ser ejecutado como root" 
     exit 1
  fi
}
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

# Función para verificar la existencia del archivo de configuración
function check_config_file() {
  echo "Verificando la existencia del archivo de configuración..."
  if [ ! -f "$CURRENT_PATH/$NEXTCLOUD_CONFIG" ]; then
  echo "No se ha encontrado el archivo de configuración. Proporcione un archivo válido antes de continuar." 
  exit 1
  fi
}
# Función para ejecutar configurador AWS CLI
function run_configurator() {
  echo "Ejecutando configurador de NEXTCLOUD."
  
  if [[ -f "$CURRENT_PATH/$NEXTCLOUD_CONFIG" ]]; then
    sudo "$CURRENT_PATH/$NEXTCLOUD_CONFIG" || { echo "Ha ocurrido un error al ejecutar el configurador."; exit 1; }
  else
    echo "El archivo de configuración no se encuentra en la ubicación especificada: $CURRENT_PATH/$NEXTCLOUD_CONFIG"
    exit 1
  fi
  
  echo "Configuración completada."
}
# Función principal
function main () {
  echo "**********NEXTCLOUD INSTALL***********"
  check_root
  download_nextcloud
  unpack_nextcloud
  move_nextcloud
  set_nextcloud_permissions
  check_config_file
  run_configurator
  echo "*************ALL DONE**************"
}
# Llamar a la función principal
main
