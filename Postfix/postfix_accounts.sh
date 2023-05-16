#!/bin/bash
# postfix_accounts.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
ACCOUNTS_FILE="mail_users.csv"
ACCOUNTS_PATH="$CURRENT_DIR/$ACCOUNTS_FILE"
POSTFIX_PATH="/etc/postfix"
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
  echo "Verificando si la ruta virtual existe..."
  if [ ! -d "$POSTFIX_PATH/virtual" ]; then
    echo "Creando la ruta: '$POSTFIX_PATH/virtual'..."
    sudo mkdir -p "$POSTFIX_PATH/virtual"
  else
    echo "La ruta virtual ya existe."
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
    # leer la lista de direcciones de correo
    echo "Leyendo la lista de dominios '$ACCOUNTS_PATH'..."
    while IFS="," read -r username nombre apellido email alias password; do
      echo "Usario: $username"
      echo "Dirección: $alias"
      echo "Contraseña: ${password:0:3}*********"
      # Obtener el dominio del correo electrónico (todo lo que está después del símbolo @)
      local domain="${alias#*@}"
      echo "Dominio: $domain"
      # Escribir una entrada en el archivo de buzones virtuales para el usuario y el dominio
      echo "$username@$domain $domain/$username"
      # Creando archivos para virtual_alias
      sudo touch "$POSTFIX_PATH/virtual/$domain"
       # Escribiendo datos 
      echo "$username@$domain $domain/$username" | grep -v '^$' >> "$POSTFIX_PATH/virtual/$domain"
      echo "Los datos del usuario '$username' han sido registrados en: '$POSTFIX_PATH/virtual/$domain'"
      # mapear  las direcciones y destinos
      echo "Mapeando las direcciones y destinos..."
      sudo postmap "$POSTFIX_PATH/virtual/$domain" || { echo "Error: Failure while executing postmap on: '$POSTFIX_PATH/virtual/$domain'"; return 1; }
      # crear directorios para cada usuario dentro de /var/mail/vhosts/
      sudo mkdir "/var/mail/vhosts/$domain/$alias"
      sudo chown postfix:mail "/var/mail/vhosts/$domain/$alias"
      sudo chmod 770 "/var/mail/vhosts/$domain/$alias"
      # agregar las cuentas de correo junto con sus contraseñas
      echo "Agregando las cuentas de correo junto con sus contraseñas..."
      echo "$alias:{PLAIN}$password" | grep -v '^$' >> "/etc/dovecot/users"
      echo "Los datos del usuario '$username' han sido registrados en: '/etc/dovecot/users'"
      echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    done < <(grep -v '^$' "$ACCOUNTS_PATH")
    echo "Todas las cuentas de correo han sido copiadas."
    echo "Todas las direcciones y destinos han sido mapeados."
}
# Función para reiniciar el servicio de Postfix y el servicio de Dovecot
function restart_services() {
    # reiniciar el servicio de Postfix
    echo "Restarting Postfix service..."
    sudo service postfix restart || { echo "Error: Failed to restart Postfix service."; return 1; }
    echo "Postfix service restarted successfully."
    sudo service postfix status || { echo "Error: Failed to check Postfix status."; return 1; }
    # reiniciar el servicio de Dovecot
    echo "Restarting Dovecot service..."
    sudo service dovecot restart || { echo "Error: Failed to restart Dovecot service."; return 1; }
    echo "Dovecot service restarted successfully."
    sudo service dovecot status || { echo "Error: Failed to check Dovecot status."; return 1; }
}
# Función principal
function postfix_accounts() {
  echo "***************POSTFIX ACCOUNTS***************"
  validate_accounts_file
  validate_virtual_path
  validate_users_file
  read_accounts
  restart_services
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
postfix_accounts
