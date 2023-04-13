#!/bin/bash

# Variables de configuración de AWS CLI
aws_access_key="AKIAWMGWI7QEM3S7YNDN"
aws_secret_access_key="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"
aws_default_region="us-east-1"

# Comprobar si AWS CLI está instalado
if ! command -v aws &> /dev/null; then
    echo "AWS CLI no está instalado. Por favor, instala AWS CLI y vuelve a intentarlo."
    exit 1
fi

# Configurar AWS CLI con las credenciales y región especificadas
echo "Configurando AWS CLI..."
aws configure set aws_access_key_id "$aws_access_key"
aws configure set aws_secret_access_key "$aws_secret_access_key"
aws configure set default.region "$aws_default_region"
aws configure set output.format json

echo "AWS CLI ha sido configurado exitosamente."
