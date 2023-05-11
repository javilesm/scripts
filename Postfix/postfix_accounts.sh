#!/bin/bash
# postfix_accounts.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
ACCOUNTS_FILE="mail_users.csv"
ACCOUNTS_PATH="$CURRENT_DIR/$ACCOUNTS_FILE"
# Función para verificar si el archivo de dominios existe
function validate_accounts_file() {
    # verificar si el archivo de dominios existe
  echo "Verificando si el archivo de dominios existe..."
  if [ ! -f "$ACCOUNTS_PATH" ]; then
    echo "ERROR: El archivo de dominios '$ACCOUNTS_FILE' no se puede encontrar en la ruta '$ACCOUNTS_PATH'."
    exit 1
  fi
  echo "El archivo de dominios '$ACCOUNTS_FILE' existe."
}
# Función para leer la lista de direcciones de correo
function read_accounts() {
    # leer la lista de direcciones de correo
    echo "Leyendo la lista de dominios '$ACCOUNTS_PATH'..."
    while IFS="," read -r username nombre apellido email alias password; do
        echo "Usario: $username"
        echo "Correo principal: $email"
        echo "Correo secundario: $alias"
        echo "Contraseña: ${password:0:3}*********"
        #sudo adduser "$alias"
        #sudo mkmailbox "$alias"
        # Escribiendo datos 
        echo "${alias} ${email}" | grep -v '^$' >> "$POSTFIX_PATH/virtual"
        echo "Los datos del usuario '$username' han sido registrados en '$POSTFIX_PATH/virtual'"
        echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    done < <(grep -v '^$' "$ACCOUNTS_PATH")
    echo "Todas las cuentas de correo han sido copiadas."
}
# Función principal
function postfix_accounts() {
  echo "***************POSTFIX ACCOUNTS***************"
  validate_accounts_file
  read_accounts
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
postfix_accounts
