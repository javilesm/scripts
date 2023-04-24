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
# Función para actualizar el sistema
function update_system() {
  echo "Actualizando sistema..."
  sudo apt-get update || { echo "Ha ocurrido un error al actualizar el sistema."; exit 1; }
  echo "Sistema actualizado."
}
function nextcloud_install() {
  echo "Instalando Nextcloud..."
  sudo apt-get install nextcloud -y || { echo "Ha ocurrido un error al instalar Nextcloud."; exit 1; }
  echo "Nextcloud ha sido instalado"
}
# Función para verificar la existencia del archivo de configuración
function check_config_file() {
  if [ ! -f "$CURRENT_PATH/$NEXTCLOUD_CONFIG" ]; then
  echo "No se ha encontrado el archivo de configuración. Proporcione un archivo válido antes de continuar." 1>&2
  exit 1
  fi
}
# Función para ejecutar configurador AWS CLI
function run_configurator() {
  echo "Ejecutando configurador de NEXTCLOUD."
  echo "Ubicación del configurador: $CURRENT_PATH/$NEXTCLOUD_CONFIG"
  sudo "$CURRENT_PATH/$NEXTCLOUD_CONFIG" || { echo "Ha ocurrido un error al ejecutar el configurador."; exit 1; }
}
# Función principal
function main () {
  echo "**********NEXTCLOUD INSTALL***********"
  check_root
  update_system
  nextcloud_install
  check_config_file
  run_configurator
  echo "*************ALL DONE**************"
}
# Llamar a la función principal
main
