#!/bin/bash
# mysql_config.sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
USERS_FILE="mysql_users.csv"
USERS_PATH="$SCRIPT_DIR/$USERS_FILE"
DBS_FILE="mysql_db.csv"
DBS_PATH="$SCRIPT_DIR/$DBS_FILE"
ROLES_FILE="mysql_roles.csv"
ROLES_PATH="$SCRIPT_DIR/$ROLES_FILE"
# Función para verificar si se ejecuta el script como root
function check_root() {
    echo "Verificando si se ejecuta el script como root..."
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ser ejecutado como root"
        exit 1
    fi
}
# Función para iniciar MySQL como servicio
function start_service() {
    echo "Iniciando MySQL como servicio..."
    if ! sudo service mysql status; then
        echo "No se pudo iniciar MySQL como servicio."
        exit 1
    fi
    sudo service mysql status
}
# Función para verificar la existencia del archivo de usuarios
function check_user_file() {
    echo "Verificando la existencia del archivo de usuarios"
    if [ ! -f "$USERS_PATH" ]; then
        echo "El archivo de usuarios '$USERS_FILE' no existe en el directorio $SCRIPT_DIR/"
        exit 1
    fi
    echo "El archivo de usuarios '$USERS_FILE' existe."
}
# Función para validar la existencia del archivo de bases de datos
function check_dbs_file() {
    echo "Validando la existencia del archivo de bases de datos..."
    if [ ! -f "$DBS_PATH" ]; then
        echo "El archivo de bases de datos '$DBS_FILE' no existe en el directorio $SCRIPT_DIR/"
        exit 1
    fi
    echo "El archivo de bases de datos '$DBS_FILE' existe."
}
# Función para crear una base de datos en MySQL
function create_db() {
    echo "Creando bases de datos en MySQL desde '$DBS_FILE' ..."
    # Leer la lista de bases de datos desde el archivo mysql_databases.csv
    while IFS=, read -r dbname; do
        # Crear base de datos
        sudo mysql -e "CREATE DATABASE IF NOT EXISTS $dbname;"
    done < "$DBS_PATH"
}
# Función para crear un usuario en MySQL
function create_user() {
    echo "Creando usuarios en MySQL desde '$USERS_FILE' ..."
    # Leer la lista de usuarios y contraseñas desde el archivo mysql_users.csv
    while IFS=, read -r username password address; do
        # Verificar si el usuario ya existe
        if sudo mysql -e "SELECT 1 FROM mysql.user WHERE user='$username'" | grep -q 1; then
            echo "El usuario '$username' ya existe."
            continue
        fi

        # Crear usuario
        sudo mysql -e "CREATE USER '$username'@'$address' IDENTIFIED BY '$password';"

        # Verificar que el usuario se ha creado correctamente
        if ! sudo mysql -e "SELECT 1 FROM mysql.user WHERE user='$username'" | grep -q 1
        then
            echo "No se ha podido crear el usuario '$username'."
            exit 1
        fi
    done < "$USERS_PATH"
}

# Función para otorgar permisos de acceso a un usuario en una o varias bases de datos de MySQL
function grant_access() {
    echo "Otorgando permisos de acceso a un usuario en una o varias bases de datos de MySQL..."

    # Leer la información de los usuarios desde el archivo mysql_users.csv
    while IFS=',' read -r username password address databases privileges; do

        # Verificar si se pasó al menos una base de datos
        if [[ -z $databases ]]; then
            echo "Se debe especificar al menos una base de datos para otorgar privilegios al usuario '$username' desde '$address'."
            exit 1
        fi

        # Verificar que los permisos tienen el formato correcto
        if ! [[ "$privileges" =~ ^(ALL PRIVILEGES|CREATE|ALTER|DROP|GRANT|SELECT|INSERT|UPDATE|DELETE)$ ]]; then
            echo "El privilegio '$privileges' no tiene un formato válido para el usuario '$username' en las bases de datos '$databases' desde '$address'."
            exit 1
        fi

        echo "Otorgando permisos de acceso para el usuario '$username' en las bases de datos '$databases' con nivel de acceso '$privileges'..."

        # Verificar si el usuario ya cuenta con los permisos
        existing_privileges=$(sudo mysql -e "SELECT privilege_type FROM mysql.db WHERE user='$username' AND db IN ('$databases') AND host='$address'")
        if [[ -n $existing_privileges ]]; then
            # Si el usuario ya tiene permisos, actualizarlos
            for db in "${databases//;/ }"; do
                sudo mysql -e "GRANT $privileges ON $db.* TO '$username'@'$address' WITH GRANT OPTION;"
            done
        else
            # Si el usuario no tiene permisos, otorgarlos
            for db in "${databases//;/ }"; do
                sudo mysql -e "GRANT $privileges ON $db.* TO '$username'@'$address';"
            done
        fi

        # Verificar que se han otorgado o actualizado los permisos correctamente
        for db in "${databases//;/ }"; do
            if ! sudo mysql -e "SELECT 1 FROM mysql.db WHERE user='$username' AND db='$db' AND host='$address' AND privilege_type='$privileges'" | grep -q 1
            then
                echo "No se han podido otorgar o actualizar los permisos de acceso al usuario '$username' en la base de datos '$db' desde '$address'."
                exit 1
            fi
        done

    done < "$USERS_PATH"
}
# Función para reiniciar el servicio de MySQL
function restart_mysql_service() {
    echo "Reiniciando el servicio de MySQL..."
    sudo service mysql restart
}
# Función principal
function mysql_config() {
    echo "**********MYSQL CONFIG**********"
    check_root
    check_user_file
    check_dbs_file
    create_db
    create_user
    grant_access
    restart_postgresql_service
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
mysql_config
