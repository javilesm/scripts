#!/bin/bash
# aws_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
AWS_CONFIG="aws_config.sh" # Script configurador
AWS_CONFIG_PATH="$CURRENT_PATH/$AWS_CONFIG"

# Función para instalar AWS CLI
function install_aws_cli() {
  echo "Instalando AWS CLI."
  install_and_restart awscli
  echo "Instalación de AWS CLI completa."
}
# Función para instalar un paquete y reiniciar los servicios afectados
function install_and_restart() {
  local package="$1"
  # Verificar si el paquete ya está instalado
  echo "Verificando si el paquete ya está instalado..."
  if dpkg -s "$package" >/dev/null 2>&1; then
    echo "El paquete '$package' ya está instalado."
    return 0
  fi

  # Instalar el paquete
  echo "Instalando $package..."
  if ! sudo apt-get install "$package" -y; then
    echo "Error: no se pudo instalar el paquete '$package'."
    return 1
  fi
  
   # Verificar si el paquete se instaló correctamente
   echo "Verificando si el paquete se instaló correctamente..."
  if [ $? -eq 0 ]; then
    echo "$package se ha instalado correctamente."
  else
    echo "Error al instalar $package."
    return 1
  fi
  
  # Buscar los servicios que necesitan reiniciarse
  echo "Buscando los servicios que necesitan reiniciarse..."
  services=$(systemctl list-dependencies --reverse "$package" | grep -oP '^\w+(?=.service)')

  # Reiniciar los servicios que dependen del paquete instalado
  echo "Reiniciando los servicios que dependen del paquete instalado..."
  if [[ -n $services ]]; then
    echo "Reiniciando los siguientes servicios: $services"
    if ! sudo systemctl restart $services; then
      echo "Error: no se pudieron reiniciar los servicios después de instalar el paquete '$package'."
      return 1
    fi
  else
    echo "No se encontraron servicios que necesiten reiniciarse después de instalar el paquete '$package'."
  fi

  echo "El paquete '$package' se instaló correctamente."
  return 0
}
# Función para instalar S3FS
function install_s3fs() {
  echo "Instalando S3FS."
  install_and_restart s3fs
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
  install_aws_cli
  install_s3fs
  check_aws_config_file
  run_aws_cli_configurator
  echo "**********ALL DONE***********"
}
# Llamar a la función principal
aws_install
