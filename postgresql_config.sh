#!/bin/bash
# postgresql_config.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
USER_FILE="postgresql_users.csv"
USERS_PATH="$SCRIPT_DIR/$USER_FILE"

# Función para verificar si se ejecuta el script como root
function check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ser ejecutado como root"
        exit 1
    fi
}
# Función para crear una base de datos en PostgreSQL
function create_db() {
    echo "Creando una base de datos en PostgreSQL..."
    # Solicitar el nombre de la base de datos
    read -p "Introduzca el nombre de la base de datos: " dbname

    # Crear base de datos
    sudo -u postgres psql -c "CREATE DATABASE $dbname;"

    # Verificar que la base de datos se ha creado correctamente
    if ! sudo -u postgres psql -lqt | cut -d | -f 1 | grep -wq $dbname
    then
        echo "No se ha podido crear la base de datos."
        exit 1
    fi
}
# Función para crear un usuario en PostgreSQL
function create_user() {
    echo "Creando usuarios en PostgreSQL desde $USERS_PATH ..."
    # Leer la lista de usuarios y contraseñas desde el archivo postgresql_users.csv
    while IFS=, read -r username password; do
        # Crear usuario
        sudo -u postgres psql -c "CREATE USER $username WITH PASSWORD '$password';"

        # Verificar que el usuario se ha creado correctamente
        if ! sudo -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname='$username'" | grep -q 1
        then
            echo "No se ha podido crear el usuario $username."
            exit 1
        fi
    done < "$USERS_PATH"
}

# Función para otorgar permisos de acceso a un usuario en una o varias bases de datos de PostgreSQL
function grant_access() {
    echo "Otorgando permisos de acceso a un usuario en una o varias bases de datos de PostgreSQL..."

    # Leer la información de los usuarios desde el archivo postgresql_users.csv
    while IFS=',' read -r username password databases access_level; do
        echo "Otorgando permisos de acceso para el usuario $username en las bases de datos $databases con nivel de acceso $access_level..."

        # Otorgar permisos de acceso a cada base de datos
        IFS=';' read -ra dbs <<< "$databases"
        for db in "${dbs[@]}"; do
            sudo -u postgres psql -c "GRANT $access_level PRIVILEGES ON DATABASE $db TO $username;"
        done

        # Verificar que se han otorgado los permisos correctamente
        for db in "${dbs[@]}"; do
            if ! sudo -u postgres psql -c "SELECT has_database_privilege('$username', '$db', 'CREATE');" | grep -q "t"
            then
                echo "No se han podido otorgar los permisos de acceso al usuario $username en la base de datos $db."
                exit 1
            fi
        done

    done < "$SCRIPT_DIR/postgresql_users.csv"
}
# Función para reiniciar el servicio de PostgreSQL
function restart_postgresql_service() {
    echo "Reiniciando el servicio de PostgreSQL..."
    sudo service postgresql restart
}
# Función principal
function postgresql_config() {
    echo "**********POSTGRESQL CONFIG**********"
    check_root
    create_db
    create_user
    grant_access
    restart_postgresql_service
    echo "**************ALL DONE**************"
}

# Llamar a la función principal
postgresql_config
