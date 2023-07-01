#!/bin/bash
# configure_postfixadmin.sh
# Variables
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
USERS_FILE="$PARENT_DIR/MySQL/mysql_users.csv"
WEB_DIR="/var/www/samava-cloud/postfixadmin"
CONFIG_FILE="$WEB_DIR/config.local.php"
UID="www-data"
GID="www-data"
# Función para obtener la versión más reciente de PostfixAdmin desde Sourceforge
function get_latest_version() {
    echo "Obteniendo la versión más reciente de PostfixAdmin..."
    LATEST_VERSION=$(curl -s https://sourceforge.net/projects/postfixadmin/files/ | grep -oP "postfixadmin-${POSTFIXADMIN_VERSION}.\d+" | sort -V | tail -1)
    if [ -z "$LATEST_VERSION" ]; then
        echo "No se pudo obtener la versión más reciente de PostfixAdmin. Saliendo..."
        exit 1
    else
        echo "La versión más reciente de PostfixAdmin es: $LATEST_VERSION"
    fi
}
# Función para descargar PostfixAdmin desde Sourceforge
function wget_postfixadmin() {
    # Descargar y extraer PostfixAdmin desde Sourceforge
    echo "Descargando PostfixAdmin $LATEST_VERSION desde Sourceforge..."
    if sudo wget -q "https://downloads.sourceforge.net/project/postfixadmin/postfixadmin/postfixadmin-${LATEST_VERSION}/postfixadmin-${LATEST_VERSION}.tar.gz"; then
        # Extraer archivo comprimido
        echo "Extrayendo archivo comprimido..."
        if sudo tar -xvzf "postfixadmin-${LATEST_VERSION}.tar.gz"; then
            echo "PostfixAdmin descargado y extraído correctamente."
        else
            echo "Error al extraer el archivo comprimido de PostfixAdmin. Saliendo..."
            exit 1
        fi
    else
        echo "Error al descargar PostfixAdmin desde Sourceforge. Saliendo..."
        exit 1
    fi
}
# Función para mover directorio
function move_dir() {
    sudo mv postfixadmin-${LATEST_VERSION} "$WEB_DIR"
    sudo chown -R $UID:$GID "$WEB_DIR"
} 
# Función para crear el archivo de configuracion
function create_config() {
    # crear el archivo de configuracion
    echo "Creando el archivo de configuracion..."
    sudo touch "$CONFIG_FILE"
}
# Función para leer la lista de usuarios
function read_users_file() {
    echo "Leyendo la lista de usuarios ..."
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

# Función principal
function configure_postfixadmin() {
    echo "**********CONFIGURE POSTFIXADMIN***********"
    get_latest_version
    wget_postfixadmin
    move_dir
    create_config
    read_users_file
    write_config_file
    echo "**************ALL DONE***************"
}
# Llamar a la función principal
configure_postfixadmin
