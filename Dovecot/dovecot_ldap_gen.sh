#!/bin/bash
# dovecot_ldap_gen.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
LDAP_GROUPS_FILE="make_groups.sh"
LDAP_GROUPS_PATH="$PARENT_DIR/LDAP/$LDAP_GROUPS_FILE"
POSTFIX_ACCOUNTS_SCRIPT="postfix_accounts.sh"
POSTFIX_ACCOUNTS_PATH="$PARENT_DIR/Postfix/$POSTFIX_ACCOUNTS_SCRIPT"
DOVECOT_CONFIG_SCRIPT="dovecot_config.sh"
DOVECOT_CONFIG_PATH="$CURRENT_DIR/$DOVECOT_CONFIG_SCRIPT"
DOVECOT_LDAP_FILE="dovecot-ldap.conf.ext"
DOVECOT_LDAP_PATH="$CURRENT_DIR/$DOVECOT_LDAP_FILE"
CONFIG_FILE="openldap_config.sh"
CONFIG_PATH="$PARENT_DIR/LDAP/$CONFIG_FILE"
DOMAINS_FILE="domains.txt"
DOMAINS_PATH="$PARENT_DIR/Postfix/$DOMAINS_FILE"
# Función para leer la variable "ADMIN_PASSWORD" desde el script "openldap_config.sh" 
function read_openldap_config() {
  # leer la variable "ADMIN_PASSWORD" desde el script "openldap_config.sh"
  admin_password=$(grep -oP 'ADMIN_PASSWORD=\K.*' "$CONFIG_PATH")
  echo "La contraseña del administrador es: $admin_password"
}
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
# Función para crear el archivo auth-ldap.conf.ext
function create_auth_file() {
    # crear el archivo auth-ldap.conf.ext
    echo "Creando el archivo '$DOVECOT_LDAP_PATH'..."
    sudo touch "$DOVECOT_LDAP_PATH"
}

# Función para editar el archivo auth-ldap.conf.ext
function edit_auth_file() {
  local contenido=""  # Variable para almacenar el contenido completo del archivo

  # leer la lista de dominios
  echo "Leyendo la lista de dominios desde '$GROUPS_PATH'..."
  while IFS="," read -r hostname; do
    echo "Hostname: $hostname"
     
    local domain="${hostname#*@}"
    domain="${domain%%.*}"
    echo "Dominio: $domain"
  
    local top_level="${hostname##*.}"
    echo "Top level: $top_level"
    
    # Contenido del archivo para el dominio actual
    local contenido_dominio="#
hosts = ldap.$hostname
auth_bind = yes
ldap_version = 3
dn = cn=admin,dc=$domain,dc=$top_level
dnpass = ${admin_password//\"/}
base = ou=${GID_NAME//\"/},dc=$domain,dc=$top_level
scope = subtree
user_attrs = mail=home=${MAIL_DIR//\"/}/%d/%n
user_filter = (&(objectClass=inetOrgPerson)(mail=%u)(domain=$hostname))
pass_attrs = mail=userPassword
pass_filter = (&(objectClass=inetOrgPerson)(mail=%u)(domain=$hostname))

"

    # Concatenar el contenido del dominio actual al contenido completo
    contenido+="$contenido_dominio"

  done < <(grep -v '^$' "$DOMAINS_PATH")
  
  # Escribir el contenido completo en el archivo
  echo "$contenido" | sudo tee "$DOVECOT_LDAP_PATH" > /dev/null
  
  # Imprimir mensaje de éxito
  echo "El archivo $DOVECOT_LDAP_PATH ha sido editado correctamente."
}

# Función principal
function auth_ldap_gen() {
    echo "***************AUTH-LDAP GEN***************"
    read_openldap_config
    read_GID_NAME
    read_MAIL_DIR
    create_auth_file
    edit_auth_file
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
auth_ldap_gen
