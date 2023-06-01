#!/bin/bash
# make_accounts.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
MAIL_ACCOUNTS_FILE="mail_users.csv"
MAIL_ACCOUNTS_PATH="$PARENT_DIR/Postfix/$MAIL_ACCOUNTS_FILE"
USERS_FILE="accounts.ldif"
USERS_PATH="$CURRENT_DIR/$USERS_FILE"
MAIL_DIR="/var/mail"
LOGIN_SHELL="/usr/bin/nologin"
POSTFIX_ACCOUNTS_SCRIPT="postfix_accounts.sh"
POSTFIX_ACCOUNTS_PATH="$PARENT_DIR/Postfix/$POSTFIX_ACCOUNTS_SCRIPT"
# Función para leer la variable GID_NAME desde el script '$POSTFIX_ACCOUNTS_PATH'
function read_GID_NAME() {
    # Leer la variable GID_NAME desde el script '$POSTFIX_ACCOUNTS_PATH'
    echo "Leyendo la variable GID_NAME desde el script '$POSTFIX_ACCOUNTS_PATH'..."
    # Verificar si el archivo existe
    if [ -f "$POSTFIX_ACCOUNTS_PATH" ]; then
        # Leer el archivo línea por línea
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Buscar la línea que define la variable GID_NAME
            if [[ "$line" =~ ^GID_NAME= ]]; then
                # Extraer el valor de la variable GID
                GID_NAME=$(echo "$line" | cut -d'=' -f2)
                export GID_NAME
                break
            fi
        done < "$POSTFIX_ACCOUNTS_PATH"
    else
        echo "El archivo '$POSTFIX_ACCOUNTS_PATH' no existe."
    fi
    echo "El valor del GID_NAME definido es: ${GID_NAME//\"/}"
}
# Función para leer la variable GID desde el script '$POSTFIX_ACCOUNTS_PATH'
function read_GID() {
    # Leer la variable GID desde el script '$POSTFIX_ACCOUNTS_PATH'
    echo "Leyendo la variable GID desde el script '$POSTFIX_ACCOUNTS_PATH'..."
    
    # Verificar si el archivo existe
    if [ -f "$POSTFIX_ACCOUNTS_PATH" ]; then
        # Leer el archivo línea por línea
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Buscar la línea que define la variable GID
            if [[ "$line" =~ ^GID= ]]; then
                # Extraer el valor de la variable GID
                GID=$(echo "$line" | cut -d'=' -f2)
                export GID
                break
            fi
        done < "$POSTFIX_ACCOUNTS_PATH"
    else
        echo "El archivo '$POSTFIX_ACCOUNTS_PATH' no existe."
    fi
}
# Función para crear el archivo base de usuarios, leer la lista de usuarios y escribir la informacion del usuario en el archivo base de usuarios
function read_accounts() {
  echo "Creando el archivo base de usuarios '$USERS_PATH'..."
  sudo touch "$USERS_PATH"
  echo "El GID es: ${GID//\"/}"
  local gidNumber=${GID//\"/}
  local uidNumber=$((gidNumber + 1))
  
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
    echo "dn: cn=$username,ou=${GID_NAME//\"/},dc=$domain,dc=$top_level" >> "$USERS_PATH"
    echo "objectClass: top" >> "$USERS_PATH"
    echo "objectClass: account" >> "$USERS_PATH"
    echo "objectClass: posixAccount" >> "$USERS_PATH"
    echo "objectClass: shadowAccount" >> "$USERS_PATH"
    echo "cn: $name.$lastname" >> "$USERS_PATH"
    echo "uid: $username" >> "$USERS_PATH"
    echo "mailDrop: $alias" >> "$USERS_PATH"
    echo "mailEnabled: TRUE" >> "$USERS_PATH"
    echo "mailQuota: 1G" >> "$USERS_PATH"
    echo "uidNumber: $uidNumber" >> "$USERS_PATH"
    echo "gidNumber: $gidNumber" >> "$USERS_PATH"
    echo "userPassword: $password" >> "$USERS_PATH"
    echo "loginShell: $LOGIN_SHELL" >> "$USERS_PATH"
    echo "homeDirectory: $MAIL_DIR/$domain/$username" >> "$USERS_PATH"
    echo >> "$USERS_PATH"
    # crear al usuario $uidNumber
    echo "Creando al usuario '$uidNumber'..."
    sudo useradd -u "$uidNumber" -g "$gidNumber" -s "$LOGIN_SHELL" -d "$MAIL_DIR/$domain/$username" -m "$alias"
    ((uidNumber++))
  done < <(grep -v '^$' "$MAIL_ACCOUNTS_PATH")
  echo "Todas las cuentas de correo han sido copiadas."
  cat /etc/passwd
}
# Función principal
function make_accounts() {
  echo "***************MAKE ACCOUNTS***************"
  read_GID_NAME
  read_GID
  read_accounts
  echo "***************ALL DONE***************"
}
# Llamar a la funcion principal
make_accounts
