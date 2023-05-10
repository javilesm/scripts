#!/bin/bash
# postfix_config.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
DOMAINS_FILE="domains.txt"
DOMAINS_PATH="$CURRENT_DIR/$DOMAINS_FILE"
POSTFIX_PATH="/etc/postfix"
POSTFIX_MAIN="$POSTFIX_PATH/main.cf"
VIRTUAL_DOMAINS="$POSTFIX_PATH/virtual_domains.cf"
VIRTUAL_MAILBOX="$POSTFIX_PATH/virtual_mailbox.cf"
VIRTUAL_ALIAS="$POSTFIX_PATH/virtual_alias.cf"
CERT_FILE="ssl-cert-snakeoil.pem" # default self-signed certificate that comes with Ubuntu
KEY_FILE="ssl-cert-snakeoil.key"
# Función para crear archivos de configuración de la base de datos virtual
function verify_config_files() {
    # Verificar si los archivos de configuración ya existen
    echo "Verificando si los archivos de configuración ya existen..."
    local error=0

    if [[ -f "$VIRTUAL_DOMAINS" ]]; then
        echo "El archivo de configuración '$VIRTUAL_DOMAINS' ya existe."
    else
        # Crear archivo de configuración 
        echo "Creando archivo de configuración: '$VIRTUAL_DOMAINS'... "
        if sudo touch "$VIRTUAL_DOMAINS"; then
            echo "Se ha creado el archivo '$VIRTUAL_DOMAINS'."
        else
            echo "ERROR: No se pudo crear el archivo '$VIRTUAL_DOMAINS'."
            error=1
        fi
    fi

    if [[ -f "$VIRTUAL_MAILBOX" ]]; then
        echo "El archivo de configuración '$VIRTUAL_MAILBOX' ya existe."
    else
        # Crear archivo de configuración 
        echo "Creando archivo de configuración: '$VIRTUAL_MAILBOX'... "
        if sudo touch "$VIRTUAL_MAILBOX"; then
            echo "Se ha creado el archivo '$VIRTUAL_MAILBOX'."
        else
            echo "ERROR: No se pudo crear el archivo '$VIRTUAL_MAILBOX'."
            error=1
        fi
    fi

    if [[ -f "$VIRTUAL_ALIAS" ]]; then
        echo "El archivo de configuración '$VIRTUAL_ALIAS' ya existe."
    else
        # Crear archivo de configuración 
        echo "Creando archivo de configuración: '$VIRTUAL_ALIAS'... "
        if sudo touch "$VIRTUAL_ALIAS"; then
            echo "Se ha creado el archivo '$VIRTUAL_ALIAS'."
        else
            echo "ERROR: No se pudo crear el archivo '$VIRTUAL_ALIAS'."
            error=1
        fi
    fi

    if [[ $error -eq 1 ]]; then
        echo "Hubo errores al crear los archivos de configuración."
        return 1
    else
        echo "Los archivos de configuración de la base de datos virtual se han verificado exitosamente."
        ls "$POSTFIX_PATH"
        return 0
    fi
}
# Función para realizar un respaldo de seguridad de los archivos de configuración
function backup_config_files() {
    # Verificar si los archivos de respaldo ya existen
    if [[ -f "$VIRTUAL_DOMAINS.bak" || -f "$VIRTUAL_MAILBOX.bak" || -f "$VIRTUAL_ALIAS.bak" ]]; then
        echo "ERROR: Uno o más archivos de respaldo ya existen."
        ls "$POSTFIX_PATH"
        return 1
    fi
    
    # Realizar un respaldo de seguridad de los archivos de configuración
    echo "Realizando un respaldo de seguridad de los archivos de configuración..."
    if ! sudo cp "$POSTFIX_MAIN" "$POSTFIX_MAIN.bak"; then
        echo "ERROR: No se pudo realizar el respaldo de seguridad de $POSTFIX_MAIN."
        return 1
    fi
    
    if ! sudo cp "$VIRTUAL_DOMAINS" "$VIRTUAL_DOMAINS.bak"; then
        echo "ERROR: No se pudo realizar el respaldo de seguridad de $VIRTUAL_DOMAINS."
        return 1
    fi
    
    if ! sudo cp "$VIRTUAL_MAILBOX" "$VIRTUAL_MAILBOX.bak"; then
        echo "ERROR: No se pudo realizar el respaldo de seguridad de $VIRTUAL_MAILBOX."
        return 1
    fi
    
    if ! sudo cp "$VIRTUAL_ALIAS" "$VIRTUAL_ALIAS.bak"; then
        echo "ERROR: No se pudo realizar el respaldo de seguridad de $VIRTUAL_ALIAS."
        return 1
    fi
    
    echo "Se han realizado los respaldos de seguridad de los archivos de configuración."
    ls "$POSTFIX_PATH"
    return 0
}
# Función para verificar si el archivo de dominios existe
function validate_domains_file() {
  echo "Verificando si el archivo de dominios existe..."
  if [ ! -f "$DOMAINS_PATH" ]; then
    echo "ERROR: El archivo de dominios '$DOMAINS_FILE' no se puede encontrar en la ruta '$DOMAINS_PATH'."
    exit 1
  fi
  echo "El archivo de dominios '$DOMAINS_FILE' existe."
}
# Función para leer la lista de dominios y configurar virtual_domains.cf, virtual_mailbox.cf y virtual_alias.cf
function read_domains_file() {
    # leer la lista de dominio
    echo "Leyendo la lista de dominios..."
    while read -r domain; do
        echo "Configurando dominio: $domain"
        # Configurar el archivo virtual_domains.cf
        echo "Configurando el archivo '$VIRTUAL_DOMAINS'..."
        if ! sudo echo "DBNAME=$POSTFIX_PATH/virtual_mailbox_$domain.db" >> "$VIRTUAL_DOMAINS"; then
            echo "ERROR: Error al escribir 'DBNAME=$POSTFIX_PATH/virtual_mailbox_$domain.db' en el archivo '$VIRTUAL_DOMAINS'."
            exit 1
        fi
        if ! sudo echo "QUERY=SELECT domain FROM domain WHERE domain='$domain' AND active = '1'" >> "$VIRTUAL_DOMAINS"; then
            echo "ERROR: Error al escribir 'QUERY=SELECT domain FROM domain WHERE domain='$domain' AND active = '1'' en el archivo '$VIRTUAL_DOMAINS'."
            exit 1
        fi
        # Configurar el archivo virtual_mailbox.cf
         echo "Configurando el archivo '$VIRTUAL_MAILBOX'..."
        if ! sudo echo "DBNAME=$POSTFIX_PATH/virtual_mailbox_$domain.db" >> "$VIRTUAL_MAILBOX"; then
            echo "ERROR: Error al escribir 'DBNAME=$POSTFIX_PATH/virtual_mailbox_$domain.db' en el archivo '$VIRTUAL_MAILBOX'."
            exit 1
        fi
        if ! sudo echo "QUERY=SELECT email FROM mailbox WHERE username='%u@$domain' AND active = '1'" >> "$VIRTUAL_MAILBOX"; then
            echo "ERROR: Error al escribir 'QUERY=SELECT email FROM mailbox WHERE username='%u@$domain' AND active = '1'' en el archivo '$VIRTUAL_MAILBOX'."
            exit 1
        fi
        # Configurar el archivo virtual_alias.cf
        echo "Configurando el archivo '$VIRTUAL_ALIAS'..."
        if ! sudo echo "DBNAME=$POSTFIX_PATH/virtual_mailbox_$domain.db" >> "$VIRTUAL_ALIAS"; then
            echo "ERROR: Error al escribir 'DBNAME=$POSTFIX_PATH/virtual_mailbox_$domain.db' en el archivo '$VIRTUAL_ALIAS'."
            exit 1
        fi
        if ! sudo echo "QUERY=SELECT email FROM alias WHERE source='%s@$domain' AND active = '1'" >> "$VIRTUAL_ALIAS"; then
            echo "ERROR: Error al escribir 'QUERY=SELECT email FROM alias WHERE source='%s@$domain' AND active = '1'' en el archivo '$VIRTUAL_ALIAS'."
            exit 1
        fi
    echo "Todos los archivos han sido configurados."
    done < <(sed -e '$a\' "$DOMAINS_PATH")
}
# Función para leer la lista de dominios y crear directorios
function mkdirs() {
    # leer la lista de dominio
    echo "Leyendo la lista de dominios..."
    while read -r domain; do
        # crear directorios
        echo "Creando directorio '$POSTFIX_PATH/dovecot/$domain'..."
        sudo mkdir -p "$POSTFIX_PATH/dovecot/$domain"
    done < <(sed -e '$a\' "$DOMAINS_PATH")
}
# Función para leer la lista de dominios y configurar el archivo main.cf
function config_postfix() {
    # leer la lista de dominio
    echo "Leyendo la lista de dominios..."
    while read -r domain; do
        echo "Configurando dominio: $domain"
        # Configurar el archivo main.cf
        echo "Configurando el archivo '$POSTFIX_MAIN'..."
        sudo sed -i "s/#myhostname =.*/myhostname = $domain/" $POSTFIX_MAIN || { echo "ERROR:al configurar el archivo '$POSTFIX_MAIN': myhostname"; exit 1; }
        sudo sed -i "s/#mydomain =.*/mydomain = $domain/" $POSTFIX_MAIN || { echo "ERROR: al configurar el archivo '$POSTFIX_MAIN': mydomain"; exit 1; }
        sudo sed -i "s/#myorigin =.*/myorigin = \$mydomain/" $POSTFIX_MAIN || { echo "ERROR: al configurar el archivo '$POSTFIX_MAIN': myorigin"; exit 1; }
        sudo sed -i "s/#virtual_alias_domains =.*/virtual_alias_domains = $1/" $POSTFIX_MAIN || { echo "ERROR: Error al configurar el archivo '$POSTFIX_MAIN': virtual_alias_domains"; exit 1; }         
        sudo sed -i "s|#smtpd_tls_cert_file =.*|smtpd_tls_cert_file = $POSTFIX_PATH\/$domain\/$CERT_FILE|" $POSTFIX_MAIN || { echo "ERROR: Error al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_cert_file"; exit 1; }
        sudo sed -i "s|#smtpd_tls_key_file =.*|smtpd_tls_key_file = $POSTFIX_PATH\/$domain\/$KEY_FILE|" $POSTFIX_MAIN || { echo "ERROR: Error al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_key_file"; exit 1; } 
    echo "El archivo '$POSTFIX_MAIN' ha sido configurado."
    done < <(sed -e '$a\' "$DOMAINS_PATH")
}
# Función principal
function postfix_config() {
  echo "***************POSTFIX CONFIG***************"
  verify_config_files
  backup_config_files
  validate_domains_file
  read_domains_file
  mkdirs
  #config_postfix
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
postfix_config
