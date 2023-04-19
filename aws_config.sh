#!/bin/bash
# Configurador de AWS CLI

# Obtener la ubicación del archivo aws_credentials.txt
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CREDENTIALS_FILE="$CURRENT_PATH/aws_credentials.txt"

# Leer credenciales desde archivo de texto
if [ -f $CREDENTIALS_FILE ]; then
    source $CREDENTIALS_FILE
else
    echo "El archivo aws_credentials.txt no existe en la ubicación $CREDENTIALS_FILE. Por favor, cree el archivo con las variables AWS_Access_Key y AWS_Secret_Access_Key y vuelva a intentarlo."
    exit 1
fi

# Comprobar si AWS CLI está instalado
if ! command -v aws &> /dev/null; then
    echo "AWS CLI no está instalado. Por favor, instala AWS CLI y vuelve a intentarlo."
    exit 1
fi

# Configurar AWS CLI con las credenciales y región especificadas
echo "Configurando AWS CLI..."

echo "Credenciales de acceso:"
echo "AWS Access Key: ${AWS_Access_Key:0:3}*********"
echo "AWS Secret Access Key: ${AWS_Secret_Access_Key:0:3}*********"
echo "AWS Default Region: $AWS_Default_Region"

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

