#!/bin/bash
# make_groups.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
CONFIG_FILE="openldap_config.sh"
CONFIG_PATH="$CURRENT_DIR/$CONFIG_FILE"
DOMAINS_FILE="domains.txt"
DOMAINS_PATH="$PARENT_DIR/Postfix/$DOMAINS_FILE"
GROUPS_FILE="grupos.ldif"
GROUPS_PATH="$CURRENT_DIR/$GROUPS_FILE"
LDAP_USERS_PATH="/etc/postfix/ldap-users.cf"
LDAP_ALIASES_PATH="/etc/postfix/ldap-aliases.cf"
MAIL_DIR="/var/mail"
# Función para leer la variable "ADMIN_PASSWORD" desde el script "openldap_config.sh" 
function read_openldap_config() {
  # leer la variable "ADMIN_PASSWORD" desde el script "openldap_config.sh"
  admin_password=$(grep -oP 'ADMIN_PASSWORD=\K.*' "$CONFIG_PATH")
  echo "La contraseña del administrador es: $admin_password"
}
# Función para crear el archivo base de usuarios
function create_groups_file() {
  # Verificar si el archivo ya existe
  if [ -e "$GROUPS_PATH" ]; then
    echo "El archivo base de usuarios '$GROUPS_PATH' ya existe."
    return 1
  fi

  # Crear el archivo base de usuarios
  echo "Creando el archivo base de usuarios '$GROUPS_PATH'..."
  if sudo touch "$GROUPS_PATH"; then
    echo "Archivo base de usuarios creado correctamente."
    return 0
  else
    echo "Error al crear el archivo base de usuarios."
    return 1
  fi
}

# Función para leer la lista de usuarios y escribir la estructura para cada dominio en el archivo base de grupos
function make_grupos() {
  # leer la lista de usuarios
  echo "Leeyendo la lista de usuarios '$GROUPS_PATH'..."
  while IFS="," read -r hostname; do
    echo "Hostname: $hostname"
     
    local domain="${hostname#*@}"
    domain="${domain%%.*}"
    echo "Dominio: $domain"
  
    local top_level="${hostname##*.}"
    echo "Top level: $top_level"
  
    echo "Escribiendo la estructura para cada dominio en el archivo base de grupos..."
    # Escribir la estructura para cada dominio en el archivo base de grupos
    echo "dn: ou=People,dc=$domain,dc=$top_level" >> "$GROUPS_PATH"
    echo "objectClass: organizationalUnit" >> "$GROUPS_PATH"
    echo "objectClass: top" >> "$GROUPS_PATH"
    echo "ou: People" >> "$GROUPS_PATH"
    echo >> "$GROUPS_PATH"

  done < <(grep -v '^$' "$DOMAINS_PATH")
  
  echo "Todas las cuentas de correo han sido copiadas."
}
# Función para crear el archivo base de usuarios
function create_users_file() {
  # Verificar si el archivo ya existe
  if [ -e "$LDAP_USERS_PATH" ]; then
    echo "El archivo base de usuarios '$LDAP_USERS_PATH' ya existe."
    return 1
  fi

  # Crear el archivo base de usuarios
  echo "Creando el archivo base de usuarios '$LDAP_USERS_PATH'..."
  if sudo touch "$LDAP_USERS_PATH"; then
    echo "Archivo base de usuarios creado correctamente."
    return 0
  else
    echo "Error al crear el archivo base de usuarios."
    return 1
  fi
}

