#!/bin/bash
# make_groups.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
DOMAINS_FILE="domains.txt"
DOMAINS_PATH="$PARENT_DIR/Postfix/$DOMAINS_FILE"
GROUPS_FILE="grupos.ldif"
GROUPS_PATH="$CURRENT_DIR/$GROUPS_FILE"
MAIL_DIR="/var/mail"

# Función para crear el archivo base de usuarios, leer la lista de usuarios y escribir la informacion del usuario en el archivo base de usuarios
function read_groups() {
  echo "Creando el archivo base de usuarios '$GROUPS_PATH'..."
  sudo touch "$GROUPS_PATH"
  
  while IFS="," read -r hostname; do
    echo "Hostname: $hostname"
     
    local domain="${hostname#*@}"
    domain="${domain%%.*}"
    echo "Dominio: $domain"
  
    local top_level="${hostname##*.}"
    echo "Top level: $top_level"
  
    echo "Escribiendo la información de cada dominio en el archivo base de grupos..."
    # Escribir la estructura para cada dominio en el archivo base de grupos
    echo "dn: ou=People,dc=$domain,dc=$top_level" >> "$GROUPS_PATH"
    echo "objectClass: organizationalUnit" >> "$GROUPS_PATH"
    echo "objectClass: top" >> "$GROUPS_PATH"
    echo "ou: People" >> "$GROUPS_PATH"
    echo >> "$GROUPS_PATH"

  done < <(grep -v '^$' "$DOMAINS_PATH")
  
  echo "Todas las cuentas de correo han sido copiadas."
}

function make_groups() {
    read_groups
}
# Llamar a la funcion principal
make_groups
