#!/bin/bash
# aws_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
AWS_CONFIG="aws_config.sh" # Script configurador
AWS_CONFIG_PATH="$CURRENT_PATH/$AWS_CONFIG"
# Función para validar permisos de administrador
function validate_admin_permissions() {
  if [ "$(id -u)" != "0" ]; then
  echo "Este script debe ser ejecutado como root o con permisos de sudo." 1>&2
  exit 1
  fi
}
# Función para instalar AWS CLI
function install_aws_cli() {
  echo "Instalando AWS CLI."
  sudo apt-get install awscli -y || { echo "Ha ocurrido un error al instalar AWS CLI."; exit 1; }
  echo "Instalación de AWS CLI completa."
}
# Función para instalar S3FS
function install_s3fs() {
  echo "Instalando S3FS."
  sudo apt-get install s3fs -y || { echo "Ha ocurrido un error al instalar S3FS."; exit 1; }
  echo "Instalación de S3FS completa."
}
# Función para verificar la existencia del archivo de configuración
function check_aws_config_file() {
  if [ ! -f "$CURRENT_PATH/$AWS_CONFIG" ]; then
  echo "No se ha encontrado el archivo de configuración de AWS. Proporcione un archivo válido antes de continuar." 1>&2
  exit 1
  fi
}
# Función para ejecutar configurador AWS CLI
function run_aws_cli_configurator() {
  echo "Ejecutando configurador de AWS CLI."
  echo "Ubicación del configurador: $AWS_CONFIG_PATH"
  sudo "$AWS_CONFIG_PATH" || { echo "Ha ocurrido un error al ejecutar el configurador de AWS CLI."; exit 1; }
}
# Función principal
function aws_install () {
  echo "**********AWS INSTALL***********"
  validate_admin_permissions
  update_system
  install_aws_cli
  install_s3fs
  check_aws_config_file
  run_aws_cli_configurator
  echo "**********ALL DONE***********"
}
# Llamar a la función principal
aws_install