# Función para leer la lista de usuarios y escribir la informacion del usuario en el archivo base de usuarios
function make_ldap_users() {
  # leer la lista de usuarios 
  echo "Leyendo la lista de usuarios '$LDAP_USERS_PATH'..."
  while IFS="," read -r hostname; do
    echo "Hostname: $hostname"
     
    local domain="${hostname#*@}"
    domain="${domain%%.*}"
    echo "Dominio: $domain"
  
    local top_level="${hostname##*.}"
    echo "Top level: $top_level"
  
    echo "Escribiendo la información de cada dominio en el archivo base de grupos..."
    # Escribir la estructura para cada dominio en el archivo base de grupos
    echo "server_host = ldap://ldap.$hostname" >> "$LDAP_USERS_PATH"
    echo "start_tls = yes" >> "$LDAP_USERS_PATH"
    echo "tls_ca_cert_file = /etc/ldap/tls/CA.pem" >> "$LDAP_USERS_PATH"
    echo "tls_require_cert = yes" >> "$LDAP_USERS_PATH"
    echo "search_base = dc=$domain,dc=$top_level" >> "$LDAP_USERS_PATH"
    echo "scope = sub" >> "$LDAP_USERS_PATH"
    echo "version = 3" >> "$LDAP_USERS_PATH"
    echo "bind = yes" >> "$LDAP_USERS_PATH"
    echo "bind_dn = cn=admin,dc=$domain,dc=$top_level" >> "$LDAP_USERS_PATH"
    echo "bind_pw = admin_password" >> "$LDAP_USERS_PATH"
    echo "query_filter = (&(objectClass=inetOrgPerson)(mail=%s))" >> "$LDAP_USERS_PATH"
    echo "result_attribute = homeDirectory" >> "$LDAP_USERS_PATH"
    echo "result_filter = %s/Maildir/" >> "$LDAP_USERS_PATH"
  done < <(grep -v '^$' "$DOMAINS_PATH")
  echo "Todas las cuentas de correo han sido copiadas."
}
# Función para crear el archivo base de usuarios
function create_aliases_file() {
  # Verificar si el archivo ya existe
  if [ -e "$LDAP_ALIASES_PATH" ]; then
    echo "El archivo base de usuarios '$LDAP_ALIASES_PATH' ya existe."
    return 1
  fi

  # Crear el archivo base de usuarios
  echo "Creando el archivo base de usuarios '$LDAP_ALIASES_PATH'..."
  if sudo touch "$LDAP_ALIASES_PATH"; then
    echo "Archivo base de usuarios creado correctamente."
    return 0
  else
    echo "Error al crear el archivo base de usuarios."
    return 1
  fi
}

# Función para crear el archivo base de usuarios, leer la lista de usuarios y escribir la informacion del usuario en el archivo base de usuarios
function make_ldap_aliases() {
  while IFS="," read -r hostname; do
    echo "Hostname: $hostname"
     
    local domain="${hostname#*@}"
    domain="${domain%%.*}"
    echo "Dominio: $domain"
  
    local top_level="${hostname##*.}"
    echo "Top level: $top_level"
  
    echo "Escribiendo la información de cada dominio en el archivo base de grupos..."
    # Escribir la estructura para cada dominio en el archivo base de grupos
    echo "server_host = ldap://ldap.$hostname" >> "$LDAP_ALIASES_PATH"
    echo "start_tls = yes" >> "$LDAP_ALIASES_PATH"
    echo "tls_ca_cert_file = /etc/ldap/tls/CA.pem" >> "$LDAP_ALIASES_PATH"
    echo "tls_require_cert = yes" >> "$LDAP_ALIASES_PATH"
    echo "search_base = dc=$domain,dc=$top_level" >> "$LDAP_ALIASES_PATH"
    echo "scope = sub" >> "$LDAP_ALIASES_PATH"
    echo "version = 3" >> "$LDAP_ALIASES_PATH"
    echo "bind = yes" >> "$LDAP_ALIASES_PATH"
    echo "bind_dn = cn=admin,dc=$domain,dc=$top_level" >> "$LDAP_ALIASES_PATH"
    echo "bind_pw = admin_password" >> "$LDAP_ALIASES_PATH"
    echo "query_filter = (&(objectClass=inetOrgPerson)(mail=%s))" >> "$LDAP_ALIASES_PATH"
    echo "result_attribute = mail" >> "$LDAP_ALIASES_PATH"
    echo "result_filter = %s" >> "$LDAP_ALIASES_PATH"
  done < <(grep -v '^$' "$DOMAINS_PATH")
  echo "Todas las cuentas de correo han sido copiadas."
}
function make_groups() {
  echo "***************MAKE GROUPS***************"
  read_openldap_config
  create_groups_file
  make_grupos
  create_users_file
  make_ldap_users
  create_aliases_file
  make_ldap_aliases
  echo "***************ALL DONE***************"
}
# Llamar a la funcion principal
make_groups
