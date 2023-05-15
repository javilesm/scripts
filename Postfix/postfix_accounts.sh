#!/bin/bash
# postfix_accounts.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
ACCOUNTS_FILE="mail_users.csv"
ACCOUNTS_PATH="$CURRENT_DIR/$ACCOUNTS_FILE"
POSTFIX_PATH="/etc/postfix"
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
# Función para verificar si el archivo virtual existe
function validate_virtual_file() {
  echo "Verificando si el archivo virtual existe..."
  if [ ! -f "$POSTFIX_PATH/virtual" ]; then
    echo "Creando archivo virtual en '$POSTFIX_PATH/virtual'..."
    touch "$POSTFIX_PATH/virtual"
  fi
  echo "El archivo virtual existe."
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
      echo "Dominio: $domain"
      # Escribir una entrada en el archivo de buzones virtuales para el usuario y el dominio
      echo "\"$username@$domain\" \"$domain/$username/\""
       # Escribiendo datos 
      echo "$username@$domain $domain/$username/" | grep -v '^$' >> "$POSTFIX_PATH/virtual"
      echo "Los datos del usuario '$username' han sido registrados en '$POSTFIX_PATH/virtual'"
      echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    done < <(grep -v '^$' "$ACCOUNTS_PATH")
    echo "Todas las cuentas de correo han sido copiadas."
}
# Función para mapear  las direcciones y destinos
function create_index() {
  # mapear  las direcciones y destinos
  echo "Mapeando las direcciones y destinos..."
  postmap "$POSTFIX_PATH/virtual" || { echo "Error: Failure while executing postmap on: '$POSTFIX_PATH/virtual'"; return 1; }
  echo "Las direcciones y destinos han sido mapeadas."
}
# Función para reiniciar el servicio de Postfix y el servicio de Dovecot
function restart_postfix() {
    # reiniciar el servicio de Postfix
    echo "Restarting Postfix service..."
    sudo service postfix restart || { echo "Error: Failed to restart Postfix service."; return 1; }
    echo "Postfix service restarted successfully."
    sudo service postfix status || { echo "Error: Failed to check Postfix status."; return 1; }
    # reiniciar el servicio de Dovecot
    echo "Restarting Dovecot service..."
    sudo service dovecot restart || { echo "Error: Failed to restart Dovecot service."; return 1; }
    echo "Dovecot service restarted successfully."
    sudo service dovecot status || { echo "Error: Failed to check Dovecot status."; return 1; }
}
# Función principal
function postfix_accounts() {
  echo "***************POSTFIX ACCOUNTS***************"
  validate_accounts_file
  validate_virtual_file
  read_accounts
  create_index
  restart_postfix
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
postfix_accounts
