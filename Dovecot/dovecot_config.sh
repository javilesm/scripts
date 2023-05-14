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
# Función para crear una copia de seguridad del archivo de configuración
function backup_conf() {
    # Verificar si el archivo de configuración existe antes de hacer una copia de seguridad
    if [ -f "$CONFIG_PATH" ]; then
        echo "Creando copia de seguridad del archivo '$CONFIG_FILE' ..."
        sudo cp "$CONFIG_PATH" "$CONFIG_PATH".bak 
        echo "Copia de seguridad creada en '$CONFIG_PATH.bak'..."
    else
        echo "ERROR: El archivo de configuración '$CONFIG_FILE' no existe. No se puede crear una copia de seguridad."
    fi
}

# Función para habilitar los protocolos
function enable_protocols() {
    # Buscar la línea que contiene la cadena "!include_try /usr/share/dovecot/protocols.d/*.protocol" y eliminar el carácter '#'
    sudo sed -i "/!include_try \/usr\/share\/dovecot\/protocols.d\/\*\.protocol/s/^#//g" $CONFIG_PATH
}

# Función para configurar la autenticación
function configure_authentication() {
    # Buscar la línea que contiene la cadena "!include auth-system.conf.ext" y eliminar el carácter '#'
    sudo sed -i "/!include auth-system.conf.ext/s/^#//g" $CONFIG_PATH
}

# Función para editar la configuración de autenticación
function edit_auth_config() {
    local edit_auth_config_file="/etc/dovecot/conf.d/10-auth.conf"
    # Editar los valores de disable_plaintext_auth y auth_mechanisms
    sudo sed -i "/disable_plaintext_auth/c\disable_plaintext_auth = no" $edit_auth_config_file
    sudo sed -i "/auth_mechanisms/c\auth_mechanisms = plain login" $edit_auth_config_file
}

# Función para editar la dirección IP de la interfaz
function listen_interface() {
    # Buscar la línea que contiene la cadena "listen =" y reemplazar la dirección IP existente con la nueva dirección IP
    sudo sed -i "/protocols = /c\protocols = imap pop3 imaps pop3s" $CONFIG_PATH
    sudo sed -i "/listen = /c\listen = *" $CONFIG_PATH
}

# Función para editar la ubicacion de las bandejas de correo
function configure_mailbox_location() {
    local configure_mailbox_location_file="/etc/dovecot/conf.d/10-mail.conf"
    # Editar el valor de mail_location
    sudo sed -i "/mail_location/c\mail_location = maildir:$MAILBOX_PATH/Maildir" $configure_mailbox_location_file
}
# Función para establecer el usuario y el grupo en la sección unix_listener 
function setup_user() {
    local setup_user_file="/etc/dovecot/conf.d/10-master.conf"
    # Establecer el usuario y el grupo en la sección unix_listener en el archivo 10-master.conf
    sudo sed -i "/unix_listener \/var\/spool\/postfix\/private\/auth {/,+2 s/user = .*/user = $POSTFIX_USER/" $setup_user_file
    sudo sed -i "/unix_listener \/var\/spool\/postfix\/private\/auth {/,+2 s/group = .*/group = $POSTFIX_GROUP/" $setup_user_file
}
# Función para habilitar encriptacion SSL
function enable_ssl() {
    local enable_ssl_file="/etc/dovecot/conf.d/10-ssl.conf"
    sudo sed -i "/^ssl =/c\ssl = yes" $enable_ssl_file
    sudo sed -i "/^ssl_cert =/c\ssl_cert = <\/etc\/ssl\/certs\/$CERTIFICADO" $enable_ssl_file
    sudo sed -i "/^ssl_key =/c\ssl_key = <\/etc\/ssl\/private\/$CLAVE_PRIVADA" $enable_ssl_file
}
# Función para inciar y habilitar el servicio de Dovecot
function start_and_enable() {
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
    listen_interface
    configure_mailbox_location
    setup_user
    enable_ssl
    start_and_enable
    echo "***************ALL DONE***************"
}
# Llamar a la funcion principal
dovecot_config
