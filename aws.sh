#!/bin/bash
# Script para instalar y configurar AWS CLI
AWS_Access_Key="AKIAWMGWI7QEM3S7YNDN"
AWS_Secret_Access_Key="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"
AWS_Default_Region="us-east-1"

# Actualizacion e instalacion de AWS CLI y S3FS
echo "Actualizacion e instalacion de AWS CLI y S3FS"
sudo apt-get update 
echo "Sistema actualizado"
sudo apt-get install awscli -y 
echo "Instalacion de AWS CLI completa"
sudo apt-get install s3fs -y
echo "Instalacion de S3FS completa"

# Configurar AWS CLI
aws configure set aws_access_key_id $AWS_Access_Key
aws configure set aws_secret_access_key $AWS_Secret_Access_Key
aws configure set default.region $AWS_Default_Region

# Exportar variables de entorno
export AWS_ACCESS_KEY_ID=$AWS_Access_Key
export AWS_SECRET_ACCESS_KEY=$AWS_Secret_Access_Key
export AWS_DEFAULT_REGION=$AWS_Default_Region

# Verificar la configuración
aws configure list

echo "¡AWS CLI ha sido instalado y configurado exitosamente!"
echo "Las variables de entorno AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY y AWS_DEFAULT_REGION también han sido exportadas."