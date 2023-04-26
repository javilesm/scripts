#!/bin/bash
# postgresql_config.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
USER_FILE="postgresql_users.csv"
USERS_PATH="$SCRIPT_DIR/$USER_FILE"
DBS_FILE="postgresql_db.csv"
DBS_PATH="$SCRIPT_DIR/$USER_FILE"
ROLES_FILE="postgresql_roles.csv"
ROLES_PATH="$SCRIPT_DIR/$ROLES_FILE"
# Función para verificar si se ejecuta el script como root
function check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ser ejecutado como root"
        exit 1
    fi
}
# Función para validar la existencia del archivo de roles
function check_roles_file() {
    if [ ! -f "$ROLES_PATH" ]; then
        echo "El archivo $ROLES_FILE no existe"
        exit 1
    fi
    echo "El archivo $ROLES_FILE existe"
}
# Función para verificar la existencia del archivo de usuarios
function check_user_file() {
    if [ ! -f "$USERS_PATH" ]; then
        echo "El archivo de usuarios $USER_FILE no existe."
        exit 1
    fi
    echo "El archivo de usuarios $USER_FILE existe."
}
# Función para validar la existencia del archivo de bases de datos
function check_dbs_file() {
    if [ ! -f "$DBS_PATH" ]; then
        echo "El archivo de bases de datos $DBS_FILE no existe."
        exit 1
    fi
    echo "El archivo de bases de datos $DBS_FILE existe."
}
# Función para crear roles de usuario en PostgreSQL
function create_roles() {
    echo "Creando roles de usuario en PostgreSQL desde $ROLES_PATH ..."
    # Leer la lista de roles de usuario desde el archivo postgresql_roles.csv
    while IFS=, read -r rolename password; do
        # Crear el rol de usuario
        sudo -u postgres psql -c "CREATE ROLE $rolename LOGIN PASSWORD '$password';"

        # Verificar que el rol de usuario se ha creado correctamente
        if ! sudo -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname='$rolename'" | grep -q 1; then
            echo "No se ha podido crear el rol de usuario '$rolename'."
            exit 1
        fi
    done < "$ROLES_PATH"
}
# Función para crear una base de datos en PostgreSQL
function create_db() {
    echo "Creando bases de datos en PostgreSQL desde $DBS_PATH ..."
    # Leer la lista de bases de datos desde el archivo postgresql_db.csv
    while IFS=',' read -r dbname owner encoding; do
        # Crear base de datos
        sudo -u postgres createdb --owner="$owner" --encoding="$encoding" "$dbname"

        # Verificar que la base de datos se ha creado correctamente
        if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$dbname"
        then
            echo "No se ha podido crear la base de datos '$dbname'."
            exit 1
        fi
    done < "$DBS_PATH"
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
            echo "No se ha podido crear el usuario '$username'."
            exit 1
        fi
    done < "$USERS_PATH"
}
# Función para otorgar permisos de acceso a un usuario en una o varias bases de datos de PostgreSQL
function grant_access() {
    echo "Otorgando permisos de acceso a un usuario en una o varias bases de datos de PostgreSQL..."

    # Leer la información de los usuarios desde el archivo postgresql_users.csv
    while IFS=',' read -r username password databases privileges; do
        echo "Otorgando privilegios '$privileges' al usuario '$username' en las bases de datos '$databases'..."

        # Otorgar permisos de acceso a cada base de datos
        IFS=';' read -ra dbs <<< "$databases"
        for db in "${dbs[@]}"; do
            sudo -u postgres psql -c "GRANT $privileges PRIVILEGES ON DATABASE $db TO $username;"
        done

        # Verificar que se han otorgado los permisos correctamente
        for db in "${dbs[@]}"; do
            if ! sudo -u postgres psql -c "SELECT has_database_privilege('$username', '$db', 'CREATE');" | grep -q "t"
            then
                echo "No se han podido otorgar los privilegios al usuario '$username' en la base de datos '$db'."
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
    check_roles_file
    check_user_file
    check_dbs_file
    create_roles
    create_db
    create_user
    grant_access
    restart_postgresql_service
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
postgresql_config
