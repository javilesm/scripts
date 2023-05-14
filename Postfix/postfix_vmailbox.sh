#!/bin/bash
# postfix_vmailbox.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
ACCOUNTS_FILE="mail_users.csv"
ACCOUNTS_PATH="$CURRENT_DIR/$ACCOUNTS_FILE"
DOMAINS_FILE="domains.txt"
DOMAINS_PATH="$CURRENT_DIR/$DOMAINS_FILE"
POSTFIX_PATH="/etc/postfix"
VMAILBOX_FILE="vmailbox" # archivo de buzones virtuales
VMAILBOX_PATH="$POSTFIX_PATH/$VMAILBOX_FILE"
VIRTUAL_ALIAS="$POSTFIX_PATH/virtual"
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
      echo "Dirección: $alias"
      echo "Contraseña: ${password:0:3}*********"
      # Obtener el dominio del correo electrónico (todo lo que está después del símbolo @)
      local domain="${alias#*@}"
      # Escribir una entrada en el archivo de buzones virtuales para el usuario y el dominio
      echo "\"$username@$domain\" \"$domain/$username/\""
      echo "$username@$domain $domain/$username/" >> "$VMAILBOX_PATH"
      echo "Los datos del usuario '$username' han sido registrados en '$VMAILBOX_PATH'"
      echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  done < <(grep -v '^$' "$ACCOUNTS_PATH")
  echo "Todas las cuentas de correo han sido copiadas."
}
# Función para leer la lista de dominios y generar los archivos de índice para los archivos de alias virtual y buzones virtuales. 
function create_index() {
  # leer la lista de dominios
  echo "Leyendo la lista de dominios..."
  while read -r domain; do
    # generar los archivos de índice para el archivo de alias virtual
    echo "Generando los archivos de índice para el alias virtual: $domain"
    postmap "$VIRTUAL_ALIAS/$domain"
  done < <(sed -e '$a\' "$DOMAINS_PATH")
  echo "Todos los archivos de índice han sido generados."
  postmap "$VMAILBOX_PATH"
}

# Función para reiniciar el servicio de Postfix
function restart_postfix() {
    # reiniciar el servicio de Postfix
    echo "Restarting Postfix service..."
    sudo service postfix restart || { echo "Error: Failed to restart Postfix service."; return 1; }
    echo "Postfix service restarted successfully."
    sudo service postfix status || { echo "Error: Failed to check Postfix status."; return 1; }
}
# Función principal
function postfix_vmailbox() {
  echo "***************POSTFIX ACCOUNTS***************"
  validate_accounts_file
  read_accounts
  create_index
  restart_postfix
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
postfix_vmailbox
