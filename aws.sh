#!/bin/bash
# Script para instalar AWS CLI

AWS_CONFIG="aws_config.sh"

# Validar permisos de administrador
if [ "$(id -u)" != "0" ]; then
   echo "Este script debe ser ejecutado como root o con permisos de sudo" 1>&2
   exit 1
fi

# Actualizacion e instalacion de AWS CLI y S3FS
echo "Actualizacion e instalacion de AWS CLI y S3FS"
sudo apt-get update 
echo "Sistema actualizado"
sudo apt-get install awscli -y 
echo "Instalacion de AWS CLI completa"
sudo apt-get install s3fs -y
echo "Instalacion de S3FS completa"

echo "¡AWS CLI ha sido instalado exitosamente!"

# Obtener la ruta actual
CURRENT_PATH="$PWD"

# Verificar la existencia del archivo de configuración
if [ ! -f "$CURRENT_PATH/$AWS_CONFIG" ]; then
   echo "No se ha encontrado el archivo de configuración de AWS" 1>&2
   exit 1
fi

# Ejecutar configurador AWS CLI
echo "Ejecutando configurador de AWS CLI"
echo "Ubicacion del configurador: $CURRENT_PATH/$AWS_CONFIG"
sudo "$CURRENT_PATH/$AWS_CONFIG"
