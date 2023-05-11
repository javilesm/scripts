#!/bin/bash
# postfix_config.sh
# Variables
MY_DOMAIN="avilesworks.com"
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
VIRTUAL_ALIAS_CF="$POSTFIX_PATH/virtual_alias.cf"
VIRTUAL_ALIAS="$POSTFIX_PATH/virtual"
CERT_FILE="ssl-cert-snakeoil.pem" # default self-signed certificate that comes with Ubuntu
KEY_FILE="ssl-cert-snakeoil.key"
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
        echo "Configurando el archivo '$VIRTUAL_ALIAS_CF'..."
        if ! sudo echo "DBNAME=$POSTFIX_PATH/virtual_mailbox_$domain.db" >> "$VIRTUAL_ALIAS_CF"; then
            echo "ERROR: Error al escribir 'DBNAME=$POSTFIX_PATH/virtual_mailbox_$domain.db' en el archivo '$VIRTUAL_ALIAS_CF'."
            exit 1
        fi
        if ! sudo echo "QUERY=SELECT email FROM alias WHERE source='%s@$domain' AND active = '1'" >> "$VIRTUAL_ALIAS_CF"; then
            echo "ERROR: Error al escribir 'QUERY=SELECT email FROM alias WHERE source='%s@$domain' AND active = '1'' en el archivo '$VIRTUAL_ALIAS_CF'."
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
        virtual_alias_domains+="$domain "
    done < <(sed -e '$a\' "$DOMAINS_PATH")
    #1virtual_mailbox_domains
    if grep -q "#virtual_mailbox_domains" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#virtual_mailbox_domains =./virtual_mailbox_domains = mysql:/etc/postfix/virtual_domains.cf" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un provlema al configurar el archivo '$POSTFIX_MAIN': virtual_mailbox_domains"; exit 1; }
    else
        echo "virtual_mailbox_domains = mysql:/etc/postfix/virtual_domains.cf" >> "$POSTFIX_MAIN"
    fi
    #2virtual_mailbox_maps
    if grep -q "#virtual_mailbox_maps" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#virtual_mailbox_maps =./virtual_mailbox_maps = mysql:/etc/postfix/virtual_mailbox.cf/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': virtual_mailbox_maps"; exit 1; }
    else
        echo "virtual_mailbox_maps = mysql:/etc/postfix/virtual_mailbox.cf" >> "$POSTFIX_MAIN"
    fi
    #3virtual_alias_maps
    if grep -q "#virtual_alias_maps" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#virtual_alias_maps =./virtual_alias_maps = hash:/etc/postfix/virtual/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': virtual_alias_maps"; exit 1; }
    else
        echo "virtual_alias_maps = hash:/etc/postfix/virtual" >> "$POSTFIX_MAIN"
    fi
    #4virtual_transport
    if grep -q "#virtual_transport" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#virtual_transport =./virtual_transport = lmtp:unix:private/dovecot-lmtp/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': virtual_transport"; exit 1; }
    else
        echo "virtual_transport = lmtp:unix:private/dovecot-lmtp" >> "$POSTFIX_MAIN"
    fi
    #5virtual_alias_domains
    if grep -q "#virtual_alias_domains" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#virtual_alias_domains =./virtual_alias_domains = ${virtual_alias_domains::-1}/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': virtual_alias_domains"; exit 1; }
    else
        echo "virtual_alias_domains = ${virtual_alias_domains::-1}" >> "$POSTFIX_MAIN"
    fi
    #6smtpd_tls_cert_file
    if grep -q "#smtpd_tls_cert_file" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_tls_cert_file =./smtpd_tls_cert_file = /etc/ssl/certs/$CERT_FILE/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_cert_file"; exit 1; }
    else
        echo "smtpd_tls_cert_file = /etc/ssl/certs/$CERT_FILE" >> "$POSTFIX_MAIN"
    fi
    #7smtpd_tls_key_file
    if grep -q "#smtpd_tls_key_file" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_tls_key_file =./smtpd_tls_key_file = /etc/ssl/private/$KEY_FILE/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_key_file"; exit 1; }
    else
        echo "smtpd_tls_key_file = /etc/ssl/private/$KEY_FILE" >> "$POSTFIX_MAIN"
    fi
    #8smtpd_tls_security_level
    if grep -q "#smtpd_tls_security_level" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_tls_security_level =./smtpd_tls_security_level = may/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_security_level"; exit 1; }
    else
        echo "smtpd_tls_security_level = may" >> "$POSTFIX_MAIN"
    fi
    #9smtpd_use_tls
    if grep -q "#smtpd_use_tls" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_use_tls =./smtpd_use_tls = yes/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_use_tls"; exit 1; }
    else
        echo "smtpd_use_tls = yes" >> "$POSTFIX_MAIN"
    fi
    #10smtpd_sasl_auth_enable
    if grep -q "#smtpd_sasl_auth_enable" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_sasl_auth_enable =./smtpd_sasl_auth_enable = yes/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_auth_enable"; exit 1; }
    else
        echo "smtpd_sasl_auth_enable = yes" >> "$POSTFIX_MAIN"
    fi
    #11smtpd_sasl_type
    if grep -q "#smtpd_sasl_type" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_sasl_type =./smtpd_sasl_type = dovecot/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_type"; exit 1; }
    else
        echo "smtpd_sasl_type = dovecot" >> "$POSTFIX_MAIN"
    fi
    #12smtpd_sasl_path
    if grep -q "#smtpd_sasl_path" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_sasl_path =./smtpd_sasl_path = private/auth/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_path"; exit 1; }
    else
        echo "smtpd_sasl_path = private/auth" >> "$POSTFIX_MAIN"
    fi
    #13smtpd_sasl_local_domain
    if grep -q "#smtpd_sasl_local_domain" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_sasl_local_domain =./smtpd_sasl_local_domain = /etc/postfix/$MY_DOMAIN" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_local_domain"; exit 1; }
    else
        echo "smtpd_sasl_local_domain = /etc/postfix/$MY_DOMAIN" >> "$POSTFIX_MAIN"
    fi
    #14smtpd_sasl_security_options
    if grep -q "#smtpd_sasl_security_options" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_sasl_security_options =./smtpd_sasl_security_options = noanonymous" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': smtpd_sasl_security_options"; exit 1; }
    else
        echo "smtpd_sasl_security_options = noanonymous" >> "$POSTFIX_MAIN"
    fi
    #15broken_sasl_auth_clients
    if grep -q "#broken_sasl_auth_clients" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#broken_sasl_auth_clients =./broken_sasl_auth_clients = yes/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': broken_sasl_auth_clients"; exit 1; }
    else
        echo "broken_sasl_auth_clients = yes" >> "$POSTFIX_MAIN"
    fi
    #16mydomain
    if grep -q "#mydomain" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#mydomain =./mydomain = avilesworks.com/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': mydomain"; exit 1; }
    else
        echo "mydomain = avilesworks.com" >> "$POSTFIX_MAIN"
    fi
    #17myhostname
    if grep -q "#myhostname" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#myhostname =./myhostname = mail.avilesworks.com/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un provlema al configurar el archivo '$POSTFIX_MAIN': myhostname"; exit 1; }
    else
        echo "myhostname = mail.avilesworks.com" >> "$POSTFIX_MAIN"
    fi
    #18mydestination
    if grep -q "#mydestination" "$POSTFIX_MAIN"; then
            sudo sed -i "s/^#mydestination =./mydestination = localhost.localdomain, localhost/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un provlema al configurar el archivo '$POSTFIX_MAIN': mydestination"; exit 1; }
        else
            echo "mydestination = localhost.localdomain, localhost" >> "$POSTFIX_MAIN"
    fi
    #19myorigin
    if grep -q "#myorigin" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#myorigin =.*/myorigin = /etc/mailname/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': myorigin"; exit 1; }
    else
        echo "myorigin = /etc/mailname" >> "$POSTFIX_MAIN"
    fi
    #20compatibility_level
    if grep -q "#compatibility_level" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#compatibility_level =./compatibility_level = 3/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un problema al configurar el archivo '$POSTFIX_MAIN': compatibility_level"; exit 1; }
    else
        echo "compatibility_level = 3" >> "$POSTFIX_MAIN"
    fi
    #21smtpd_tls_loglevel
    if grep -q "#smtpd_tls_loglevel" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_tls_loglevel =./smtpd_tls_loglevel = 1/" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un provlema al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_loglevel"; exit 1; }
    else
        echo "smtpd_tls_loglevel = 1" >> "$POSTFIX_MAIN"
    fi
    #22smtpd_tls_received_header
    if grep -q "#smtpd_tls_received_header" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_tls_received_header =./smtpd_tls_received_header = yes" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un provlema al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_received_header"; exit 1; }
    else
        echo "smtpd_tls_received_header = yes" >> "$POSTFIX_MAIN"
    fi
    #23smtpd_tls_session_cache_timeout
    if grep -q "#smtpd_tls_session_cache_timeout" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#smtpd_tls_session_cache_timeout =./smtpd_tls_session_cache_timeout = 3600s" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un provlema al configurar el archivo '$POSTFIX_MAIN': smtpd_tls_session_cache_timeout"; exit 1; }
    else
        echo "smtpd_tls_session_cache_timeout = 3600s" >> "$POSTFIX_MAIN"
    fi
    #24tls_random_source
    if grep -q "#tls_random_source" "$POSTFIX_MAIN"; then
        sudo sed -i "s/^#tls_random_source =./tls_random_source = dev:/dev/urandom" "$POSTFIX_MAIN" || { echo "ERROR: Hubo un provlema al configurar el archivo '$POSTFIX_MAIN': tls_random_source"; exit 1; }
    else
        echo "tls_random_source = dev:/dev/urandom" >> "$POSTFIX_MAIN"
    fi
      # check config
    if sudo postfix check; then
        echo "El archivo '$POSTFIX_MAIN' ha sido configurado exitosamente."
    else
        echo "Falla al configurar '$POSTFIX_MAIN'"
    fi
}
# Función para leer la lista de direcciones de correo
function read_accounts() {
    # leer la lista de direcciones de correo
    echo "Leyendo la lista de dominios '$ACCOUNTS_PATH'..."
    while IFS="," read -r username nombre apellido email alias password; do
        echo "Usario: $username"
        echo "Correo principal: $email"
        echo "Correo secundario: $alias"
        echo "Contraseña: ${password:0:3}*********"
        #sudo adduser "$alias"
        #sudo mkmailbox "$alias"
        # Escribiendo datos 
        echo "${alias} ${email}" | grep -v '^$' >> "$POSTFIX_PATH/virtual"
        echo "Los datos del usuario '$username' han sido registrados en '$POSTFIX_PATH/virtual'"
        echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    done < <(grep -v '^$' "$ACCOUNTS_PATH")
    echo "Todas las cuentas de correo han sido copiadas."
}
# Función para reiniciar el servicio de Postfix
function restart_postfix() {
    # reiniciar el servicio de Postfix
  echo "Restarting Postfix service..."
  sudo service postfix restart
  echo "Postfix service restarted successfully."
  sudo service postfix status
  tail -F /var/log/mail.log -f
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
  restart_postfix
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
postfix_config
