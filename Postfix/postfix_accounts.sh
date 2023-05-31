#!/bin/bash
# postfix_accounts.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
ACCOUNTS_FILE="mail_users.csv"
ACCOUNTS_PATH="$CURRENT_DIR/$ACCOUNTS_FILE"
DOMAINS_FILE="domains.txt"
DOMAINS_PATH="$CURRENT_DIR/$DOMAINS_FILE"
POSTFIX_PATH="/etc/postfix"
DOVECOT_PATH="/etc/dovecot"
MAIL_DIR="/var/mail"
GID="10000"
GID_NAME="people"
# Función para crear al grupo $GID
function group_add() {
    # crear al grupo $GID
    echo "Creando al grupo '$GID'..."
    sudo groupadd -g "$GID" "$GID_NAME"
    cat /etc/group
}
# Función para crear al usuario uidname:GID
function create_uidname_user() {
  local uidname="vmail"
  # crear al usuario uidname:GID
  echo "Creando al usuario $uidname:${GID//\"/}..."
  sudo useradd -u 1001 -g ${GID//\"/} -s /usr/bin/nologin -d ${MAIL_DIR//\"/} -m "$uidname"
  cat /etc/passwd
}

# Función para verificar si el archivo de cuentas de usuario existe
function validate_accounts_file() {
    # verificar si el archivo de dominios existe
  echo "Verificando si el archivo de cuentas de usuario existe..."
  if [ ! -f "$ACCOUNTS_PATH" ]; then
    echo "ERROR: El archivo de cuentas de usuario '$ACCOUNTS_FILE' no se puede encontrar en la ruta '$ACCOUNTS_PATH'."
    exit 1
  fi
  echo "El archivo de cuentas de usuario '$ACCOUNTS_FILE' existe."
}
# Función para verificar si la ruta virtual existe
function validate_MAIL_DIR() {
  echo "Verificando si la ruta '$MAIL_DIR' existe..."
  if [ ! -d "$MAIL_DIR" ]; then
    # crear directorio
    echo "Creando el directorio: '$MAIL_DIR'..."
    sudo mkdir -p "$MAIL_DIR"
    # cambiar permisos del directorio padre
    echo "Cambiando los permisos del directorio padre '$MAIL_DIR'..."
    sudo chmod 777 "$MAIL_DIR"
  else
    echo "La ruta '$MAIL_DIR' ya existe."
  fi
}
# Función para verificar si el archivo /etc/dovecot/users existe
function validate_users_file() {
  echo "Verificando si el archivo de usuarios existe..."
  if [ ! -f "$DOVECOT_PATH/users" ]; then
    echo "Creando archivo '$DOVECOT_PATH/users'..."
    sudo touch "$DOVECOT_PATH/users"
  fi
  echo "El archivo '$DOVECOT_PATH/users' ha sido creado."
}
# Función para leer la lista de direcciones de dominios y mapear  las direcciones y destinos
function read_domains() {
    # leer la lista de dominios
    echo "Leyendo la lista de dominios: '$DOMAINS_PATH'..."
    while read -r hostname; do
      local host="${hostname#*@}"
      host="${host%%.*}"
      echo "Hostname: $host"
      # crear subdirectorios para cada dominio
      echo "Cambiando los permisos del directorio padre '$MAIL_DIR'..."
      sudo mkdir -p "$MAIL_DIR/$host"
      # cambiar permisos del subdirectorio
      echo "Cambiando los permisos del subdirectorio '$MAIL_DIR/$host'..."
      sudo chmod +x "$MAIL_DIR/$host"
      sudo chmod o+w "$MAIL_DIR/$host"
      # cambiar la propiedad del directorio
      echo "Cambiando la propiedad del directorio '$MAIL_DIR/$host'..."
      sudo chown :"$GID" "$MAIL_DIR/$host"
      sudo chmod g+w "$MAIL_DIR/$host"
    done < <(grep -v '^$' "$DOMAINS_PATH")
    echo "Todas los permisos y propiedades han sido actualizados."
}
# Función para leer la lista de direcciones de correo
function read_accounts() {
    sudo touch "$POSTFIX_PATH/virtual_alias_maps"
    # leer la lista de direcciones de correo
    echo "Leyendo la lista de usuarios: '$ACCOUNTS_PATH'..."
    while IFS="," read -r username nombre apellido email alias password; do
      echo "Usario: $username"
      echo "Dirección: $alias"
      echo "Contraseña: ${password:0:3}*********"
      # Obtener el dominio del correo electrónico (todo lo que está después del símbolo @)
      local domain="${alias#*@}"
      domain="${domain%%.*}"
      echo "Dominio: $domain"
      local top_level="${alias##*.}"
      echo "Top level: $top_level"
      # crear subdirectorio del usuario
      echo "Creando subdirectorio del usuario '$username' del dominio '$domain'..."
      sudo mkdir -p "$MAIL_DIR/$domain/$username"
      # cambiar permisos al subdirectorio del usuario
      echo "Cambiando permisos del subdirectorio del usuario '$username' del dominio '$domain'..."
      sudo chmod +w "$MAIL_DIR/$domain/$username"
      # cambiar propiedad del subdirectorio del usuario
      echo "Cambiando la propiedad del subdirectorio del usuario '$username' del dominio '$domain'..."
      sudo chown :$GID "$MAIL_DIR/$domain/$username"
      # Escribir una entrada en el archivo de buzones virtuales para el usuario y el dominio
      echo "$alias $domain/$username" | grep -v '^$' >> "$POSTFIX_PATH/virtual_alias_maps"
      echo "Los datos del usuario '$username' han sido registrados en: '$POSTFIX_PATH/virtual_alias_maps'"
      # agregar las cuentas de correo junto con sus contraseñas
      echo "Agregando las cuentas de correo junto con sus contraseñas..."
      echo "$alias:{PLAIN}$password" | grep -v '^$' >> "$DOVECOT_PATH/users"
      echo "Los datos del usuario '$username' han sido registrados en: '$DOVECOT_PATH/users'"
      echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    done < <(grep -v '^$' "$ACCOUNTS_PATH")
    echo "Todas las cuentas de correo han sido copiadas."
    # mapear  las direcciones y destinos
    echo "Mapeando las direcciones y usuarios..."
    sudo postmap "$POSTFIX_PATH/virtual_alias_maps" || { echo "Error: Failure while executing postmap on: '$POSTFIX_PATH/virtual_alias_maps'"; return 1; }

}
# Función para reiniciar el servicio de Postfix y el servicio de Dovecot
function restart_services() {
    # reiniciar el servicio de Postfix
    echo "Restarting Postfix service..."
    sudo service postfix restart || { echo "Error: Failed to restart Postfix service."; return 1; }
    echo "Postfix service restarted successfully."
    # reiniciar el servicio de Dovecot
    echo "Restarting Dovecot service..."
    sudo service dovecot restart || { echo "Error: Failed to restart Dovecot service."; return 1; }
    echo "Dovecot service restarted successfully."
    
}
# Función principal
function postfix_accounts() {
  echo "***************POSTFIX ACCOUNTS***************"
  group_add
  create_uidname_user
  validate_accounts_file
  validate_MAIL_DIR
  validate_users_file
  read_domains
  read_accounts
  restart_services
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
postfix_accounts
