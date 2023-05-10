#!/bin/bash
# postfix_config.sh
# Variables
LOG_FILE="/var/log/mail.log"
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
DOMAINS_FILE="domains.txt"
DOMAINS_PATH="$CURRENT_DIR/$DOMAINS_FILE"
ACCOUNTS_FILE="mail_users.csv"
ACCOUNTS_PATH="$CURRENT_DIR/$ACCOUNTS_FILE"
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
    done < <(sed -e '$a\' "$DOMAINS_PATH")
    echo "Todos los archivos han sido configurados."
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
    echo "Todos los directorios han sido creados."
    ls "$POSTFIX_PATH/dovecot"
}
# Función para leer la lista de dominios y configurar el archivo main.cf
function config_postfix() {
    virtual_alias_domains=""
    while read -r domain; do
        # leer la lista de dominio
        echo "Leyendo la lista de dominios '$DOMAINS_PATH'..."
        # Generar archivo de prueba
        echo "Generando archivo de prueba para el dominio: $domain"
        echo "mydomain = $domain" >> "$CURRENT_DIR/$domain.test"
        echo "myhostname = mail.$domain" > "$CURRENT_DIR/$domain.test"
        echo "myorigin = \$mydomain" >> "$CURRENT_DIR/$domain.test"

        virtual_alias_domains+="$domain "
    done < <(sed -e '$a\' "$DOMAINS_PATH")
    echo "Configurando el archivo '$POSTFIX_MAIN' con los dominios virtuales..."
    # Generar archivo de prueba
    echo "virtual_mailbox_domains = mysql:$VIRTUAL_DOMAINS" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#virtual_mailbox_domains =./virtual_mailbox_domains = mysql:$VIRTUAL_DOMAINS" $POSTFIX_MAIN || { echo "ERROR:al configurar el archivo '$POSTFIX_MAIN': virtual_mailbox_domains"; exit 1; }
    echo "virtual_mailbox_maps = mysql:$VIRTUAL_MAILBOX" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#virtual_mailbox_maps =./virtual_mailbox_maps = mysql:$VIRTUAL_MAILBOX" $POSTFIX_MAIN || { echo "ERROR:al configurar el archivo '$POSTFIX_MAIN': virtual_mailbox_maps"; exit 1; }
    echo "virtual_alias_maps = hash:$VIRTUAL_ALIAS" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#virtual_alias_maps =./virtual_alias_maps = hash:$VIRTUAL_ALIAS" $POSTFIX_MAIN || { echo "ERROR:al configurar el archivo '$POSTFIX_MAIN': virtual_alias_maps"; exit 1; }
    echo "virtual_transport = lmtp:unix:private/dovecot-lmtp" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#virtual_transport =./virtual_transport = lmtp:unix:private/dovecot-lmtp" $POSTFIX_MAIN || { echo "ERROR:al configurar el archivo '$POSTFIX_MAIN': virtual_transport"; exit 1; }
    echo "virtual_alias_domains = ${virtual_alias_domains::-1}" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s|^#virtual_alias_domains =.*|virtual_alias_domains = ${virtual_alias_domains::-1}" $POSTFIX_MAIN || { echo "ERROR: al configurar el archivo '$POSTFIX_MAIN': virtual_alias_domains"; exit 1; }
    echo "smtpd_tls_cert_file = /etc/ssl/certs/$CERT_FILE" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s|^#smtpd_tls_cert_file =.*|smtpd_tls_cert_file = /etc/ssl/certs/$CERT_FILE|" $POSTFIX_MAIN || { echo "ERROR: Error al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_cert_file"; exit 1; }
    echo "smtpd_tls_key_file = /etc/ssl/private/$KEY_FILE" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s|^#smtpd_tls_key_file =.*|smtpd_tls_key_file = /etc/ssl/private/$KEY_FILE|" $POSTFIX_MAIN || { echo "ERROR: Error al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_key_file"; exit 1; } 
    echo "smtpd_tls_security_level = may" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "/^#smtpd_tls_security_level =./smtpd_tls_security_level = may" $POSTFIX_MAIN || { echo "ERROR: Error al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_security_level"; exit 1; } 
    echo "smtpd_use_tls = yes" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#smtpd_use_tls =./smtpd_use_tls = yes" $POSTFIX_MAIN || { echo "ERROR: Error al configurar el archivo '$POSTFIX_MAIN': smtpd_use_tls; exit 1; } 
    echo "smtpd_sasl_auth_enable = yes" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#smtpd_sasl_auth_enable =./smtpd_sasl_auth_enable = yes" $POSTFIX_MAIN || { echo "ERROR: Error al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_auth_enable"; exit 1; } 
    echo "smtpd_sasl_type = dovecot" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#smtpd_sasl_type =./smtpd_sasl_type = dovecot" $POSTFIX_MAIN || { echo "ERROR: Error al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_type"; exit 1; } 
    echo "smtpd_sasl_path = private/auth" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#smtpd_sasl_path =./smtpd_sasl_path = private/auth" $POSTFIX_MAIN || { echo "ERROR: Error al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_path"; exit 1; } 
    echo "smtpd_sasl_local_domain =" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#smtpd_sasl_local_domain =./smtpd_sasl_local_domain =" $POSTFIX_MAIN || { echo "ERROR: Error al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_local_domain"; exit 1; } 
    echo "smtpd_sasl_security_options = noanonymous" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#smtpd_sasl_security_options =./smtpd_sasl_security_options = noanonymous" $POSTFIX_MAIN || { echo "ERROR: Error al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_security_options"; exit 1; } 
    echo "broken_sasl_auth_clients = yes" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#broken_sasl_auth_clients =./broken_sasl_auth_clients = yes" $POSTFIX_MAIN || { echo "ERROR: Error al configurar el archivo '$POSTFIX_MAIN': broken_sasl_auth_clients"; exit 1; } 
    echo "mydomain = example.com" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#mydomain =.*/mydomain = example.com" $POSTFIX_MAIN || { echo "ERROR: al configurar el archivo '$POSTFIX_MAIN': mydomain"; exit 1; }
    echo "myhostname = mail.example.com" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#myhostname =.*/myhostname = mail.example.com" $POSTFIX_MAIN || { echo "ERROR:al configurar el archivo '$POSTFIX_MAIN': myhostname"; exit 1; }
    echo "mydestination = \$myhostname, localhost.$myhostname, localhost" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#mydestination =.*/mydestination = \$myhostname, localhost.$myhostname, localhost" $POSTFIX_MAIN || { echo "ERROR: al configurar el archivo '$POSTFIX_MAIN': mydestination"; exit 1; }
    echo "myorigin = \$mydomain" >> "$CURRENT_DIR/test.txt"
    #sudo sed -i "s/^#myorigin =.*/myorigin = \$mydomain" $POSTFIX_MAIN || { echo "ERROR: al configurar el archivo '$POSTFIX_MAIN': myorigin"; exit 1; }
    echo "" >> "$CURRENT_DIR/test.txt"
    echo "El archivo '$POSTFIX_MAIN' ha sido configurado."
}
# Función para leer la lista de direcciones de correo
function read_accounts() {
    while IFS="," read -r username nombre apellido email alias password; do
        # leer la lista de direcciones de correo
        echo "Leyendo la lista de dominios '$ACCOUNTS_PATH'..."
        # Generar archivo de prueba
        echo "Usario: $username"
        echo "Correo principal: $email"
        echo "Correo secundario: $alias"
        echo "Contraseña: ${password:0:3}*********"
        #sudo adduser "$alias"
        #sudo mkmailbox "$alias"
   
    done < <(sed -e '$a\' "$ACCOUNTS_PATH")
}
# Función principal
function postfix_config() {
  echo "***************POSTFIX CONFIG***************"
  verify_config_files
  backup_config_files
  validate_domains_file
  read_domains_file
  mkdirs
  config_postfix
  read_accounts
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
postfix_config
