#!/bin/bash
# make_accounts.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
ACCOUNTS_FILE="mail_users.csv"
ACCOUNTS_PATH="$PARENT_DIR/Postfix/$ACCOUNTS_FILE"
USERS_FILE="accounts.ldif"
USERS_PATH="$CURRENT_DIR/$USERS_FILE"
MAIL_DIR="/var/mail"
LOGIN_SHELL="/usr/bin/nologin"
POSTFIX_ACCOUNTS_SCRIPT="postfix_accounts.sh"
POSTFIX_ACCOUNTS_PATH="$PARENT_DIR/Postfix/$POSTFIX_ACCOUNTS_SCRIPT"
# Cargar el contenido de script2.sh en script1.sh
source "$POSTFIX_ACCOUNTS_PATH"
# Función para crear el archivo base de usuarios, leer la lista de usuarios y escribir la informacion del usuario en el archivo base de usuarios
function read_accounts() {
  echo "Creando el archivo base de usuarios '$USERS_PATH'..."
  sudo touch "$USERS_PATH"
  
  local uidNumber=$((GID + 1))
  local gidNumber=$GID
  
  while IFS="," read -r username name lastname email alias password; do
    echo "Usuario: $username"
    echo "Nombre: $name"
    echo "Apellido: $lastname"
    echo "Dirección: $alias"
    echo "Contraseña: ${password:0:3}*********"
  
    local domain="${alias#*@}"
    domain="${domain%%.*}"
    echo "Dominio: $domain"
  
    local top_level="${alias##*.}"
    echo "Top level: $top_level"
  
    echo "Escribiendo la información del usuario en el archivo base de usuarios..."
  
    # Escribir la estructura para cada usuario en el archivo base de usuarios
    echo "dn: cn=$username,ou=People,dc=$domain,dc=$top_level" >> "$USERS_PATH"
    echo "objectClass: top" >> "$USERS_PATH"
    echo "objectClass: account" >> "$USERS_PATH"
    echo "objectClass: posixAccount" >> "$USERS_PATH"
    echo "objectClass: shadowAccount" >> "$USERS_PATH"
    echo "cn: $name.$lastname" >> "$USERS_PATH"
    echo "uid: $username" >> "$USERS_PATH"
    echo "uidNumber: $uidNumber" >> "$USERS_PATH"
    echo "gidNumber: $gidNumber" >> "$USERS_PATH"
    echo "userPassword: $password" >> "$USERS_PATH"
    echo "loginShell: $LOGIN_SHELL" >> "$USERS_PATH"
    echo "homeDirectory: $MAIL_DIR/$domain/$username" >> "$USERS_PATH"
    echo >> "$USERS_PATH"
    # crear al usuario $uidNumber
    echo "Creando al usuario '$uidNumber'..."
    sudo useradd -u "$uidNumber" -g "$gidNumber" -s "$LOGIN_SHELL" -d "$MAIL_DIR/$domain/$username" -m "$username"
    ((uidNumber++))
  done < <(grep -v '^$' "$ACCOUNTS_PATH")
  
  echo "Todas las cuentas de correo han sido copiadas."
}

function make_accounts() {
    read_accounts
}
# Llamar a la funcion principal
make_accounts
