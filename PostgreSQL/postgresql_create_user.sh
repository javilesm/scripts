#!/bin/bash
# postgresql_create_user.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
USERS_FILE="postgresql_users.csv"
USERS_PATH="$SCRIPT_DIR/$USERS_FILE"
# Función para verificar la existencia del archivo de usuarios
echo "Verificar la existencia del archivo de usuarios..."
function check_users_file() {
    if [ ! -f "$USERS_PATH" ]; then
        echo "El archivo de usuarios '$USERS_FILE' no existe."
        exit 1
    fi
    echo "El archivo de usuarios '$USERS_FILE' existe."
}
# Función para crear un usuario en PostgreSQL y asignarle permisos
function create_user() {
    echo "Creando usuarios en PostgreSQL desde '$USERS_FILE' ..."
    # Leer la lista de usuarios y contraseñas desde el archivo postgresql_users.csv
    while IFS="," read -r username password host databases privileges; do
        # Verificar si el usuario ya existe
        echo "Verificando si el usuario '$username' ya existe..."
        if sudo -u postgres psql -c "SELECT 1 FROM pg_user WHERE usename='$username'" | grep -q 1; then
            echo "El usuario '$username' ya existe."
            continue
        else
            # Crear usuario
            echo "El usuario '$username' no existe, creando..."
            if ! sudo -u postgres psql -c "CREATE USER $username WITH PASSWORD '$password';"; then
                echo "Error al crear al usuario '$username'."
                continue
            fi
            echo "El usuario '$username' ha sido creado exitosamente."
            # Esperar un corto período de tiempo antes de verificar el usuario
            sleep 5
            # Verificar que el usuario se ha creado correctamente
            echo "Verificando que el usuario '$username' se haya creado correctamente..."
            if ! sudo -u postgres psql -c "SELECT 1 FROM pg_user WHERE usename='$username'" | grep -q 1; then
                echo "No se ha podido crear el usuario '$username'."
                continue
            fi
            echo "El usuario '$username' ha sido verificado exitosamente."

            # Verificar que la base de datos exista antes de asignar permisos
            echo "Verificando que la base de datos '$databases' exista..."
            if ! sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname='$databases'" | grep -q 1; then
                echo "La base de datos '$databases' no existe."
                continue
            fi
            echo "La base de datos '$databases' existe."

            # Asignar permisos a la base de datos correspondiente
            echo "Asignando permisos a la base de datos '$databases' para el usuario '$username'..."
            if ! sudo -u postgres psql -c "GRANT $privileges ON DATABASE $databases TO $username;"; then
                echo "Error al asignar permisos a la base de datos '$databases' para el usuario '$username'."
                continue
            fi
            echo "Los permisos para la base de datos '$databases' han sido asignados exitosamente al usuario '$username'."
        fi
    done < <(sed -e '$a\' "$USERS_PATH")
    echo "Todos los usuarios en '$USERS_FILE' fueron creados y se les asignaron permisos en las bases de datos especificadas."
}
# Función para mostrar todos los usuarios en PostgreSQL
function show_users() {
    echo "Mostrando todos los usuarios en PostgreSQL..."
    sudo -u postgres psql -c "SELECT usename FROM pg_user;"
}
# Función principal
function postgresql_create_user() {
    echo "**********POSTGRESQL CREATE USER**********"
    check_USERS_FILE
    show_users
    create_user
    show_users
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
postgresql_create_user
