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
mailbox_file_original="$DOVECOT_PATH/conf.d/10-mail.conf"
mailbox_file_fake="$CURRENT_DIR/10-mail.conf"
master_file_original="$DOVECOT_PATH/conf.d/10-master.conf"
master_file_fake="$CURRENT_DIR/10-master.conf"
imap_file_original="$DOVECOT_PATH/conf.d/20-imap.conf"
imap_file_fake="$CURRENT_DIR/20-imap.conf"
pop3_file_original="$DOVECOT_PATH/conf.d/20-pop3.conf"
pop3_file_fake="$CURRENT_DIR/20-pop3.conf"
auth_file_original="$DOVECOT_PATH/conf.d/10-auth.conf"
auth_file_fake="$CURRENT_DIR/10-auth.conf"
ssl_file_original="$DOVECOT_PATH/conf.d/10-ssl.conf"
ssl_file_fake="$CURRENT_DIR/10-ssl.conf"
dovecot_sql_conf_file="$DOVECOT_PATH/dovecot-sql.conf.ext"
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

    if [ -f "$mailbox_file_original" ]; then
        echo "Creando copia de seguridad del archivo '$mailbox_file_original' ..."
        sudo cp "$mailbox_file_original" "$mailbox_file_original".bak 
        echo "Copia de seguridad creada en '$mailbox_file_original.bak'..."
    else
        echo "ERROR: El archivo de configuración '$mailbox_file_original' no existe. No se puede crear una copia de seguridad."
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
    
     if [ -f "$ssl_file_original" ]; then
        echo "Creando copia de seguridad del archivo '$ssl_file_original' ..."
        sudo cp "$ssl_file_original" "$ssl_file_original".bak 
        echo "Copia de seguridad creada en '$ssl_file_original.bak'..."
    else
        echo "ERROR: El archivo de configuración '$ssl_file_original' no existe. No se puede crear una copia de seguridad."
    fi
}
# Función para reemplazar el archivo 10-master.conf
function change_master_file() {
    # reemplazar el archivo 10-master.conf
    echo "Reemplazando el archivo '$master_file_original' ..."
    if [ -f "$master_file_original" ]; then
        sudo mv "$master_file_fake" "$master_file_original"
        echo "El archivo '$master_file_original' fue reemplazado por '$master_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$master_file_original' no existe. No se puede reemplazar."
    fi
}
# Función para reemplazar el archivo 20-imap.conf
function change_imap_file() {
    # reemplazar el archivo 20-imap.conf
    echo "Reemplazando el archivo '$imap_file_original' ..."
    if [ -f "$imap_file_original" ]; then
        sudo mv "$imap_file_fake" "$imap_file_original"
        echo "El archivo '$imap_file_original' fue reemplazado por '$imap_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$imap_file_original' no existe. No se puede reemplazar."
    fi
}
# Función para reemplazar el archivo 20-pop3.conf
function change_pop3_file() {
    # reemplazar el archivo 20-pop3.conf
    echo "Reemplazando el archivo '$pop3_file_original' ..."
    if [ -f "$pop3_file_original" ]; then
        sudo mv "$pop3_file_fake" "$pop3_file_original"
        echo "El archivo '$pop3_file_original' fue reemplazado por '$pop3_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$pop3_file_original' no existe. No se puede reemplazar."
    fi
}
# Función para reemplazar el archivo 10-auth.conf
function change_auth_file() {
    # reemplazar el archivo 10-auth.conf
    echo "Reemplazando el archivo '$auth_file_original' ..."
    if [ -f "$auth_file_original" ]; then
        sudo mv "$auth_file_fake" "$auth_file_original"
        echo "El archivo '$auth_file_original' fue reemplazado por '$auth_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$auth_file_original' no existe. No se puede reemplazar."
    fi
}
# Función para reemplazar el archivo 10-ssl.conf
function change_ssl_file() {
    # reemplazar el archivo 10-ssl.conf
    echo "Reemplazando el archivo '$ssl_file_original' ..."
    if [ -f "$ssl_file_original" ]; then
        sudo mv "$ssl_file_fake" "$ssl_file_original"
        echo "El archivo '$ssl_file_original' fue reemplazado por '$ssl_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$ssl_file_original' no existe. No se puede reemplazar."
    fi
}
# Función para reemplazar el archivo 10-mail.conf
function change_mail_file() {
    # reemplazar el archivo 10-mail.conf
    echo "Reemplazando el archivo '$mailbox_file_original' ..."
    if [ -f "$mailbox_file_original" ]; then
        sudo mv "$mailbox_file_fake" "$mailbox_file_original"
        echo "El archivo '$mailbox_file_original' fue reemplazado por '$mailbox_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$mailbox_file_original' no existe. No se puede reemplazar."
    fi
}
# Función para habilitar los protocolos
function enable_protocols() {
    # habilitar los protocolos
    echo "Habilitando los protocolos..."
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
    #mail_location
    if grep -q "#mail_location =" "$CONFIG_PATH"; then
        sudo sed -i "s|^#mail_location =.*|mail_location = maildir:~/Maildir|" "$CONFIG_PATH" || { echo "ERROR: Hubo un problema al configurar el archivo '$CONFIG_PATH': #mail_location"; exit 1; }
    elif grep -q "mail_location =" "$CONFIG_PATH"; then
        sudo sed -i "s|^mail_location =.*|mail_location = maildir:~/Maildir|" "$CONFIG_PATH" || { echo "ERROR: Hubo un problema al configurar el archivo '$CONFIG_PATH': mail_location"; exit 1; }
    else
         echo "mail_location = maildir:~/Maildir" >> "$CONFIG_PATH"
    fi
}
# Función para editar la configuración de disable_plaintext_auth 
function edit_auth_config() {
    # editar la configuración de disable_plaintext_auth
    echo "Editando la configuración de disable_plaintext_auth..."
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
# Función para editar el archivo 'dovecot-sql-conf_file'
function edit_dovecot-sql-conf_file() {
    # editar el archivo 'dovecot-sql-conf_file'
    echo "Editando el archivo '$dovecot_sql_conf_file'..."
    #driver
    if grep -q "#driver" "$dovecot_sql_conf_file"; then
        sudo sed -i "s|^#driver =.*|driver = pgsql|" "$dovecot_sql_conf_file" || { echo "ERROR: Hubo un problema al configurar el archivo '$auth_config_file': #driver"; exit 1; }
    elif grep -q "driver" "$dovecot_sql_conf_file"; then
        sudo sed -i  "s|^driver =.*|driver = pgsql|" "$dovecot_sql_conf_file" || { echo "ERROR: Hubo un problema al configurar el archivo '$auth_config_file': driver"; exit 1; }
    else
         echo "driver = pgsql" >> "$dovecot_sql_conf_file"
    fi
    # parámetros
    sed -i "$a\connect = host=localhost dbname=postfix user=postfix_user password=postfix2023" "$dovecot_sql_conf_file"
    sed -i "$a\default_pass_scheme = SHA512-CRYPT" "$dovecot_sql_conf_file"
    sed -i "$a\password_query = SELECT username, password FROM users WHERE username = '%u';" "$dovecot_sql_conf_file"
    sed -i "$a\user_query = SELECT '/home/' || maildir AS home, 'maildir:/home/' || maildir AS mail, 1001 AS uid, 1001 AS gid FROM users WHERE username = '%u';" "$dovecot_sql_conf_file"
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
    change_master_file
    change_imap_file
    change_pop3_file
    change_auth_file
    change_ssl_file
    change_mail_file
    enable_protocols
    edit_auth_config
    configure_mailbox_location
    edit_dovecot-sql-conf_file
    start_and_enable
    echo "***************ALL DONE***************"
}
# Llamar a la funcion principal
dovecot_config
