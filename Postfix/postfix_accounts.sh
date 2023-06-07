#!/bin/bash
# postfix_accounts.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
ACCOUNTS_FILE="mail_users.csv"
ACCOUNTS_PATH="$CURRENT_DIR/$ACCOUNTS_FILE"
PARTITIONS_SCRIPT="mail_partitions.sh"
PARTITIONS_PATH="$CURRENT_DIR/$PARTITIONS_SCRIPT"
DOMAINS_FILE="domains.txt"
DOMAINS_PATH="$CURRENT_DIR/$DOMAINS_FILE"
POSTFIX_PATH="/etc/postfix"
DOVECOT_PATH="/etc/dovecot"
USERS_PATH="$DOVECOT_PATH/users"
MAIL_DIR="/var/mail"
GID="10000"
GID_NAME="people"
UID_NAME=${GID_NAME//\"/}
# Función para crear al grupo $GID
function group_add() {
    # crear al grupo $GID
    echo "Creando al grupo '$GID'..."
    sudo groupadd -g ${GID//\"/} "$GID_NAME"
    cat /etc/group
}
# Función para crear al usuario UID_NAME:GID
function create_uidname_user() {
  # crear al usuario $UID_NAME:GID
  echo "Creando al usuario $UID_NAME:${GID//\"/}..."
  sudo useradd -u ${GID//\"/} -g ${GID//\"/} -s /usr/bin/nologin -d ${MAIL_DIR//\"/} -m "$UID_NAME"
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
  echo "Verificando si el directorio padre '$MAIL_DIR' existe..."
  if [ ! -d "$MAIL_DIR" ]; then
    # crear directorio
    echo "Creando el directorio: '$MAIL_DIR'..."
    sudo mkdir -p "$MAIL_DIR"
    else
    echo "El directorio padre '$MAIL_DIR' ya existe."
  fi
    # cambiar permisos del directorio padre
    echo "Cambiando los permisos del directorio padre '$MAIL_DIR'..."
    sudo chmod +w "$MAIL_DIR"
    # cambiar la propiedad del directorio padre
    echo "Cambiando la propiedad del directorio '$MAIL_DIR'..."
    sudo chown :${GID//\"/} "$MAIL_DIR"
}
# Función para verificar si el archivo de configuración existe
function validate_script() {
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$PARTITIONS_PATH" ]; then
    echo "ERROR: El archivo '$PARTITIONS_SCRIPT' no se puede encontrar en la ruta '$PARTITIONS_PATH'."
    exit 1
  fi
  echo "El archivo '$PARTITIONS_SCRIPT' existe."
}
# Función para ejecutar el configurador de Postfix
function run_script() {
  echo "Ejecutar el configurador '$PARTITIONS_SCRIPT'..."
    # Intentar ejecutar el archivo de configuración de Postfix
  if sudo bash "$PARTITIONS_PATH"; then
    echo "El archivo '$PARTITIONS_SCRIPT' se ha ejecutado correctamente."
  else
    echo "ERROR: No se pudo ejecutar el archivo '$PARTITIONS_SCRIPT'."
    exit 1
  fi
  echo "Configurador '$PARTITIONS_SCRIPT' ejecutado."
}
# Función para verificar si el archivo /etc/dovecot/users existe
function validate_users_file() {
  echo "Verificando si el archivo de usuarios existe..."
  if [ ! -f "$USERS_PATH" ]; then
    echo "Creando archivo '$USERS_PATH'..."
    sudo touch "$USERS_PATH"
  fi
  echo "El archivo '$USERS_PATH' ha sido creado."
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
      echo "Creando el subdirectorio: '$MAIL_DIR'..."
      sudo mkdir -p "$MAIL_DIR/$host"
      # cambiar permisos del subdirectorio
      echo "Cambiando los permisos del subdirectorio '$MAIL_DIR/$host'..."
      sudo chmod +x "$MAIL_DIR/$host"
      sudo chmod o+w "$MAIL_DIR/$host"
      # cambiar la propiedad del directorio
      echo "Cambiando la propiedad del directorio '$MAIL_DIR/$host'..."
      sudo chown :${GID//\"/} "$MAIL_DIR/$host"
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
      local usermail_path="$MAIL_DIR/$domain/$username"
      # crear subdirectorio del usuario
      echo "Creando subdirectorio '$usermail_path'..."
      sudo mkdir -p "$usermail_path"
      # cambiar permisos al subdirectorio del usuario
      echo "Cambiando permisos del subdirectorio '$usermail_path'..."
      sudo chmod 777 "$usermail_path"
      sudo chmod +w "$usermail_path"
      # cambiar propiedad del subdirectorio del usuario
      echo "Cambiando la propiedad del subdirectorio '$usermail_path'..."
      sudo chown :${GID//\"/} "$usermail_path"
      # Escribir una entrada en el archivo de buzones virtuales para el usuario y el dominio
      echo "$alias" "$username"| grep -v '^$' >> "$POSTFIX_PATH/virtual_alias_maps"
      echo "Los datos del usuario '$username' han sido registrados en: '$POSTFIX_PATH/virtual_alias_maps'"
      # agregar las cuentas de correo junto con sus contraseñas
      echo "Agregando las cuentas de correo junto con sus contraseñas..."
      echo "$alias:{PLAIN}$password" | grep -v '^$' >> "$USERS_PATH"
      echo "Los datos del usuario '$username' han sido registrados en: '$USERS_PATH'"
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
  validate_script
  run_script
  validate_users_file
  read_domains
  read_accounts
  restart_services
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
postfix_accounts
