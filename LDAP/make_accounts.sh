#!/bin/bash
# make_accounts.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
ACCOUNTS_FILE="mail_users.csv"
ACCOUNTS_PATH="$PARENT_DIR/Postfix/$ACCOUNTS_FILE"

# Función para leer la lista de direcciones de correo
function read_accounts() {
    # leer la lista de direcciones de correo
    echo "Leyendo la lista de usuarios: '$ACCOUNTS_PATH'..."
    while IFS="," read -r username name lastname email alias password; do
      echo "Usario: $username"
      echo "Nombre: $nombre"
      echo "Apellido: $lastname"
      echo "Dirección: $alias"
      echo "Contraseña: ${password:0:3}*********"
      # Obtener el dominio del correo electrónico (todo lo que está después del símbolo @)
      local domain="${alias#*@}"
      domain="${domain%%.*}"
      echo "Dominio: $domain"
      # Obtener el top level del dominio
      local top_level="${alias##*.}"
      echo "Top level: $top_level"
      # crear subdirectorio del usuario
    done < <(grep -v '^$' "$ACCOUNTS_PATH")
    echo "Todas las cuentas de correo han sido copiadas."
}

function make_accounts() {
    read_accounts
}
