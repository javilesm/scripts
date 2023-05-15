#!/bin/bash
# dovecot_config.sh
# Variables
CONFIG_FILE="dovecot.conf"
DOVECOT_PATH="/etc/dovecot"
CONFIG_PATH="$DOVECOT_PATH/$CONFIG_FILE"
USERS_FILE="users.csv"
INTERFACE_IP="*"
MAILBOX_PATH=$HOME
POSTFIX_USER="postfix"
POSTFIX_GROUP="postfix"
CERTIFICADO="ssl-cert-snakeoil.pem" # default self-signed certificate that comes with Ubuntu
CLAVE_PRIVADA="ssl-cert-snakeoil.key"
auth_config_file="$DOVECOT_PATH/conf.d/10-auth.conf"
mailbox_location_file="$DOVECOT_PATH/conf.d/10-mail.conf"
# Función para crear una copia de seguridad del archivo de configuración
function backup_conf() {
    echo "Creando una copia de seguridad del archivo de configuración..."
    # Verificar si el archivo de configuración existe antes de hacer una copia de seguridad
    if [ -f "$CONFIG_PATH" ]; then
        echo "Creando copia de seguridad del archivo '$CONFIG_FILE' ..."
        sudo cp "$CONFIG_PATH" "$CONFIG_PATH".bak 
        echo "Copia de seguridad creada en '$CONFIG_PATH.bak'..."
    else
        echo "ERROR: El archivo de configuración '$CONFIG_FILE' no existe. No se puede crear una copia de seguridad."
    fi

    if [ -f "$auth_config_file" ]; then
        echo "Creando copia de seguridad del archivo '$auth_config_file' ..."
        sudo cp "$auth_config_file" "$auth_config_file".bak 
        echo "Copia de seguridad creada en '$auth_config_file.bak'..."
    else
        echo "ERROR: El archivo de configuración '$auth_config_file' no existe. No se puede crear una copia de seguridad."
    fi

    if [ -f "$mailbox_location_file" ]; then
        echo "Creando copia de seguridad del archivo '$mailbox_location_file' ..."
        sudo cp "$mailbox_location_file" "$mailbox_location_file".bak 
        echo "Copia de seguridad creada en '$mailbox_location_file.bak'..."
    else
        echo "ERROR: El archivo de configuración '$mailbox_location_file' no existe. No se puede crear una copia de seguridad."
    fi
}

# Función para habilitar los protocolos
function enable_protocols() {
    echo "Habilitando los protocolos..."
    # Buscar la línea que contiene la cadena "!include_try /usr/share/dovecot/protocols.d/*.protocol" y eliminar el carácter '#'
    if grep -q "#!include_try /usr/share/dovecot/protocols.d/*.protocol" "$CONFIG_PATH"; then
        sudo sed -i "s~^#!include_try /usr/share/dovecot/protocols.d/*.protocol~#!include_try /usr/share/dovecot/protocols.d/*.protocol~g" "$CONFIG_PATH"
    elif grep -q "!include_try /usr/share/dovecot/protocols.d/*.protocol" "$CONFIG_PATH"; then
         sudo sed -i "s~^!include_try /usr/share/dovecot/protocols.d/*.protocol~!include_try /usr/share/dovecot/protocols.d/*.protocol~g" "$CONFIG_PATH"
    else
         echo "!include_try /usr/share/dovecot/protocols.d/*.protocol" >> "$CONFIG_PATH"
    fi
}

# Función para configurar la autenticación
function configure_authentication() {
    echo "Configurando la autenticación..."
    # Buscar la línea que contiene la cadena "!include auth-system.conf.ext" y eliminar el carácter '#'
    if grep -q "#!include auth-system.conf.ext" "$CONFIG_PATH"; then
        sudo sed -i "s~^#!include auth-system.conf.ext =.*/!include /etc/dovecot/conf.d/auth-system.conf.ext" "$CONFIG_PATH"
    elif grep -q "!include auth-system.conf.ext" "$CONFIG_PATH"; then
        sudo sed -i "s~^!include auth-system.conf.ext =.*/!include /etc/dovecot/conf.d/auth-system.conf.ext" "$CONFIG_PATH"
    else
         echo "!include /etc/dovecot/conf.d/auth-system.conf.ext" >> "$CONFIG_PATH"
    fi
}

# Función para editar la configuración de disable_plaintext_auth 
function edit_auth_config() {
    echo "Editando la configuración de disable_plaintext_auth..."
    # Editar los valores de disable_plaintext_auth
    if grep -q "#disable_plaintext_auth" "$auth_config_file"; then
        sudo sed -i "s/^#disable_plaintext_auth =.*/disable_plaintext_auth = no/" "$auth_config_file"
    elif grep -q "disable_plaintext_auth" "$auth_config_file"; then
        sudo sed -i "s/^disable_plaintext_auth =.*/disable_plaintext_auth = no/" "$auth_config_file"
    else
         echo "disable_plaintext_auth = no" >> "$auth_config_file"
    fi

}

