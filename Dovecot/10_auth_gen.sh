#!/bin/bash
# 10_auth_gen.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
LDAP_GROUPS_FILE="make_groups.sh"
LDAP_GROUPS_PATH="$PARENT_DIR/LDAP/$LDAP_GROUPS_FILE"
POSTFIX_ACCOUNTS_SCRIPT="postfix_accounts.sh"
POSTFIX_ACCOUNTS_PATH="$PARENT_DIR/Postfix/$POSTFIX_ACCOUNTS_SCRIPT"
DOVECOT_CONFIG_SCRIPT="dovecot_config.sh"
DOVECOT_CONFIG_PATH="$CURRENT_DIR/$DOVECOT_CONFIG_SCRIPT"
AUTH_FILE="10-auth.conf"
AUTH_PATH="$CURRENT_DIR/$AUTH_FILE"
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
    echo "El valor de GID es: ${GID//\"/}"
}
# Función para leer la variable GID_NAME desde el script '$POSTFIX_ACCOUNTS_PATH'
function read_GID_NAME() {
    # Leer la variable GID_NAME desde el script '$POSTFIX_ACCOUNTS_PATH'
    echo "Leyendo la variable GID desde el script '$POSTFIX_ACCOUNTS_PATH'..."
    # Verificar si el archivo existe
    if [ -f "$POSTFIX_ACCOUNTS_PATH" ]; then
        # Leer el archivo línea por línea
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Buscar la línea que define la variable GID
            if [[ "$line" =~ ^GID_NAME= ]]; then
                # Extraer el valor de la variable GID_NAME
                GID_NAME=$(echo "$line" | cut -d'=' -f2)
                export GID_NAME
                break
            fi
        done < "$POSTFIX_ACCOUNTS_PATH"
    else
        echo "El archivo '$POSTFIX_ACCOUNTS_PATH' no existe."
    fi
    echo "El valor de GID_NAME es: ${GID_NAME//\"/}"
}
# Función para leer la variable GID_NAME desde el script '$POSTFIX_ACCOUNTS_PATH'
function read_GID_NAME() {
    # Leer la variable GID_NAME desde el script '$POSTFIX_ACCOUNTS_PATH'
    echo "Leyendo la variable GID desde el script '$POSTFIX_ACCOUNTS_PATH'..."
    # Verificar si el archivo existe
    if [ -f "$POSTFIX_ACCOUNTS_PATH" ]; then
        # Leer el archivo línea por línea
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Buscar la línea que define la variable GID
            if [[ "$line" =~ ^GID_NAME= ]]; then
                # Extraer el valor de la variable GID_NAME
                GID_NAME=$(echo "$line" | cut -d'=' -f2)
                export GID_NAME
                break
            fi
        done < "$POSTFIX_ACCOUNTS_PATH"
    else
        echo "El archivo '$POSTFIX_ACCOUNTS_PATH' no existe."
    fi
    echo "El valor de GID_NAME es: ${GID_NAME//\"/}"
}
# Función para leer la variable MAIL_DIR desde el script '$LDAP_GROUPS_PATH'
function read_MAIL_DIR() {
    # Leer la variable MAIL_DIR desde el script '$LDAP_GROUPS_PATH'
    echo "Leyendo la variable MAIL_DIR desde el script '$LDAP_GROUPS_PATH'..."
    # Verificar si el archivo existe
    if [ -f "$LDAP_GROUPS_PATH" ]; then
        # Leer el archivo línea por línea
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Buscar la línea que define la variable MAIL_DIR
            if [[ "$line" =~ ^MAIL_DIR= ]]; then
                # Extraer el valor de la variable MAIL_DIR
                MAIL_DIR=$(echo "$line" | cut -d'=' -f2)
                export MAIL_DIR
                break
            fi
        done < "$LDAP_GROUPS_PATH"
    else
        echo "El archivo '$LDAP_GROUPS_PATH' no existe."
    fi
    echo "El valor de MAIL_DIR es: ${MAIL_DIR//\"/}"
}
# Función para leer la variable DRIVER desde el script '$DOVECOT_CONFIG_PATH'
function read_DRIVER() {
    # Leer la variable DRIVER desde el script '$DOVECOT_CONFIG_PATH'
    echo "Leyendo la variable DRIVER desde el script '$DOVECOT_CONFIG_PATH'..."
    # Verificar si el archivo existe
    if [ -f "$DOVECOT_CONFIG_PATH" ]; then
        # Leer el archivo línea por línea
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Buscar la línea que define la variable DRIVER
            if [[ "$line" =~ ^DRIVER= ]]; then
                # Extraer el valor de la variable DRIVER
                DRIVER=$(echo "$line" | cut -d'=' -f2)
                export DRIVER
                break
            fi
        done < "$DOVECOT_CONFIG_PATH"
    else
        echo "El archivo '$DOVECOT_CONFIG_PATH' no existe."
    fi
    echo "El valor de DRIVER es: ${DRIVER//\"/}"
}
# Función para crear el archivo auth-ldap.conf.ext
function create_auth_file() {
    # crear el archivo auth-ldap.conf.ext
    echo "Creando el archivo 'AUTH_PATH'..."
    sudo touch "$AUTH_PATH"
}
# Función para editar el archivo auth-ldap.conf.ext
function edit_auth_file() {
    # Contenido del archivo
    local contenido="passdb {
  driver = passwd-file
  args = scheme=PLAIN username_format=%u /etc/dovecot/users
}

userdb {
  driver = static
  args = args = uid=${GID_NAME//\"/} gid=${GID_NAME//\"/} home=${MAIL_DIR//\"/}/%d/%n
}

userdb {
  driver = static
  args = uid=${GID//\"/} gid=${GID//\"/} home=${MAIL_DIR//\"/}/%d/%n
}"

    # Escribir el contenido en el archivo
    echo "$contenido" | sudo tee "$AUTH_PATH" > /dev/null

    # Imprimir mensaje de éxito
    echo "El archivo $AUTH_PATH ha sido editado correctamente."
}

# Función principal
function auth_ldap_gen() {
    echo "***************AUTH-LDAP GEN***************"
    read_GID
    read_GID_NAME
    read_MAIL_DIR
    read_DRIVER
    create_auth_file
    edit_auth_file
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
auth_ldap_gen
