#!/bin/bash
# postfix_vmailbox.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
ACCOUNTS_FILE="mail_users.csv"
ACCOUNTS_PATH="$CURRENT_DIR/$ACCOUNTS_FILE"
DOMAINS_FILE="domains.txt"
DOMAINS_PATH="$CURRENT_DIR/$DOMAINS_FILE"
POSTFIX_PATH="/etc/postfix"
VMAILBOX_DIR="virtual" # archivo de buzones virtuales
VMAILBOX_PATH="$POSTFIX_PATH/$VMAILBOX_DIR"
# Función para verificar si el archivo de cuentas de usuario existe
function validate_accounts_file() {
    # verificar si el archivo de cuentas de usuario existe
  echo "Verificando si el archivo de cuentas de usuario existe..."
  if [ ! -f "$ACCOUNTS_PATH" ]; then
    echo "ERROR: El archivo de cuentas de usuario '$ACCOUNTS_FILE' no se puede encontrar en la ruta '$ACCOUNTS_PATH'."
    exit 1
  fi
  echo "El archivo de cuentas de usuario '$ACCOUNTS_FILE' existe."
}
# Función para verificar si el archivo de dominios existe
function validate_domains_file() {
    # verificar si el archivo de dominios existe
  echo "Verificando si el archivo de dominios existe..."
  if [ ! -f "$DOMAINS_PATH" ]; then
    echo "ERROR: El archivo de dominios '$DOMAINS_PATH' no se puede encontrar en la ruta '$DOMAINS_PATH'."
    exit 1
  fi
  echo "El archivo de dominios '$DOMAINS_PATH' existe."
}
# Función para verificar si la ruta virtual existe
function validate_vmailbox_path() {
  echo "Verificando si la ruta virtual existe..."
  if [ ! -d "$VMAILBOX_PATH" ]; then
    echo "Creando la ruta: '$VMAILBOX_PATH'..."
    sudo mkdir -p "$VMAILBOX_PATH"
    if [ $? -ne 0 ]; then
      echo "Error: No se pudo crear la ruta virtual '$VMAILBOX_PATH'."
      return 1
    fi
    echo "La ruta virtual '$VMAILBOX_PATH' ha sido creada."
  else
    echo "La ruta virtual ya existe."
  fi
}

# Función para leer la lista de dominios y crear los archivos de buzones de correo virtual
function read_domains() {
    # Leer la lista de dominios
    while read -r domain || [[ -n "$domain" ]]; do
        if [ -z "$domain" ]; then
            continue
        fi
      
        # Crear los archivos de buzones de correo virtual
        echo "Creando los archivos de buzones de correo virtual del dominio: '$domain'..."
        if [ -e "$VMAILBOX_PATH/$domain" ]; then
            echo "Advertencia: El archivo de buzones de correo virtual '$VMAILBOX_PATH/$domain' del dominio '$domain' ya existe."
        else
            sudo touch "$VMAILBOX_PATH/$domain"
            if [ $? -ne 0 ]; then
                echo "Error: No se pudo crear el archivo de buzones de correo virtual '$VMAILBOX_PATH/$domain' del dominio '$domain'."
                continue
            fi
            echo "El archivo de buzones de correo virtual '$VMAILBOX_PATH/$domain' del dominio '$domain' ha sido creado."
            sudo mkdir -p "$VMAILBOX_PATH/$domain"
        fi
    done < <(grep -v '^$' "$DOMAINS_PATH")

    echo "Todos los archivos de buzones de correo virtual de todos los dominios han sido creados."
}

# Función para leer la lista de direcciones de correo
function read_accounts() {
  # leer la lista de direcciones de correo
  echo "Leyendo la lista de direcciones de correo: '$ACCOUNTS_PATH'..."
  while IFS="," read -r username nombre apellido email alias password; do
      echo "Usario: $username"
      echo "Dirección: $alias"
      echo "Contraseña: ${password:0:3}*********"
      # Obtener el dominio del correo electrónico (todo lo que está después del símbolo @)
      local domain2="${alias#*@}"
      # Escribir una entrada en el archivo de buzones virtuales para el usuario y el dominio
      echo "$alias $domain2/$username"
      echo "$alias $domain2/$username" | grep -v '^$' >> "$VMAILBOX_PATH/$domain2"
      echo "$alias $alias" | grep -v '^$' >> "$VMAILBOX_PATH/aliases"
      echo "La cuenta '$alias' ha sido registrada en el archivo de buzones de correo virtual: '$VMAILBOX_PATH/$domain2'"
      echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  done < <(grep -v '^$' "$ACCOUNTS_PATH")
  echo "Todas las cuentas de correo han sido copiadas."
}
# Función para leer la lista de dominios y mapear los buzones de correo
function map_domains() {
  # Leer la lista de dominios
  while read -r domain3; do
    # mapear los buzones de correo
    echo "Mapeando los buzones de correo del dominio: '$domain3'..."
    sudo postmap "$VMAILBOX_PATH/$domain3" || { echo "Error: Failure while executing postmap on: '$VMAILBOX_PATH/$domain3'"; return 1; }
  
  done < <(grep -v '^$' "$DOMAINS_PATH")
  sudo postmap "/etc/aliases" || { echo "Error: Failure while executing postmap on: '/etc/aliases'"; return 1; }
  sudo postmap "$VMAILBOX_PATH/aliases" || { echo "Error: Failure while executing postmap on: '$VMAILBOX_PATH/aliases'"; return 1; }
  echo "Todos los buzones de correo han sido mapeados."
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
function postfix_vmailbox() {
  echo "***************POSTFIX MAILBOX CONFIG***************"
  validate_accounts_file
  validate_domains_file
  validate_vmailbox_path
  read_domains
  read_accounts
  map_domains
  restart_services
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
postfix_vmailbox
