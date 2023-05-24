#!/bin/bash
# postfix_accounts.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
ACCOUNTS_FILE="mail_users.csv"
ACCOUNTS_PATH="$CURRENT_DIR/$ACCOUNTS_FILE"
DOMAINS_FILE="domains.txt"
DOMAINS_PATH="$CURRENT_DIR/$DOMAINS_FILE"
POSTFIX_PATH="/etc/postfix"
MAIL_PATH="/var/mail"
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
# Función para verificar si la ruta virtual existe
function validate_virtual_path() {
  echo "Verificando si la ruta '$POSTFIX_PATH/virtual' existe..."
  if [ ! -d "$POSTFIX_PATH/virtual" ]; then
    echo "Creando la ruta: '$POSTFIX_PATH/virtual'..."
    sudo mkdir -p "$POSTFIX_PATH/virtual"
    sudo chmod 777 "$POSTFIX_PATH/virtual"
  else
    echo "La ruta '$POSTFIX_PATH/virtual' ya existe."
  fi
}
# Función para verificar si la ruta virtual existe
function validate_mail_path() {
  echo "Verificando si la ruta '$MAIL_PATH' existe..."
  if [ ! -d "$MAIL_PATH" ]; then
    # crear directorio
    echo "Creando el directorio: '$MAIL_PATH'..."
    sudo mkdir -p "$MAIL_PATH"
    # cambiar permisos al directorio
    sudo chmod 777 "$MAIL_PATH"
  else
    echo "La ruta '$MAIL_PATH' ya existe."
  fi
}
# Función para verificar si el archivo /etc/dovecot/users existe
function validate_users_file() {
  echo "Verificando si el archivo de usuarios existe..."
  if [ ! -f "/etc/dovecot/users" ]; then
    echo "Creando archivo '/etc/dovecot/users'..."
    cd "/etc/dovecot"
    sudo touch "users"
  fi
  echo "El archivo '/etc/dovecot/users' ha sido creado."
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
      echo "Dominio: $domain"
      # Escribir una entrada en el archivo de buzones virtuales para el usuario y el dominio
      echo "$username@$domain $domain/$username"
      # Escribiendo datos 
      echo "$username@$domain $domain/$username" | grep -v '^$' >> "$POSTFIX_PATH/virtual_alias_maps"
      echo "Los datos del usuario '$username' han sido registrados en: '$POSTFIX_PATH/virtual_alias_maps'"
      # agregar las cuentas de correo junto con sus contraseñas
      echo "Agregando las cuentas de correo junto con sus contraseñas..."
      echo "$alias:{PLAIN}$password" | grep -v '^$' >> "/etc/dovecot/users"
      echo "Los datos del usuario '$username' han sido registrados en: '/etc/dovecot/users'"
      echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    done < <(grep -v '^$' "$ACCOUNTS_PATH")
    echo "Todas las cuentas de correo han sido copiadas."
    # mapear  las direcciones y destinos
    echo "Mapeando las direcciones y usuarios..."
    sudo postmap "$POSTFIX_PATH/virtual_alias_maps" || { echo "Error: Failure while executing postmap on: '$POSTFIX_PATH/virtual_alias_maps'"; return 1; }

}
# Función para leer la lista de direcciones de dominios y mapear  las direcciones y destinos
function read_domains() {
    # leer la lista de dominios
    echo "Leyendo la lista de dominios: '$DOMAINS_PATH'..."
    while read -r host; do
      # cambiar permisos del directorio padre
      echo "Cambiando los permisos del directorio padre '/var/mail'..."
      sudo chmod 755 "/var/mail"
      # cambiar permisos del subdirectorio
      echo "Cambiando los permisos del subdirectorio '/var/mail/$host'..."
      sudo chmod 700 "/var/mail/$host"
      # cambiar la propiedad del directorio
      echo "Cambiando la propiedad del directorio '/var/mail/$host'..."
      sudo chown 120:128 "/var/mail/$host"
    done < <(grep -v '^$' "$DOMAINS_PATH")
    echo "Todas los permisos y propiedades han sido actualizados."
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
  validate_accounts_file
  validate_virtual_path
  validate_mail_path
  validate_users_file
  read_accounts
  read_domains
  restart_services
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
postfix_accounts
