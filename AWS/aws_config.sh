#!/bin/bash
# aws_config.sh
# Variables 
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"  # Directorio de este script
S3_CREDENTIALS_FILE=".s3"
S3_CREDENTIALS_PATH="$HOME/$S3_CREDENTIALS_FILE"
CREDENTIALS_FILE="aws_credentials.txt" # Ubicacion segura de las credenciales de acceso
CREDENTIALS_PATH="$CURRENT_PATH/$CREDENTIALS_FILE" # Ruta a las credenciales de acceso
# Función para leer las credenciales desde el archivo de texto
function read_credentials() {
    # Obtener la ubicación del archivo aws_credentials.txt
    echo "Obtener la ubicación del archivo '$CREDENTIALS_FILE'..."
    if [ -f $CREDENTIALS_PATH ]; then
        source $CREDENTIALS_PATH
    else
        echo "ERROR: El archivo '$CREDENTIALS_FILE' no existe en la ubicación '$CREDENTIALS_PATH'. Por favor, cree el archivo con las variables AWS_Access_Key y AWS_Secret_Access_Key y vuelva a intentarlo."
        exit 1
    fi
}
# Función para  imprimir las credenciales de acceso
function print_credentials() {
    # imprimir las credenciales de acceso
    echo "Imprimir las credenciales de acceso..."
    echo "AWS Access Key: ${AWS_Access_Key:0:3}*********"
    echo "AWS Secret Access Key: ${AWS_Secret_Access_Key:0:3}*********"
    echo "AWS Default Region: $AWS_Default_Region"
}
# Función para comprobar si AWS CLI está instalado
function check_aws_cli() {
    # comprobar si AWS CLI está instalado
    echo "Comprobando si AWS CLI está instalado..."
    if ! command -v aws &> /dev/null; then
        echo "ERROR: AWS CLI no está instalado. Por favor, instala AWS CLI y vuelve a intentarlo."
        exit 1
    fi
}
# Función para configurar AWS CLI con las credenciales y región especificadas
function configure_aws_cli() {
    # configurar AWS CLI con las credenciales y región especificadas
    echo "Configurando AWS CLI..."
    aws configure set aws_access_key_id $AWS_Access_Key
    aws configure set aws_secret_access_key $AWS_Secret_Access_Key
    aws configure set default.region $AWS_Default_Region
}
# Función para exportar las variables de entorno
function export_variables() {
    # exportar las variables de entorno
    echo "Exportando las variables de entorno..."
    source $CREDENTIALS_PATH
    export AWS_ACCESS_KEY_ID=$AWS_Access_Key
    export AWS_SECRET_ACCESS_KEY=$AWS_Secret_Access_Key
    export AWS_DEFAULT_REGION=$AWS_Default_Region
}
# Función para crear y editar el archivo de credenciales
function create_credentials_file() {
    # Verificar si el archivo de credenciales ya existe
    echo "Verificando si el archivo de credenciales ya existe..."
    if [ -f "$S3_CREDENTIALS_PATH" ]; then
        echo "El archivo de credenciales ya existe en '$S3_CREDENTIALS_PATH'"
        exit 1
    fi
    # Verificar que las credenciales de Amazon S3 se hayan proporcionado
    echo "Verificando que las credenciales de Amazon S3 se hayan proporcionado..."
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "ERROR: Debe proporcionar las credenciales de Amazon S3."
        exit 1
    fi
    # Crear el archivo de credenciales
    echo "Creando archivo de credenciales en la ruta '$S3_CREDENTIALS_PATH'..."
    if sudo touch "$S3_CREDENTIALS_PATH"; then
        # Editar el archivo de credenciales
        echo "Editando archivo de credenciales..."
        echo "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" > $S3_CREDENTIALS_PATH
        echo "Archivo de credenciales creado y editado correctamente."
    else
        echo "ERROR: No se pudo crear el archivo de credenciales."
        exit 1
    fi
}
# Función para cambiar los permisos del archivo de credenciales
function change_credentials_permissions() {
    # Verificar que el archivo de credenciales exista
    echo "Verificando que el archivo de credenciales exista..."
    if [ ! -f "$S3_CREDENTIALS_PATH" ]; then
        echo "ERROR: El archivo de credenciales no existe en '$S3_CREDENTIALS_PATH'"
        exit 1
    fi
    echo "El archivo de credenciales existe en '$S3_CREDENTIALS_PATH'"
    # Cambiar los permisos del archivo de credenciales
    echo "Cambiando permisos del archivo de credenciales..."
    if sudo chmod 600 $S3_CREDENTIALS_PATH; then
        echo "Permisos del archivo de credenciales cambiados correctamente."
    else
        echo "ERROR: No se pudieron cambiar los permisos del archivo de credenciales."
        exit 1
    fi
}
# Función para verificar la configuración de AWS
function verify_configuration() {
    # verificar la configuración de AWS
    echo "Verificando la configuración de AWS..."
    aws configure list
    echo "AWS CLI ha sido configurado exitosamente."
    echo "Las variables de entorno AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY y AWS_DEFAULT_REGION también han sido exportadas."
}
# Función principal para configurar AWS CLI
function aws_config() {
    echo "**********AWS CONFIGURE***********"
    read_credentials
    print_credentials
    check_aws_cli
    configure_aws_cli
    export_variables
    create_credentials_file
    change_credentials_permissions
    verify_configuration
    echo "**********ALL DONE***********"
}
# Ejecutar la función principal
aws_config
