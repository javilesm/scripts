#!/bin/bash
# dovecot_config.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
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
master_file_original="$DOVECOT_PATH/conf.d/10-master.conf"
master_file_fake="$CURRENT_DIR/10-master.conf"
imap_file_original="$DOVECOT_PATH/conf.d/20-imap.conf"
imap_file_fake="$CURRENT_DIR/20-imap.conf"
pop3_file_original="$DOVECOT_PATH/conf.d/20-pop3.conf"
pop3_file_fake="$CURRENT_DIR/20-pop3.conf"
auth_file_original="$DOVECOT_PATH/conf.d/10-auth.conf"
auth_file_fake="$CURRENT_DIR/10-auth.conf"
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
    
    if [ -f "$imap_file_original" ]; then
        echo "Creando copia de seguridad del archivo '$imap_file_original' ..."
        sudo cp "$imap_file_original" "$imap_file_original".bak 
        echo "Copia de seguridad creada en '$imap_file_original.bak'..."
    else
        echo "ERROR: El archivo de configuración '$imap_file_original' no existe. No se puede crear una copia de seguridad."
    fi
    
    if [ -f "$master_file_original" ]; then
        echo "Creando copia de seguridad del archivo '$master_file_original' ..."
        sudo cp "$master_file_original" "$master_file_original".bak 
        echo "Copia de seguridad creada en '$master_file_original.bak'..."
    else
        echo "ERROR: El archivo de configuración '$master_file_original' no existe. No se puede crear una copia de seguridad."
    fi
    
    if [ -f "$pop3_file_original" ]; then
        echo "Creando copia de seguridad del archivo '$pop3_file_original' ..."
        sudo cp "$pop3_file_original" "$pop3_file_original".bak 
        echo "Copia de seguridad creada en '$pop3_file_original.bak'..."
    else
        echo "ERROR: El archivo de configuración '$pop3_file_original' no existe. No se puede crear una copia de seguridad."
    fi
    
        if [ -f "$auth_file_original" ]; then
        echo "Creando copia de seguridad del archivo '$auth_file_original' ..."
        sudo cp "$auth_file_original" "$auth_file_original".bak 
        echo "Copia de seguridad creada en '$auth_file_original.bak'..."
    else
        echo "ERROR: El archivo de configuración '$auth_file_original' no existe. No se puede crear una copia de seguridad."
    fi
}
# Función para reemplazar el archivo 10-master.conf
function change_master() {
    if [ -f "$master_file_original" ]; then
        # cambiar la proiedad del archivo 10-master.conf
        echo "Cambiando la propiedad del archivo '$master_file_original' ..."
        sudo chown $USER:$USER "$master_file_original"
        echo "La propiedad del archivo '$master_file_original' fue cambiada."
        # reemplazar el archivo 10-master.conf
        echo "Reemplazando el archivo '$master_file_original' ..."
        sudo cp "$master_file_fake" "$master_file_original"
        echo "El archivo '$master_file_original' fue reemplazado por '$master_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$master_file_original' no existe. No se puede reemplazar."
    fi
}
# Función para reemplazar el archivo 20-imap.conf
function change_imap() {
    if [ -f "$imap_file_original" ]; then
        # cambiar la proiedad del archivo 10-master.conf
        echo "Cambiando la propiedad del archivo '$imap_file_original' ..."
        sudo chown $USER:$USER "$imap_file_original"
        echo "La propiedad del archivo '$imap_file_original' fue cambiada."
        # reemplazar el archivo 10-master.conf
        echo "Reemplazando el archivo '$imap_file_original' ..."
        sudo cp "$imap_file_fake" "$imap_file_original"
        echo "El archivo '$imap_file_original' fue reemplazado por '$imap_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$imap_file_original' no existe. No se puede reemplazar."
    fi
}
# Función para reemplazar el archivo 20-pop3.conf
function change_pop3() {
    if [ -f "$pop3_file_original" ]; then
        # cambiar la proiedad del archivo 10-master.conf
        echo "Cambiando la propiedad del archivo '$pop3_file_original' ..."
        sudo chown $USER:$USER "$pop3_file_original"
        echo "La propiedad del archivo '$pop3_file_original' fue cambiada."
        # reemplazar el archivo 10-master.conf
        echo "Reemplazando el archivo '$pop3_file_original' ..."
        sudo cp "$pop3_file_fake" "$pop3_file_original"
        echo "El archivo '$pop3_file_original' fue reemplazado por '$pop3_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$pop3_file_original' no existe. No se puede reemplazar."
    fi
}
# Función para reemplazar el archivo 20-pop3.conf
function change_auth() {
    if [ -f "$auth_file_original" ]; then
        # cambiar la proiedad del archivo 10-master.conf
        echo "Cambiando la propiedad del archivo '$auth_file_original' ..."
        sudo chown $USER:$USER "$auth_file_original"
        echo "La propiedad del archivo '$auth_file_original' fue cambiada."
        # reemplazar el archivo 10-master.conf
        echo "Reemplazando el archivo '$auth_file_original' ..."
        sudo cp "$auth_file_fake" "$auth_file_original"
        echo "El archivo '$auth_file_original' fue reemplazado por '$auth_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$auth_file_original' no existe. No se puede reemplazar."
    fi
}
# Función para habilitar los protocolos
function enable_protocols() {
    #include_try
    if grep -q "#!include_try /usr/share/dovecot/protocols.d/*.protocol" "$CONFIG_PATH"; then
        sudo sed -i "s|^#!include_try /usr/share/dovecot/protocols.d/*.protocol|!include_try /usr/share/dovecot/protocols.d/*.protocol|" "$CONFIG_PATH" || { echo "ERROR: Hubo un problema al configurar el archivo '$CONFIG_PATH': !include_try"; exit 1; }
    else
         echo "!include_try /usr/share/dovecot/protocols.d/*.protocol" >> "$CONFIG_PATH"
    fi
    #!include auth-system.conf.ext
    if grep -q "#!include auth-system.conf.ext" "$CONFIG_PATH"; then
        sudo sed -i "s|^#!include auth-system.conf.ext =.*|!include /etc/dovecot/conf.d/auth-system.conf.ext|" "$CONFIG_PATH" || { echo "ERROR: Hubo un problema al configurar el archivo '$CONFIG_PATH': #!include auth-system.conf.ext"; exit 1; }
    elif grep -q "!include auth-system.conf.ext" "$CONFIG_PATH"; then
        sudo sed -i "s|^!include auth-system.conf.ext =.*|!include /etc/dovecot/conf.d/auth-system.conf.ext|" "$CONFIG_PATH" || { echo "ERROR: Hubo un problema al configurar el archivo '$CONFIG_PATH': !include auth-system.conf.ext"; exit 1; }
    else
         echo "!include /etc/dovecot/conf.d/auth-system.conf.ext" >> "$CONFIG_PATH"
    fi
    #protocols
    if grep -q "#protocols" "$CONFIG_PATH"; then
        sudo sed -i "s|^#protocols =.*|protocols = imap pop3 imaps pop3s|" "$CONFIG_PATH" || { echo "ERROR: Hubo un problema al configurar el archivo '$CONFIG_PATH': #protocols"; exit 1; }
    elif grep -q "protocols" "$CONFIG_PATH"; then
        sudo sed -i "s|^protocols =.*|protocols = imap pop3 imaps pop3s|" "$CONFIG_PATH" || { echo "ERROR: Hubo un problema al configurar el archivo '$CONFIG_PATH': protocols"; exit 1; }
    else
         echo "protocols = imap pop3 imaps pop3s" >> "$CONFIG_PATH"
    fi
    #listen
    if grep -q "#listen =" "$CONFIG_PATH"; then
        sudo sed -i "s|^#listen =.*|listen = *, ::|" "$CONFIG_PATH" || { echo "ERROR: Hubo un problema al configurar el archivo '$CONFIG_PATH': #listen"; exit 1; }
    elif grep -q "listen =" "$CONFIG_PATH"; then
        sudo sed -i "s|^listen =.*|listen = *, ::|" "$CONFIG_PATH" || { echo "ERROR: Hubo un problema al configurar el archivo '$CONFIG_PATH': listen"; exit 1; }
    else
         echo "listen = *, ::" >> "$CONFIG_PATH"
    fi
}
# Función para editar la configuración de disable_plaintext_auth 
function edit_auth_config() {
    #disable_plaintext_auth
    if grep -q "#disable_plaintext_auth" "$auth_config_file"; then
        sudo sed -i "s|^#disable_plaintext_auth =.*|disable_plaintext_auth = no|" "$auth_config_file" || { echo "ERROR: Hubo un problema al configurar el archivo '$auth_config_file': #disable_plaintext_auth"; exit 1; }
    elif grep -q "disable_plaintext_auth" "$auth_config_file"; then
        sudo sed -i "s|^disable_plaintext_auth =.*|disable_plaintext_auth = no|" "$auth_config_file" || { echo "ERROR: Hubo un problema al configurar el archivo '$auth_config_file': disable_plaintext_auth"; exit 1; }
    else
         echo "disable_plaintext_auth = no" >> "$auth_config_file"
    fi
    #auth_mechanisms
    if grep -q "#auth_mechanisms" "$auth_config_file"; then
        sudo sed -i "s|^#auth_mechanisms =.*|auth_mechanisms = plain login|" "$auth_config_file" || { echo "ERROR: Hubo un problema al configurar el archivo '$auth_config_file': #auth_mechanisms"; exit 1; }
    elif grep -q "auth_mechanisms" "$auth_config_file"; then
        sudo sed -i  "s|^auth_mechanisms =.*|auth_mechanisms = plain login|" "$auth_config_file" || { echo "ERROR: Hubo un problema al configurar el archivo '$auth_config_file': auth_mechanisms"; exit 1; }
    else
         echo "auth_mechanisms = plain login" >> "$auth_config_file"
    fi
}
# Función para editar la ubicacion de las bandejas de correo
function configure_mailbox_location() {
    #mail_location
    if grep -q "#mail_location" "$mailbox_location_file"; then
        sudo sed -i "s|^#mail_location =.*|mail_location = maildir:/var/mail/vhosts/%d/%n|" "$mailbox_location_file" || { echo "ERROR: Hubo un problema al configurar el archivo '$mailbox_location_file': #mail_location"; exit 1; }
    elif grep -q "mail_location" "$mailbox_location_file"; then
        sudo sed -i "s|^mail_location =.*|mail_location = maildir:/var/mail/vhosts/%d/%n|" "$mailbox_location_file" || { echo "ERROR: Hubo un problema al configurar el archivo '$mailbox_location_file': mail_location"; exit 1; }
    else
         echo "mail_location = maildir:/var/mail/vhosts/%d/%n" >> "$mailbox_location_file"
    fi
    #mail_privileged_group
    if grep -q "#mail_privileged_group" "$mailbox_location_file"; then
        sudo sed -i "s|^#mail_privileged_group =.*|mail_privileged_group = mail|" "$mailbox_location_file" || { echo "ERROR: Hubo un problema al configurar el archivo '$mailbox_location_file': #mail_privileged_group"; exit 1; }
    elif grep -q "mail_privileged_group" "$mailbox_location_file"; then
        sudo sed -i "s|^mail_privileged_group =.*|mail_privileged_group = mail|" "$mailbox_location_file" || { echo "ERROR: Hubo un problema al configurar el archivo '$mailbox_location_file': mail_privileged_group"; exit 1; }
    else
         echo "mail_privileged_group = mail" >> "$mailbox_location_file"
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
    change_master
    change_imap
    change_pop3
    change_auth
    enable_protocols
    edit_auth_config
    configure_mailbox_location
    enable_ssl
    start_and_enable
    echo "***************ALL DONE***************"
}
# Llamar a la funcion principal
dovecot_config
