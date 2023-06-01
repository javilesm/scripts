#!/bin/bash
# dovecot_config.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
AUTH_LDAP_FILE="auth_ldap_gen.sh"
AUTH_LDAP_PATH="$CURRENT_DIR/$AUTH_LDAP_FILE"
AUTH_FILE="auth_gen.sh"
AUTH_PATH="$CURRENT_DIR/$AUTH_FILE"
CONFIG_FILE="dovecot.conf"
DOVECOT_PATH="/etc/dovecot"
CONFIG_PATH="$DOVECOT_PATH/$CONFIG_FILE"
USERS_FILE="users.csv"
INTERFACE_IP="*"
DRIVER="ldap"
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
auth_ldap_orginal="$DOVECOT_PATH/auth-ldap.conf.ext"
auth_ldap_fake="$CURRENT_DIR/auth-ldap.conf.ext"
POSTFIX_ACCOUNTS_SCRIPT="postfix_accounts.sh"
POSTFIX_ACCOUNTS_PATH="$PARENT_DIR/Postfix/$POSTFIX_ACCOUNTS_SCRIPT"
LDAP_GROUPS_FILE="make_groups.sh"
LDAP_GROUPS_PATH="$PARENT_DIR/LDAP/$LDAP_GROUPS_FILE"
# Función para leer la variable GID desde el script '$POSTFIX_ACCOUNTS_PATH'
function read_GID() {
    # Leer la variable GID desde el script '$POSTFIX_ACCOUNTS_PATH'
    echo "Leyendo la variable GID desde el script '$POSTFIX_ACCOUNTS_PATH'..."
    # Verificar si el archivo existe
    if [ -f "$POSTFIX_ACCOUNTS_PATH" ]; then
        # Leer el archivo línea por línea
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Buscar la línea que define la variable GID
            if [[ "$line" =~ ^GID= ]]; then
                # Extraer el valor de la variable GID
                GID=$(echo "$line" | cut -d'=' -f2)
                export GID
                break
            fi
        done < "$POSTFIX_ACCOUNTS_PATH"
    else
        echo "El archivo '$POSTFIX_ACCOUNTS_PATH' no existe."
    fi
    echo "El valor de GID es: ${GID//\"/}"
}
# Función para leer la variable MAIL_DIR desde el script '$LDAP_GROUPS_PATH'
function read_MAIL_DIR() {
    # Leer la variable MAIL_DIR desde el script '$LDAP_GROUPS_PATH'
    echo "Leyendo la variable MAIL_DIR desde el script '$LDAP_GROUPS_PATH'..."
    # Verificar si el archivo existe
    if [ -f "$LDAP_GROUPS_PATH" ]; then
        # Leer el archivo línea por línea
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Buscar la línea que define la variable MAIL_DIR
            if [[ "$line" =~ ^MAIL_DIR= ]]; then
                # Extraer el valor de la variable MAIL_DIR
                MAIL_DIR=$(echo "$line" | cut -d'=' -f2)
                export MAIL_DIR
                break
            fi
        done < "$LDAP_GROUPS_PATH"
    else
        echo "El archivo '$LDAP_GROUPS_PATH' no existe."
    fi
    echo "El valor de MAIL_DIR es: ${MAIL_DIR//\"/}"
}
# Función para verificar si el archivo de configuración existe
function validate_script() {
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$AUTH_LDAP_PATH" ]; then
    echo "ERROR: El archivo de configuración '$AUTH_LDAP_FILE' no se puede encontrar en la ruta '$AUTH_LDAP_PATH'."
    exit 1
  fi
  echo "El archivo de configuración '$AUTH_LDAP_FILE' existe."
}
# Función para ejecutar el configurador de Postfix
function run_script() {
  echo "Ejecutar el configurador '$AUTH_LDAP_FILE'..."
    # Intentar ejecutar el archivo de configuración de Postfix
  if sudo bash "$AUTH_LDAP_PATH"; then
    echo "El archivo de configuración '$AUTH_LDAP_FILE' se ha ejecutado correctamente."
  else
    echo "ERROR: No se pudo ejecutar el archivo de configuración '$AUTH_LDAP_FILE'."
    exit 1
  fi
  echo "Configurador '$AUTH_LDAP_FILE' ejecutado."
}
# Función para ejecutar el configurador de Postfix
function run_auth_script() {
  echo "Ejecutar el configurador '$AUTH_FILE'..."
    # Intentar ejecutar el archivo de configuración de Postfix
  if sudo bash "$AUTH_PATH"; then
    echo "El archivo de configuración '$AUTH_FILE' se ha ejecutado correctamente."
  else
    echo "ERROR: No se pudo ejecutar el archivo de configuración '$AUTH_FILE'."
    exit 1
  fi
  echo "Configurador '$AUTH_FILE' ejecutado."
}
function edit_auth_file_fake() {
    # userdb {
    if grep -q "# userdb {" "$auth_file_fake"; then
        sudo sed -i "s|^# userdb {.*|userdb {\n    driver = static\n    args = uid=${GID//\"/} gid=${GID//\"/} home=${MAIL_DIR//\"/}/%d/%n  \n}|" "$auth_file_fake" || { echo "ERROR: Hubo un problema al configurar el archivo '$auth_file_fake': # userdb { }"; exit 1; }
    elif grep -q "userdb { }" "$auth_file_fake"; then
        sudo sed -i "s|^userdb {.*|userdb {\n    driver = static\n    args = uid=${GID//\"/} gid=${GID//\"/} home=${MAIL_DIR//\"/}/%d/%n  \n}|" "$auth_file_fake" || { echo "ERROR: Hubo un problema al configurar el archivo '$auth_file_fake': userdb { }"; exit 1; }
    else
         echo -e "userdb {\n    driver = static\n    args = uid=${GID//\"/} gid=${GID//\"/} home=${MAIL_DIR//\"/}/%d/%n  \n}" >> "$auth_file_fake"
    fi
}
# Función para crear una copia de seguridad del archivo de configuración
function backup_original_files() {
    echo "Creando una copia de seguridad de los archivos de configuración..."
    # Verificar si el archivo de configuración existe antes de hacer una copia de seguridad
    if [ -f "$CONFIG_PATH" ]; then
        echo "Creando copia de seguridad del archivo '$CONFIG_FILE' ..."
        sudo cp "$CONFIG_PATH" "$CONFIG_PATH".bak 
        echo "Copia de seguridad creada en '$CONFIG_PATH.bak'..."
    else
        echo "ERROR: El archivo de configuración '$CONFIG_FILE' no existe. No se puede crear una copia de seguridad."
    fi

    if [ -f "$auth_ldap_orginal" ]; then
        echo "Creando copia de seguridad del archivo '$auth_ldap_orginal' ..."
        sudo cp "$auth_ldap_orginal" "$auth_ldap_orginal".bak 
        echo "Copia de seguridad creada en '$auth_ldap_orginal.bak'..."
    else
        echo "ERROR: El archivo de configuración '$auth_ldap_orginal' no existe. No se puede crear una copia de seguridad."
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
# Función para reemplazar los archivos de configuración originales
function change_original_files() {
    # reemplazar los archivos de configuración originales
    echo "Reemplazando los archivos de configuración originales..."
    # reemplazar el archivo auth_ldap_orginal
    echo "Reemplazando el archivo '$auth_ldap_orginal' ..."
    if [ -f "$auth_ldap_orginal" ]; then
        sudo mv "$auth_ldap_fake" "$auth_ldap_orginal"
        echo "El archivo '$auth_ldap_orginal' fue reemplazado por '$auth_ldap_fake'"
    else
        echo "ERROR: El archivo de configuración '$master_file_original' no existe. No se puede reemplazar."
    fi
    # reemplazar el archivo 10-master.conf
    echo "Reemplazando el archivo '$master_file_original' ..."
    if [ -f "$master_file_original" ]; then
        sudo mv "$master_file_fake" "$master_file_original"
        echo "El archivo '$master_file_original' fue reemplazado por '$master_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$master_file_original' no existe. No se puede reemplazar."
    fi
    # reemplazar el archivo 20-imap.conf
    echo "Reemplazando el archivo '$imap_file_original' ..."
    if [ -f "$imap_file_original" ]; then
        sudo mv "$imap_file_fake" "$imap_file_original"
        echo "El archivo '$imap_file_original' fue reemplazado por '$imap_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$imap_file_original' no existe. No se puede reemplazar."
    fi
     # reemplazar el archivo 20-pop3.conf
    echo "Reemplazando el archivo '$pop3_file_original' ..."
    if [ -f "$pop3_file_original" ]; then
        sudo mv "$pop3_file_fake" "$pop3_file_original"
        echo "El archivo '$pop3_file_original' fue reemplazado por '$pop3_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$pop3_file_original' no existe. No se puede reemplazar."
    fi
    # reemplazar el archivo 10-auth.conf
    echo "Reemplazando el archivo '$auth_file_original' ..."
    if [ -f "$auth_file_original" ]; then
        sudo mv "$auth_file_fake" "$auth_file_original"
        echo "El archivo '$auth_file_original' fue reemplazado por '$auth_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$auth_file_original' no existe. No se puede reemplazar."
    fi
    # reemplazar el archivo 10-ssl.conf
    echo "Reemplazando el archivo '$ssl_file_original' ..."
    if [ -f "$ssl_file_original" ]; then
        sudo mv "$ssl_file_fake" "$ssl_file_original"
        echo "El archivo '$ssl_file_original' fue reemplazado por '$ssl_file_fake'"
    else
        echo "ERROR: El archivo de configuración '$ssl_file_original' no existe. No se puede reemplazar."
    fi
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
function edit_params() {
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
function edit_protocols() {
    # protocol imap { }
    if grep -q "# protocol imap {" "$CONFIG_PATH"; then
        sudo sed -i "s|^# protocol imap {.*|protocol imap {\n    auth = ${DRIVER//\"/}\n}|" "$CONFIG_PATH" || { echo "ERROR: Hubo un problema al configurar el archivo '$CONFIG_PATH': # protocol imap { }"; exit 1; }
    elif grep -q "protocol imap { }" "$CONFIG_PATH"; then
        sudo sed -i "s|^protocol imap {.*|protocol imap {\n    auth = ${DRIVER//\"/}\n}|" "$CONFIG_PATH" || { echo "ERROR: Hubo un problema al configurar el archivo '$CONFIG_PATH': protocol imap { }"; exit 1; }
    else
        echo -e "protocol imap {\n    auth = ${DRIVER//\"/}\n}" >> "$CONFIG_PATH"
    fi
    #protocol pop3
    if grep -q "# protocol pop3 {" "$CONFIG_PATH"; then
        sudo sed -i "s|^# protocol pop3 {.*|protocol pop3 {\n    auth = ${DRIVER//\"/}\n}|" "$CONFIG_PATH" || { echo "ERROR: Hubo un problema al configurar el archivo '$CONFIG_PATH': #protocol pop3 {}"; exit 1; }
    elif grep -q "protocol pop3 {" "$CONFIG_PATH"; then
        sudo sed -i "s|^protocol pop3 {.*|protocol pop3 {\n    auth = ${DRIVER//\"/}\n}|" "$CONFIG_PATH" || { echo "ERROR: Hubo un problema al configurar el archivo '$CONFIG_PATH': protocol pop3 {}"; exit 1; }
    else
        echo -e "protocol pop3 {\n    auth = ${DRIVER//\"/}\n}" >> "$CONFIG_PATH"
    fi
}
# Función para editar el archivo 'dovecot-sql-conf_file'
function edit_dovecot-sql-conf_file() {
    # editar el archivo 'dovecot-sql-conf_file'
    echo "Editando el archivo '$dovecot_sql_conf_file'..."
    if grep -q "#driver" "$dovecot_sql_conf_file"; then
        sudo sed -i "s|^#driver =.*|driver = ${DRIVER//\"/}|" "$dovecot_sql_conf_file" || { echo "ERROR: Hubo un problema al configurar el archivo '$dovecot_sql_conf_file': #driver"; exit 1; }
    elif grep -q "driver" "$dovecot_sql_conf_file"; then
        sudo sed -i  "s|^driver =.*|driver = ${DRIVER//\"/}|" "$dovecot_sql_conf_file" || { echo "ERROR: Hubo un problema al configurar el archivo '$dovecot_sql_conf_file': driver"; exit 1; }
    else
         echo "driver = ${DRIVER//\"/}" >> "$dovecot_sql_conf_file"
    fi
    # parámetros
    echo "Parametros.."
    echo "connect = host=localhost dbname=postfix user=postfix_user password=postfix2023" >> "$dovecot_sql_conf_file"
    echo "default_pass_scheme = SHA512-CRYPT" >> "$dovecot_sql_conf_file"
    echo "password_query = SELECT username, password FROM users WHERE username = '%u';" >> "$dovecot_sql_conf_file"
    echo "user_query = SELECT '${MAIL_DIR//\"/}' || maildir AS home, 'maildir:${MAIL_DIR//\"/}' || maildir AS mail, 1001 AS uid, ${GID//\"/} AS gid FROM users WHERE username = '%u';" >> "$dovecot_sql_conf_file"
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
function dovecot_config() {
    echo "***************DOVECOT CONFIGURATOR***************"
    read_GID
    read_MAIL_DIR
    validate_script
    run_script
    run_auth_script
    edit_auth_file_fake
    backup_original_files
    change_original_files
    edit_params
    #edit_protocols
    edit_dovecot-sql-conf_file
    start_and_enable
    restart_services
    echo "***************ALL DONE***************"
}
# Llamar a la funcion principal
dovecot_config
