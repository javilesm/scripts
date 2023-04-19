#!/bin/bash
# Script para instalar AWS CLI

AWS_CONFIG="aws_setup.sh"

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

# Instalar paquetes
echo "Ejecutando configurador de AWS CLI"
echo "Ubicacion del configurador: $CURRENT_PATH/$AWS_CONFIG"
sudo "$CURRENT_PATH/$AWS_CONFIG"
