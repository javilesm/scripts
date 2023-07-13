#!/bin/bash
# credentials_updater.sh

# Variables
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)" # Obtener el directorio actual
CREDENTIALS_FILE="aws_credentials.txt"
CREDENTIALS_PATH="$CURRENT_DIR/$CREDENTIALS_FILE"

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
    # Imprimir las credenciales de acceso
    echo "Imprimir las credenciales de acceso..."
    echo "AWS Access Key: ${AWS_Access_Key:0:3}*********"
    echo "AWS Secret Access Key: ${AWS_Secret_Access_Key:0:3}*********"
    echo "AWS Default Region: $AWS_Default_Region"
}

# Función para actualizar las credenciales de acceso
function update_credentials() {
    echo "Actualizando las credenciales de acceso..."
    read -p "¿Desea actualizar las credenciales de acceso? (y/n): " choice
    if [[ "$choice" == "y" ]]; then
        read -p "Ingrese la nueva AWS Access Key: " new_access_key
        read -p "Ingrese la nueva AWS Secret Access Key: " new_secret_access_key
        read -p "Ingrese la nueva AWS Default Region: " new_default_region

        # Actualizar las variables de las credenciales en el archivo aws_credentials.txt
        sed -i "s/AWS_Access_Key=.*/AWS_Access_Key=$new_access_key/" $CREDENTIALS_PATH
        sed -i "s/AWS_Secret_Access_Key=.*/AWS_Secret_Access_Key=$new_secret_access_key/" $CREDENTIALS_PATH
        sed -i "s/AWS_Default_Region=.*/AWS_Default_Region=$new_default_region/" $CREDENTIALS_PATH

        echo "Las credenciales de acceso han sido actualizadas con éxito."
    else
        echo "No se realizaron cambios en las credenciales de acceso."
    fi
}

# Función principal
function credentials_updater() {
  echo "**********CREDENTIALS UPDATER***********"
  read_credentials
  print_credentials
  update_credentials
  echo "**************ALL DONE***************"
}

# Llamar a la función principal
credentials_updater
