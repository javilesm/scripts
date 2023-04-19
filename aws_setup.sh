#!/bin/bash

# Variables de configuración de AWS CLI
AWS_Access_Key="AKIAWMGWI7QEM3S7YNDN"
AWS_Secret_Access_Key="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"
AWS_Default_Region="us-east-1"

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

echo "AWS CLI ha sido configurado exitosamente."
echo "Las variables de entorno AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY y AWS_DEFAULT_REGION también han sido exportadas."
