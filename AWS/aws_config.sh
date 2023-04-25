#!/bin/bash
# aws_config.sh
# Variables 
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )"  # Directorio de este script
CREDENTIALS_FILE="aws_credentials.txt" # Ubicacion segura de las credenciales de acceso
CREDENTIALS_PATH="$CURRENT_PATH/$CREDENTIALS_FILE" # Ruta a las credenciales de acceso
# Función para leer las credenciales desde el archivo de texto
function read_credentials() {
    # Obtener la ubicación del archivo aws_credentials.txt
    echo "Obtener la ubicación del archivo aws_credentials.txt"
    if [ -f $CREDENTIALS_PATH ]; then
        source $CREDENTIALS_PATH
    else
        echo "El archivo aws_credentials.txt no existe en la ubicación $CREDENTIALS_PATH. Por favor, cree el archivo con las variables AWS_Access_Key y AWS_Secret_Access_Key y vuelva a intentarlo."
        exit 1
    fi
}
# Función para  imprimir las credenciales de acceso
function print_credentials() {
    echo "Credenciales de acceso:"
    echo "AWS Access Key: ${AWS_Access_Key:0:3}*********"
    echo "AWS Secret Access Key: ${AWS_Secret_Access_Key:0:3}*********"
    echo "AWS Default Region: $AWS_Default_Region"
}
# Función para comprobar si AWS CLI está instalado
function check_aws_cli() {
    echo "Comprobando si AWS CLI está instalado"
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI no está instalado. Por favor, instala AWS CLI y vuelve a intentarlo."
        exit 1
    fi
}
# Función para configurar AWS CLI con las credenciales y región especificadas
function configure_aws_cli() {
    echo "Configurando AWS CLI..."
    aws configure set aws_access_key_id $AWS_Access_Key
    aws configure set aws_secret_access_key $AWS_Secret_Access_Key
    aws configure set default.region $AWS_Default_Region
}
# Función para exportar las variables de entorno
function export_variables() {
    echo "Exportando las variables de entorno"
    export AWS_ACCESS_KEY_ID=$AWS_Access_Key
    export AWS_SECRET_ACCESS_KEY=$AWS_Secret_Access_Key
    export AWS_DEFAULT_REGION=$AWS_Default_Region
}
# Función para verificar la configuración
function verify_configuration() {
    echo "Verificando la configuración"
    aws configure list
    echo "AWS CLI ha sido configurado exitosamente."
    echo "Las variables de entorno AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY y AWS_DEFAULT_REGION también han sido exportadas."
}
# Función principal para configurar AWS CLI
function aws_config() {
    echo "**********CONFIGURE AWS***********"
    read_credentials
    print_credentials
    check_aws_cli
    configure_aws_cli
    export_variables
    verify_configuration
}
# Ejecutar la función principal
aws_config
