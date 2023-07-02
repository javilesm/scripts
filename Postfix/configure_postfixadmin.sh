#!/bin/bash
# configure_postfixadmin.sh
# Variables
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
USERS_FILE="$PARENT_DIR/MySQL/mysql_users.csv"
WEB_DIR="/var/www/samava-cloud/postfixadmin"
CONFIG_FILE="$WEB_DIR/config.local.php"

# Función para descargar PostfixAdmin desde GitHub
function wget_postfixadmin() {
    cd "$CURRENT_DIR"
    # Descargar y extraer PostfixAdmin desde GitHub
    echo "Descargando PostfixAdmin desde GitHub..."
    if sudo wget -O postfixadmin.tgz https://github.com/postfixadmin/postfixadmin/archive/postfixadmin-3.3.10.tar.gz; then
        # Extraer archivo comprimido
        echo "Extrayendo archivo comprimido..."
        if sudo tar -xvzf "postfixadmin.tgz"; then
            echo "PostfixAdmin descargado y extraído correctamente."
        else
            echo "Error al extraer el archivo comprimido de PostfixAdmin. Saliendo..."
            exit 1
        fi
    else
        echo "Error al descargar PostfixAdmin desde GitHub. Saliendo..."
        exit 1
    fi
}
# Función para mover directorio
function move_dir() {
    sudo rm postfixadmin.tgz
    sudo mv $CURRENT_DIR/postfixadmin-postfixadmin-3.3.10 "$WEB_DIR"
    sudo chown -R www-data:www-data "$WEB_DIR"
} 
# Función para crear el archivo de configuracion
function create_config() {
    # crear el archivo de configuracion
    echo "Creando el archivo de configuracion..."
    sudo touch "$CONFIG_FILE"
}
# Función para leer la lista de usuarios MySQL
function read_users_file() {
    echo "Leyendo la lista de usuarios MySQL..."
    # Buscar al usuario 'postfixadmin' en el archivo mysql_users.csv y mostrar sus atributos
    local username="postfixadmin"
    while IFS="," read -r u p h d priv; do
        if [ "$u" == "$username" ]; then
            echo "username: $u"
            echo "password: $p"
            echo "host: $h"
            echo "databases: $d"
            echo "privileges: $priv"
            break
        fi
    done < "$USERS_FILE"
}
# Función para escribir el contenido en el archivo de configuración
function write_config_file() {
    echo "<?php
\$CONF['configured'] = true;

\$CONF['database_type'] = 'mysqli';
\$CONF['database_host'] = '$h';
\$CONF['database_user'] = '$u';
\$CONF['database_password'] = '$p';
\$CONF['database_name'] = '$d';

\$CONF['default_aliases'] = array (
 'abuse' => 'abuse@avilesworks.com',
 'hostmaster' => 'hostmaster@avilesworks.com',
 'postmaster' => 'postmaster@avilesworks.com',
 'webmaster' => 'webmaster@avilesworks.com'
);

\$CONF['fetchmail'] = 'NO';
\$CONF['show_footer_text'] = 'NO';

\$CONF['quota'] = 'YES';
\$CONF['domain_quota'] = 'YES';
\$CONF['quota_multiplier'] = '1024000';
\$CONF['used_quotas'] = 'YES';
\$CONF['new_quota_table'] = 'YES';

\$CONF['aliases'] = '0';
\$CONF['mailboxes'] = '0';
\$CONF['maxquota'] = '0';
\$CONF['domain_quota_default'] = '0';
?>" > "$CONFIG_FILE"

    echo "Archivo de configuración escrito correctamente."
}
function mkdir_templates_c() {
    sudo mkdir -p "$WEB_DIR/templates_c"
    sudo chown -R www-data "$WEB_DIR/templates_c"
}
#  create the schema for the PostfixAdmin database 
function create_schema() {
    #  create the schema for the PostfixAdmin database 
    echo "Creando esquema para la base de datos PostfixAdmin..."
    sudo -u "www-data" php "$WEB_DIR/public/upgrade.php"
}
# Función principal
function configure_postfixadmin() {
    echo "**********CONFIGURE POSTFIXADMIN***********"
    get_latest_version
    wget_postfixadmin
    move_dir
    create_config
    read_users_file
    write_config_file
    mkdir_templates_c
    create_schema
    echo "**************ALL DONE***************"
}
# Llamar a la función principal
configure_postfixadmin
