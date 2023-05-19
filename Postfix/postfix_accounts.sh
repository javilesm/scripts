#!/bin/bash
# postfix_accounts.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
ACCOUNTS_FILE="mail_users.csv"
ACCOUNTS_PATH="$CURRENT_DIR/$ACCOUNTS_FILE"
DOMAINS_FILE="domains.txt"
DOMAINS_PATH="$CURRENT_DIR/$DOMAINS_FILE"
POSTFIX_PATH="/etc/postfix"
MAIL_PATH="/var/spool/mail"
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
# Función para leer la lista de direcciones de dominios y crear los archivos de direcciones de correo
function create_files() {
    # leer la lista de dominios
    echo "Leyendo la lista de dominios: '$DOMAINS_PATH'..."
    while read -r host; do
      # crear directorios
      sudo mkdir -p "$MAIL_PATH/$host"
      # cambiar permisos al directorio
      sudo chmod 777 "$MAIL_PATH/$host"
      # Creando archivos para virtual_alias
      sudo touch "$POSTFIX_PATH/virtual/$host"
    done < <(grep -v '^$' "$DOMAINS_PATH")
    echo "Todos los archivos de direcciones de correo han sido creados."
}
# Función para leer la lista de direcciones de correo
function read_accounts() {
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
      echo "$username@$domain $domain/$username" | grep -v '^$' >> "$POSTFIX_PATH/virtual/$domain"
      echo "Los datos del usuario '$username' han sido registrados en: '$POSTFIX_PATH/virtual/$domain'"
      # crear directorios para cada usuario dentro de /var/spool/mail/$domain
      sudo mkdir -p "$MAIL_PATH/$domain/$username"
      sudo chmod 777 "$MAIL_PATH/$domain/$username"
      # crear directorios para cada usuario dentro de /var/mail/vhosts/$domain
      sudo mkdir "/var/mail/vhosts/$domain/$alias"
      sudo chown postfix:mail "/var/mail/vhosts/$domain/$alias"
      sudo chmod 777 "/var/mail/vhosts/$domain/$alias"
      # agregar las cuentas de correo junto con sus contraseñas
      echo "Agregando las cuentas de correo junto con sus contraseñas..."
      echo "$alias:{PLAIN}$password" | grep -v '^$' >> "/etc/dovecot/users"
      echo "Los datos del usuario '$username' han sido registrados en: '/etc/dovecot/users'"
      echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    done < <(grep -v '^$' "$ACCOUNTS_PATH")
    echo "Todas las cuentas de correo han sido copiadas."
}
# Función para leer la lista de direcciones de dominios y mapear  las direcciones y destinos
function read_domains() {
    # leer la lista de dominios
    echo "Leyendo la lista de dominios: '$DOMAINS_PATH'..."
    while read -r domains; do
      # mapear  las direcciones y destinos
      echo "Mapeando las direcciones y destinos del dominio '$domains'..."
      sudo postmap "$POSTFIX_PATH/virtual/$domains" || { echo "Error: Failure while executing postmap on: '$POSTFIX_PATH/virtual/$domains'"; return 1; }
      sudo chmod 2775 "/var/mail/vhosts/$domains"
      sudo chown 117:125 "/var/mail/vhosts/$domains"
    done < <(grep -v '^$' "$DOMAINS_PATH")
    echo "Todas las direcciones y destinos han sido mapeados."
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
  create_files
  read_accounts
  read_domains
  restart_services
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
postfix_accounts