# Función para editar la configuración de auth_mechanisms
function edit_auth_mechanisms() {
    echo "Editando la configuración de auth_mechanisms..."
    # Editar los valores de auth_mechanisms
    if grep -q "#auth_mechanisms" "$auth_config_file"; then
        sudo sed -i "s/^#auth_mechanisms =.*/auth_mechanisms = plain login/" "$auth_config_file"
    elif grep -q "auth_mechanisms" "$auth_config_file"; then
        sudo sed -i  "s/^auth_mechanisms =.*/auth_mechanisms = plain login/" "$auth_config_file"
    else
         echo "auth_mechanisms = plain login" >> "$auth_config_file"
    fi
}

# Función para editar la dirección IP de la interfaz
function listen_interface() {
    # Buscar la línea que contiene la cadena "listen =" y reemplazar la dirección IP existente con la nueva dirección IP
    echo "Buscando la línea que contiene la cadena "listen =" y reemplazar la dirección IP existente con la nueva dirección IP..."
    if grep -q "#protocols" "$CONFIG_PATH"; then
        sudo sed -i "s/^#protocols =./protocols = imap pop3 imaps pop3s" "$CONFIG_PATH"
    elif grep -q "protocols" "$CONFIG_PATH"; then
        sudo sed -i "s/^protocols =./protocols = imap pop3 imaps pop3s" "$CONFIG_PATH"
    else
         echo "protocols = imap pop3 imaps pop3s" >> "$CONFIG_PATH"
    fi
    # editar la dirección IP de la interfaz
    echo "Editando la dirección IP de la interfaz..."
    if grep -q "#listen" "$CONFIG_PATH"; then
        sudo sed -i "s/^#listen =./listen = */" "$CONFIG_PATH"
    elif grep -q "listen" "$CONFIG_PATH"; then
        sudo sed -i "s/^listen =./listen = */" "$CONFIG_PATH"
    else
         echo "listen = *" >> "$CONFIG_PATH"
    fi
}

# Función para editar la ubicacion de las bandejas de correo
function configure_mailbox_location() {
    # Editar el valor de mail_location
    echo "Editando la ubicacion de las bandejas de correo..."
    if grep -q "#mail_location" "$mailbox_location_file"; then
        sudo sed -i "s/^#mail_location =./mail_location = maildir:$MAILBOX_PATH/Maildir" "$mailbox_location_file"
    elif grep -q "mail_location" "$mailbox_location_file"; then
        sudo sed -i "s/^mail_location =./mail_location = maildir:$MAILBOX_PATH/Maildir" "$mailbox_location_file"
    else
         echo "mail_location = maildir:$MAILBOX_PATH/Maildir" >> "$mailbox_location_file"
    fi
}

# Función para habilitar encriptacion SSL
function enable_ssl() {
    echo "Habilitando encriptacion SSL..."
    local enable_ssl_file="/etc/dovecot/conf.d/10-ssl.conf"
    sudo sed -i "/^ssl =/c\ssl = yes" $enable_ssl_file
    sudo sed -i "/^ssl_cert =/c\ssl_cert = \/etc\/ssl\/certs\/$CERTIFICADO" $enable_ssl_file
    sudo sed -i "/^ssl_key =/c\ssl_key = \/etc\/ssl\/private\/$CLAVE_PRIVADA" $enable_ssl_file
}

# Función para iniciar y habilitar el servicio de Dovecot
function start_and_enable() {
    # iniciar y habilitar el servicio de Dovecot
    echo "Iniciando y habilitar el servicio de Dovecot..."
    sudo service dovecot start
    if [ $? -eq 0 ]; then
        echo "El servicio de Dovecot se inició correctamente."
        if systemctl is-active --quiet dovecot; then
            echo "El servicio de Dovecot está en ejecución."
        else
            echo "ERROR: El servicio de Dovecot no se está ejecutando."
        fi
    else
        echo "ERROR: No se pudo iniciar el servicio de Dovecot."
    fi
}
# Función principal
function dovecot_config() {
    echo "***************DOVECOT CONFIGURATOR***************"
    backup_conf
    enable_protocols
    configure_authentication
    edit_auth_config
    edit_auth_mechanisms
    listen_interface
    #configure_mailbox_location #se deja la config defaul por problemas
    enable_ssl
    start_and_enable
    echo "***************ALL DONE***************"
}
# Llamar a la funcion principal
dovecot_config
