#!/bin/bash
# postfix_config.sh
# Variables
MY_DOMAIN="avilesworks.com"
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
DOMAINS_FILE="domains.txt"
DOMAINS_PATH="$CURRENT_DIR/$DOMAINS_FILE"
POSTFIX_PATH="/etc/postfix"
POSTFIX_MAIN="$POSTFIX_PATH/main.cf"
VIRTUAL_DOMAINS="$POSTFIX_PATH/virtual_domains.cf"
VIRTUAL_MAILBOX="$POSTFIX_PATH/virtual_mailbox.cf"
VIRTUAL_ALIAS_CF="$POSTFIX_PATH/virtual_alias.cf"
VIRTUAL_ALIAS="$POSTFIX_PATH/virtual"
# Función para crear al usuario vmail:5000
function create_vmail_user() {
    # crear al usuario vmail:5000
    echo "Creando al usuario vmail:5000..."
    sudo groupadd -g 5000 vmail
    sudo useradd -u 5000 -g vmail -s /usr/bin/nologin -d /var/mail -m vmail
}
# Función para crear archivos de configuración de la base de datos virtual
function verify_config_files() {
    # Verificar si los archivos de configuración ya existen
    echo "Verificando si los archivos de configuración ya existen..."
    local error=0
    # Verificar si el archivo de configuración virtual_domains.cf ya existe
    echo "Verificando si el archivo de configuración virtual_domains.cf ya existe..."
    if [[ -f "$VIRTUAL_DOMAINS" ]]; then
        echo "El archivo de configuración '$VIRTUAL_DOMAINS' ya existe."
    else
        # Crear archivo de configuración virtual_domains.cf
        echo "Creando archivo de configuración: '$VIRTUAL_DOMAINS'... "
        if sudo touch "$VIRTUAL_DOMAINS"; then
            echo "Se ha creado el archivo '$VIRTUAL_DOMAINS'."
        else
            echo "ERROR: No se pudo crear el archivo '$VIRTUAL_DOMAINS'."
            error=1
        fi
    fi
    # Verificar si el archivo de configuración virtual_mailbox.cf ya existe
    echo "Verificando si el archivo de configuración virtual_mailbox.cf ya existe..."
    if [[ -f "$VIRTUAL_MAILBOX" ]]; then
        echo "El archivo de configuración '$VIRTUAL_MAILBOX' ya existe."
    else
        # Crear archivo de configuración virtual_mailbox.cf
        echo "Creando archivo de configuración: '$VIRTUAL_MAILBOX'... "
        if sudo touch "$VIRTUAL_MAILBOX"; then
            echo "Se ha creado el archivo '$VIRTUAL_MAILBOX'."
        else
            echo "ERROR: No se pudo crear el archivo '$VIRTUAL_MAILBOX'."
            error=1
        fi
    fi
    # Verificar si el archivo de configuración virtual_alias.cf ya existe
    echo "Verificando si el archivo de configuración virtual_alias.cf ya existe..."
    if [[ -f "$VIRTUAL_ALIAS_CF" ]]; then
        echo "El archivo de configuración '$VIRTUAL_ALIAS_CF' ya existe."
    else
        # Crear archivo de configuración virtual_alias.cf
        echo "Creando archivo de configuración: '$VIRTUAL_ALIAS_CF'... "
        if sudo touch "$VIRTUAL_ALIAS_CF"; then
            echo "Se ha creado el archivo '$VIRTUAL_ALIAS_CF'."
        else
            echo "ERROR: No se pudo crear el archivo '$VIRTUAL_ALIAS_CF'."
            error=1
        fi
    fi

    if [[ $error -eq 1 ]]; then
        echo "ERROR: Hubo errores al crear los archivos de configuración."
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
    if [[ -f "$VIRTUAL_DOMAINS.bak" || -f "$VIRTUAL_MAILBOX.bak" || -f "$VIRTUAL_ALIAS_CF.bak" ]]; then
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
    
    if ! sudo cp "$VIRTUAL_ALIAS_CF" "$VIRTUAL_ALIAS_CF.bak"; then
        echo "ERROR: No se pudo realizar el respaldo de seguridad de $VIRTUAL_ALIAS_CF."
        return 1
    fi
    
    echo "Se han realizado los respaldos de seguridad de los archivos de configuración."
    ls "$POSTFIX_PATH"
    return 0
}
# Función para verificar si el archivo de dominios existe
function validate_domains_file() {
    # verificar si el archivo de dominios existe
  echo "Verificando si el archivo de dominios existe..."
  if [ ! -f "$DOMAINS_PATH" ]; then
    echo "ERROR: El archivo de dominios '$DOMAINS_FILE' no se puede encontrar en la ruta '$DOMAINS_PATH'."
    exit 1
  fi
  echo "El archivo de dominios '$DOMAINS_FILE' existe."
}
# Función para crear un archivo base y copiar la lista de dominios en ese archivo
function create_domains_path() {
    # crear archivo base
    echo "Creando archivo base..."
    sudo touch "$POSTFIX_PATH/virtual_domains"
    # copiar la lista de dominios
    echo "Copiando la lista de dominios '$DOMAINS_PATH' al archivo base '$POSTFIX_PATH/virtual_domains'..."
    sudo cp "$DOMAINS_PATH" "$POSTFIX_PATH/virtual_domains"
    # mapear
    echo "Mapeando '$POSTFIX_PATH/virtual_domains'..."
    sudo postmap "$POSTFIX_PATH/virtual_domains"
}
# Función para leer la lista de dominios y configurar virtual_domains.cf, virtual_mailbox.cf y virtual_alias.cf
function config_virtual_files() {
    # leer la lista de dominios
    echo "Leyendo la lista de dominios..."
    while read -r domain; do
        echo "Configurando dominio: $domain"
        # Configurar el archivo virtual_domains.cf
        echo "Configurando el archivo '$VIRTUAL_DOMAINS'..."
        if ! sudo echo "DBNAME=/var/mail/vhosts/$domain.db" >> "$VIRTUAL_DOMAINS"; then
            echo "ERROR: Error al escribir 'DBNAME=/var/mail/vhosts/$domain.db' en el archivo '$VIRTUAL_DOMAINS'."
            exit 1
        fi
        if ! sudo echo "QUERY=SELECT domain FROM domain WHERE domain='$domain' AND active = '1'" >> "$VIRTUAL_DOMAINS"; then
            echo "ERROR: Error al escribir 'QUERY=SELECT domain FROM domain WHERE domain='$domain' AND active = '1'' en el archivo '$VIRTUAL_DOMAINS'."
            exit 1
        fi
        # Configurar el archivo virtual_mailbox.cf
         echo "Configurando el archivo '$VIRTUAL_MAILBOX'..."
        if ! sudo echo "DBNAME=/var/mail/vhosts/$domain.db" >> "$VIRTUAL_MAILBOX"; then
            echo "ERROR: Error al escribir 'DBNAME=/var/mail/vhosts/$domain.db' en el archivo '$VIRTUAL_MAILBOX'."
            exit 1
        fi
        if ! sudo echo "QUERY=SELECT email FROM mailbox WHERE username='%u@$domain' AND active = '1'" >> "$VIRTUAL_MAILBOX"; then
            echo "ERROR: Error al escribir 'QUERY=SELECT email FROM mailbox WHERE username='%u@$domain' AND active = '1'' en el archivo '$VIRTUAL_MAILBOX'."
            exit 1
        fi
        # Configurar el archivo virtual_alias.cf
        echo "Configurando el archivo '$VIRTUAL_ALIAS_CF'..."
        if ! sudo echo "DBNAME=/var/mail/vhosts/$domain.db" >> "$VIRTUAL_ALIAS_CF"; then
            echo "ERROR: Error al escribir 'DBNAME=/var/mail/vhosts/$domain.db' en el archivo '$VIRTUAL_ALIAS_CF'."
            exit 1
        fi
        if ! sudo echo "QUERY=SELECT email FROM alias WHERE source='%s@$domain' AND active = '1'" >> "$VIRTUAL_ALIAS_CF"; then
            echo "ERROR: Error al escribir 'QUERY=SELECT email FROM alias WHERE source='%s@$domain' AND active = '1'' en el archivo '$VIRTUAL_ALIAS_CF'."
            exit 1
        fi
    done < <(sed -e '$a\' "$DOMAINS_PATH")
    echo "Todos los archivos han sido configurados."
}
# Función para leer la lista de dominios y configurar el archivo main.cf
function config_postfix() {
    virtual_mailbox_domains=""
    while read -r domain; do
        virtual_mailbox_domains+="$domain, "
    done < <(sed -e '$a\' "$DOMAINS_PATH")
    #virtual_mailbox_domains
    if grep -q "#virtual_mailbox_domains" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#virtual_mailbox_domains =.*/virtual_mailbox_domains = ${virtual_mailbox_domains::-1}/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #virtual_mailbox_domains"; exit 1; }
    elif grep -q "virtual_mailbox_domains" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^virtual_mailbox_domains =.*/virtual_mailbox_domains = ${virtual_mailbox_domains::-1}/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': virtual_mailbox_domains"; exit 1; }
    else
        echo "virtual_mailbox_domains = ${virtual_mailbox_domains::-1}" >> "$POSTFIX_MAIN"
    fi
    echo "virtual_mailbox_domains = ${virtual_mailbox_domains::-1}" >> "$CURRENT_DIR/test.txt"
    #virtual_mailbox_base
    if grep -q "#virtual_mailbox_base" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#virtual_mailbox_base =.*|virtual_mailbox_base = /var/mail/|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #virtual_mailbox_base"; exit 1; }
    elif grep -q "virtual_mailbox_maps" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^virtual_mailbox_base =.*|virtual_mailbox_base = /var/mail/|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': virtual_mailbox_base"; exit 1; }
    else
        echo "virtual_mailbox_base = /var/mail/" >> "$POSTFIX_MAIN"
    fi
    echo "virtual_mailbox_base = /var/mail/" >> "$CURRENT_DIR/test.txt"
    #virtual_mailbox_maps
    if grep -q "#virtual_mailbox_maps" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#virtual_mailbox_maps =.*|virtual_mailbox_maps = hash:/etc/postfix/virtual_alias_maps|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #virtual_mailbox_maps"; exit 1; }
    elif grep -q "virtual_mailbox_maps" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^virtual_mailbox_maps =.*|virtual_mailbox_maps = hash:/etc/postfix/virtual_alias_maps|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': virtual_mailbox_maps"; exit 1; }
    else
        echo "virtual_mailbox_maps = hash:/etc/postfix/virtual_alias_maps" >> "$POSTFIX_MAIN"
    fi
    echo "virtual_mailbox_maps = hash:/etc/postfix/virtual_alias_maps" >> "$CURRENT_DIR/test.txt"
    #virtual_alias_maps
    if grep -q "#virtual_alias_maps" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#virtual_alias_maps =.*|virtual_alias_maps = hash:/etc/postfix/virtual_alias_maps|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #virtual_alias_maps"; exit 1; }
    elif grep -q "virtual_alias_maps" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^virtual_alias_maps =.*|virtual_alias_maps = hash:/etc/postfix/virtual_alias_maps|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': virtual_alias_maps"; exit 1; }
    else
        echo "virtual_alias_maps = hash:/etc/postfix/virtual_alias_maps" >> "$POSTFIX_MAIN"
    fi
    echo "virtual_alias_maps = hash:/etc/postfix/virtual_alias_maps" >> "$CURRENT_DIR/test.txt"
    #virtual_transport
    if grep -q "#virtual_transport" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#virtual_transport =.*|virtual_transport = lmtp:unix:private/dovecot-lmtp|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #virtual_transport"; exit 1; }
    elif grep -q "virtual_transport" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^virtual_transport =.*|virtual_transport = lmtp:unix:private/dovecot-lmtp|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': virtual_transport"; exit 1; }
    else
        echo "virtual_transport = lmtp:unix:private/dovecot-lmtp" >> "$POSTFIX_MAIN"
    fi
    echo "virtual_transport = lmtp:unix:private/dovecot-lmtp" >> "$CURRENT_DIR/test.txt"
    #virtual_alias_domains
    if grep -q "#virtual_alias_domains" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#virtual_alias_domains =.*|virtual_alias_domains = hash:/etc/postfix/virtual_domains|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #virtual_alias_domains"; exit 1; }
    elif grep -q "virtual_alias_domains" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^virtual_alias_domains =.*|virtual_alias_domains = hash:/etc/postfix/virtual_domains|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': virtual_alias_domains"; exit 1; }
    else
        echo "virtual_alias_domains = hash:/etc/postfix/virtual_domains" >> "$POSTFIX_MAIN"
    fi
    echo "virtual_alias_domains = hash:/etc/postfix/virtual_domains" >> "$CURRENT_DIR/test.txt"
    #smtpd_tls_cert_file
    if grep -q "#smtpd_tls_cert_file" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#smtpd_tls_cert_file=.*|smtpd_tls_cert_file=/etc/dovecot/certs/samava.pem|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtpd_tls_cert_file"; exit 1; }
    elif grep -q "smtpd_tls_cert_file" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^smtpd_tls_cert_file=.*|smtpd_tls_cert_file=/etc/dovecot/certs/samava.pem|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_cert_file"; exit 1; }
    else
        echo "smtpd_tls_cert_file= /etc/dovecot/certs/samava.pem" >> "$POSTFIX_MAIN"
    fi
    echo "smtpd_tls_cert_file=/etc/dovecot/certs/samava.pem" >> "$CURRENT_DIR/test.txt"
    #smtpd_tls_key_file
    if grep -q "#smtpd_tls_key_file" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#smtpd_tls_key_file=.*|smtpd_tls_key_file=/etc/dovecot/certs/samava.key|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtpd_tls_key_file"; exit 1; }
    elif grep -q "smtpd_tls_key_file" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^smtpd_tls_key_file=.*|smtpd_tls_key_file=/etc/dovecot/certs/samava.key|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_key_file"; exit 1; }
    else
        echo "smtpd_tls_key_file=/etc/dovecot/certs/samava.key" >> "$POSTFIX_MAIN"
    fi
    echo "smtpd_tls_key_file=/etc/dovecot/certs/samava.key" >> "$CURRENT_DIR/test.txt"
    #smtpd_tls_security_level
    if grep -q "#smtpd_tls_security_level" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_tls_security_level =.*/smtpd_tls_security_level = may/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtpd_tls_security_level"; exit 1; }
    elif grep -q "smtpd_tls_security_level" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^smtpd_tls_security_level =.*/smtpd_tls_security_level = may/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_security_level"; exit 1; }
    else
        echo "smtpd_tls_security_level = may" >> "$POSTFIX_MAIN"
    fi
    echo "smtpd_tls_security_level = may" >> "$CURRENT_DIR/test.txt"
    #smtpd_use_tls
    if grep -q "#smtpd_use_tls" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_use_tls =.*/smtpd_use_tls = yes/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtpd_use_tls"; exit 1; }
    elif grep -q "smtpd_use_tls" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^smtpd_use_tls =.*/smtpd_use_tls = yes/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_use_tls"; exit 1; }
    else
        echo "smtpd_use_tls = yes" >> "$POSTFIX_MAIN"
    fi
    echo "smtpd_use_tls = yes" >> "$CURRENT_DIR/test.txt"
    #smtpd_sasl_auth_enable
    if grep -q "#smtpd_sasl_auth_enable" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_sasl_auth_enable =.*/smtpd_sasl_auth_enable = yes/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtpd_sasl_auth_enable"; exit 1; }
    elif grep -q "smtpd_sasl_auth_enable" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^smtpd_sasl_auth_enable =.*/smtpd_sasl_auth_enable = yes/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_auth_enable"; exit 1; }
    else
        echo "smtpd_sasl_auth_enable = yes" >> "$POSTFIX_MAIN"
    fi
    echo "smtpd_sasl_auth_enable = yes" >> "$CURRENT_DIR/test.txt"
    #smtpd_sasl_type
    if grep -q "#smtpd_sasl_type" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_sasl_type =.*/smtpd_sasl_type = dovecot/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtpd_sasl_type"; exit 1; }
    elif grep -q "smtpd_sasl_type" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^smtpd_sasl_type =.*/smtpd_sasl_type = dovecot/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_type"; exit 1; }
    else
        echo "smtpd_sasl_type = dovecot" >> "$POSTFIX_MAIN"
    fi
    echo "smtpd_sasl_type = dovecot" >> "$CURRENT_DIR/test.txt"
    #smtpd_sasl_path
    if grep -q "#smtpd_sasl_path" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#smtpd_sasl_path =.*|smtpd_sasl_path = private/auth|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtpd_sasl_path"; exit 1; }
    elif grep -q "smtpd_sasl_path" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^smtpd_sasl_path =.*|smtpd_sasl_path = private/auth|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_path"; exit 1; }
    else
        echo "smtpd_sasl_path = private/auth" >> "$POSTFIX_MAIN"
    fi
    echo "smtpd_sasl_path = private/auth" >> "$CURRENT_DIR/test.txt"
    #smtpd_sasl_local_domain
    if grep -q "#smtpd_sasl_local_domain" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#smtpd_sasl_local_domain =.*|smtpd_sasl_local_domain = /etc/postfix/$MY_DOMAIN|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtpd_sasl_local_domain"; exit 1; }
    elif grep -q "smtpd_sasl_local_domain" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^smtpd_sasl_local_domain =.*|smtpd_sasl_local_domain = /etc/postfix/$MY_DOMAIN|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_local_domain"; exit 1; }
    else
        echo "smtpd_sasl_local_domain = /etc/postfix/$MY_DOMAIN" >> "$POSTFIX_MAIN"
    fi
    echo "smtpd_sasl_local_domain = /etc/postfix/$MY_DOMAIN" >> "$CURRENT_DIR/test.txt"
    #smtpd_sasl_security_options
    if grep -q "#smtpd_sasl_security_options" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_sasl_security_options =.*/smtpd_sasl_security_options = noanonymous/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtpd_sasl_security_options"; exit 1; }
    elif grep -q "smtpd_sasl_security_options" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^smtpd_sasl_security_options =.*/smtpd_sasl_security_options = noanonymous/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_security_options"; exit 1; }
    else
        echo "smtpd_sasl_security_options = noanonymous" >> "$POSTFIX_MAIN"
    fi
    echo "smtpd_sasl_security_options = noanonymous" >> "$CURRENT_DIR/test.txt"
    #broken_sasl_auth_clients
    if grep -q "#broken_sasl_auth_clients" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#broken_sasl_auth_clients =.*/broken_sasl_auth_clients = yes/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #broken_sasl_auth_clients"; exit 1; }
    elif grep -q "broken_sasl_auth_clients" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^broken_sasl_auth_clients =.*/broken_sasl_auth_clients = yes/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': broken_sasl_auth_clients"; exit 1; }
    else
        echo "broken_sasl_auth_clients = yes" >> "$POSTFIX_MAIN"
    fi
    echo "broken_sasl_auth_clients = yes" >> "$CURRENT_DIR/test.txt"
    #mydomain
    if grep -q "#mydomain" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#mydomain =.*/mydomain = $MY_DOMAIN/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #mydomain"; exit 1; }
    elif grep -q "mydomain" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^mydomain =.*/mydomain = $MY_DOMAIN/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': mydomain"; exit 1; }
    else
        echo "mydomain = $MY_DOMAIN" >> "$POSTFIX_MAIN"
    fi
    echo "mydomain = $MY_DOMAIN" >> "$CURRENT_DIR/test.txt"
    #myhostname
    if grep -q "#myhostname" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#myhostname =.*/myhostname = mail.$MY_DOMAIN/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #myhostname"; exit 1; }
    elif grep -q "myhostname" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^myhostname =.*/myhostname = mail.$MY_DOMAIN/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': myhostname"; exit 1; }
    else
        echo "myhostname = mail.$MY_DOMAIN" >> "$POSTFIX_MAIN"
    fi
    echo "myhostname = mail.$MY_DOMAIN" >> "$CURRENT_DIR/test.txt"
    #mydestination
    if grep -q "#mydestination" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#mydestination =.*/mydestination = localhost.localdomain, localhost/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #mydestination"; exit 1; }
    elif grep -q "mydestination" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^mydestination =.*/mydestination = localhost.localdomain, localhost/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': mydestination"; exit 1; }
    else
        echo "mydestination = localhost.localdomain, localhost" >> "$POSTFIX_MAIN"
    fi
    echo "mydestination = localhost.localdomain, localhost" >> "$CURRENT_DIR/test.txt"
    #compatibility_level
    if grep -q "#compatibility_level" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#compatibility_level =.*/compatibility_level = 3.6/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #compatibility_level"; exit 1; }
    elif grep -q "compatibility_level" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^compatibility_level =.*/compatibility_level = 3.6/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': compatibility_level"; exit 1; }
    else
        echo "compatibility_level = 3.6" >> "$POSTFIX_MAIN"
    fi
    echo "compatibility_level = 3.6" >> "$CURRENT_DIR/test.txt"
    #smtpd_tls_loglevel
    if grep -q "#smtpd_tls_loglevel" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_tls_loglevel =.*/smtpd_tls_loglevel = 1/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtpd_tls_loglevel"; exit 1; }
    elif grep -q "smtpd_tls_loglevel" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^smtpd_tls_loglevel =.*/smtpd_tls_loglevel = 1/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_loglevel"; exit 1; }
    else
        echo "smtpd_tls_loglevel = 1" >> "$POSTFIX_MAIN"
    fi
    echo "smtpd_tls_loglevel = 1" >> "$CURRENT_DIR/test.txt"
    #smtpd_tls_received_header
    if grep -q "#smtpd_tls_received_header" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_tls_received_header =.*/smtpd_tls_received_header = yes/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtpd_tls_received_header"; exit 1; }
    elif grep -q "smtpd_tls_received_header" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^smtpd_tls_received_header =.*/smtpd_tls_received_header = yes/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_received_header"; exit 1; }
    else
        echo "smtpd_tls_received_header = yes" >> "$POSTFIX_MAIN"
    fi
    echo "smtpd_tls_received_header = yes" >> "$CURRENT_DIR/test.txt"
    #smtpd_tls_session_cache_timeout
    if grep -q "#smtpd_tls_session_cache_timeout" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_tls_session_cache_timeout =.*/smtpd_tls_session_cache_timeout = 3600s/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtpd_tls_session_cache_timeout"; exit 1; }
    elif grep -q "smtpd_tls_session_cache_timeout" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^smtpd_tls_session_cache_timeout =.*/smtpd_tls_session_cache_timeout = 3600s/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_session_cache_timeout"; exit 1; }
    else
        echo "smtpd_tls_session_cache_timeout = 3600s" >> "$POSTFIX_MAIN"
    fi
    echo "smtpd_tls_session_cache_timeout = 3600s" >> "$CURRENT_DIR/test.txt"
    #tls_random_source
    if grep -q "#tls_random_source" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#tls_random_source =.*|tls_random_source = dev:/dev/urandom|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #tls_random_source"; exit 1; }
    elif grep -q "tls_random_source" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^tls_random_source =.*|tls_random_source = dev:/dev/urandom|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': tls_random_source"; exit 1; }
    else
        echo "tls_random_source = dev:/dev/urandom" >> "$POSTFIX_MAIN"
    fi
    echo "tls_random_source = dev:/dev/urandom" >> "$CURRENT_DIR/test.txt"
    #mynetworks
    if grep -q "#mynetworks" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#mynetworks =.*|mynetworks = 0.0.0.0/0|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #mynetworks"; exit 1; }
    elif grep -q "mynetworks" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^mynetworks =.*|mynetworks = 0.0.0.0/0|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': mynetworks"; exit 1; }
    else
        echo "mynetworks = 0.0.0.0/0" >> "$POSTFIX_MAIN"
    fi
    echo "mynetworks = 0.0.0.0/0" >> "$CURRENT_DIR/test.txt"
  
    #virtual_minimum_uid
    if grep -q "#virtual_minimum_uid" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#virtual_minimum_uid =.*|virtual_minimum_uid = 5000|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #virtual_minimum_uid"; exit 1; }
    elif grep -q "virtual_minimum_uid" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#virtual_minimum_uid =.*|virtual_minimum_uid = 5000|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': virtual_minimum_uid"; exit 1; }
    else
        echo "virtual_minimum_uid= 5000" >> "$POSTFIX_MAIN"
    fi
    echo "virtual_minimum_uid = 5000" >> "$CURRENT_DIR/test.txt"
    #vvirtual_uid_maps
    if grep -q "#virtual_uid_maps" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#virtual_uid_maps =.*|virtual_uid_maps = static:5000|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #virtual_uid_maps"; exit 1; }
    elif grep -q "virtual_uid_maps" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^virtual_uid_maps =.*|virtual_uid_maps = static:5000|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': virtual_uid_maps"; exit 1; }
    else
        echo "virtual_uid_maps = static:5000" >> "$POSTFIX_MAIN"
    fi
    echo "virtual_uid_maps = static:5000" >> "$CURRENT_DIR/test.txt"
    #virtual_gid_maps
    if grep -q "#virtual_gid_maps" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#virtual_gid_maps =.*|virtual_gid_maps = static:5000|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #virtual_gid_maps"; exit 1; }
    elif grep -q "virtual_gid_maps" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^virtual_gid_maps =.*|virtual_gid_maps = static:5000|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': virtual_gid_maps"; exit 1; }
    else
        echo "virtual_gid_maps = static:5000" >> "$POSTFIX_MAIN"
    fi
    echo "virtual_gid_maps = static:5000" >> "$CURRENT_DIR/test.txt"
    #inet_protocols
    if grep -q "#inet_protocols" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#inet_protocols =.*|inet_protocols = ipv4|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #inet_protocols"; exit 1; }
    elif grep -q "inet_protocols" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^inet_protocols =.*|inet_protocols = ipv4|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': inet_protocols"; exit 1; }
    else
        echo "inet_protocols = ipv4" >> "$POSTFIX_MAIN"
    fi
    echo "inet_protocols = ipv4" >> "$CURRENT_DIR/test.txt"
    #sasl_password_maps
    if grep -q "#sasl_password_maps" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#sasl_password_maps =.*|sasl_password_maps = hash:/etc/dovecot/users|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #sasl_password_maps"; exit 1; }
    elif grep -q "sasl_password_maps" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^sasl_password_maps =.*|sasl_password_maps = hash:/etc/dovecot/users|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': sasl_password_maps"; exit 1; }
    else
        echo "sasl_password_maps = hash:/etc/dovecot/users" >> "$POSTFIX_MAIN"
    fi
    echo "sasl_password_maps = hash:/etc/dovecot/users" >> "$CURRENT_DIR/test.txt"
    #smtputf8_enable
    if grep -q "#smtputf8_enable" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#smtputf8_enable =.*|smtputf8_enable = no|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtputf8_enable"; exit 1; }
    elif grep -q "smtputf8_enable" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^smtputf8_enable =.*|smtputf8_enable = no|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtputf8_enable"; exit 1; }
    else
        echo "smtputf8_enable = no" >> "$POSTFIX_MAIN"
    fi
    echo "smtputf8_enable = no" >> "$CURRENT_DIR/test.txt"
    #disable_dns_lookups
    if grep -q "#disable_dns_lookups" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#disable_dns_lookups =.*|disable_dns_lookups = no|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #disable_dns_lookups"; exit 1; }
    elif grep -q "disable_dns_lookups" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^disable_dns_lookups =.*|disable_dns_lookups = no|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': disable_dns_lookups"; exit 1; }
    else
        echo "disable_dns_lookups = no" >> "$POSTFIX_MAIN"
    fi
    echo "disable_dns_lookups = no" >> "$CURRENT_DIR/test.txt"
    #smtp_host_lookup
    if grep -q "#smtp_host_lookup" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#smtp_host_lookup =.*|smtp_host_lookup = dns|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtp_host_lookup"; exit 1; }
    elif grep -q "smtp_host_lookup" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^smtp_host_lookup =.*|smtp_host_lookup = dns|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtp_host_lookup"; exit 1; }
    else
        echo "smtp_host_lookup = dns" >> "$POSTFIX_MAIN"
    fi
    echo "smtp_host_lookup = dns" >> "$CURRENT_DIR/test.txt"
    #smtpd_tls_protocols
    if grep -q "#smtpd_tls_protocols" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#smtpd_tls_protocols =.*|smtpd_tls_protocols = !SSLv2,!SSLv3|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtpd_tls_protocols"; exit 1; }
    elif grep -q "smtpd_tls_protocols" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^smtpd_tls_protocols =.*|smtpd_tls_protocols = !SSLv2,!SSLv3|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_protocols"; exit 1; }
    else
        echo "smtpd_tls_protocols = !SSLv2,!SSLv3" >> "$POSTFIX_MAIN"
    fi
    echo "smtpd_tls_protocols = !SSLv2,!SSLv3" >> "$CURRENT_DIR/test.txt"
    #smtpd_tls_mandatory_protocols
    if grep -q "#smtpd_tls_mandatory_protocols" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#smtpd_tls_mandatory_protocols =.*|smtpd_tls_mandatory_protocols = !SSLv2,!SSLv3|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtpd_tls_mandatory_protocols"; exit 1; }
    elif grep -q "smtpd_tls_mandatory_protocols" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^smtpd_tls_mandatory_protocols =.*|smtpd_tls_mandatory_protocols = !SSLv2,!SSLv3|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_mandatory_protocols"; exit 1; }
    else
        echo "smtpd_tls_mandatory_protocols = !SSLv2,!SSLv3" >> "$POSTFIX_MAIN"
    fi
    echo "smtpd_tls_mandatory_protocols = !SSLv2,!SSLv3" >> "$CURRENT_DIR/test.txt"
    #smtp_enforce_tls
    if grep -q "#smtp_enforce_tls" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#smtp_enforce_tls =.*|smtp_enforce_tls = yes|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #smtp_enforce_tls"; exit 1; }
    elif grep -q "smtp_enforce_tls" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^smtp_enforce_tls =.*|smtp_enforce_tls = yes|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtp_enforce_tls"; exit 1; }
    else
        echo "smtp_enforce_tls = yes" >> "$POSTFIX_MAIN"
    fi
    echo "smtp_enforce_tls = yes" >> "$CURRENT_DIR/test.txt"
     #mailbox_command
    if grep -q "#mailbox_command" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^#mailbox_command =.*|mailbox_command = /usr/lib/dovecot/deliver|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': #mailbox_command"; exit 1; }
    elif grep -q "mailbox_command" "$POSTFIX_MAIN"; then
        sudo sed -i "s|^mailbox_command =.*|mailbox_command = /usr/lib/dovecot/deliver|" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': mailbox_command"; exit 1; }
    else
        echo "mailbox_command = /usr/lib/dovecot/deliver" >> "$POSTFIX_MAIN"
    fi
    echo "mailbox_command = /usr/lib/dovecot/deliver" >> "$CURRENT_DIR/test.txt"
}
# Función para comprobar la configuracion de Postfix
function postfix_check() {
    # comprobar la configuracion de Postfix
    echo "Comprobando la configuracion de Postfix..."
    if sudo postfix check; then
        echo "El archivo '$POSTFIX_MAIN' ha sido configurado exitosamente."
    else
        echo "Falla al configurar '$POSTFIX_MAIN'"
    fi
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
function postfix_config() {
  echo "***************POSTFIX CONFIG***************"
  create_vmail_user
  verify_config_files
  backup_config_files
  validate_domains_file
  create_domains_path
  config_virtual_files
  config_postfix
  postfix_check
  restart_services
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
postfix_config
