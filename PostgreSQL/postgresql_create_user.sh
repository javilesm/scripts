#!/bin/bash
# postgresql_create_user.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
USER_FILE="postgresql_users.csv"
USERS_PATH="$SCRIPT_DIR/$USER_FILE"
# Función para verificar la existencia del archivo de usuarios
echo "Verificar la existencia del archivo de usuarios..."
function check_user_file() {
    if [ ! -f "$USERS_PATH" ]; then
        echo "El archivo de usuarios '$USER_FILE' no existe."
        exit 1
    fi
    echo "El archivo de usuarios '$USER_FILE' existe."
}
# Función para crear un usuario en PostgreSQL
function create_user() {
    echo "Creando usuarios en PostgreSQL desde '$USERS_FILE' ..."
    # Leer la lista de usuarios y contraseñas desde el archivo postgresql_users.csv
    while IFS="," read -r username password host databases privileges; do
        # Crear usuario
        echo "Creando el usuario '$username'..."
        if sudo -u postgres psql -c "CREATE USER $username WITH PASSWORD '$password';"; then
            echo "Error al crear al usuario '$username'."
            exit 1
        fi
        echo "El usuario '$username' ha sido creado exitosamente."
        # Verificar que el usuario se ha creado correctamente
        echo "Verificando que el usuario '$username' se haya creado correctamente..."
        if ! sudo -u postgres psql -c "SELECT 1 FROM pg_user WHERE username='$username'" | grep -q 1
        then
            echo "No se ha podido crear el usuario '$username'."
            exit 1
        fi
        echo "El usurio '$username' ha sido verificado exitosamente."
    done < <(sed -e '$a\' "$USERS_PATH")
    echo "Todos los usuarios en '$USERS_FILE' fueron creados."
}
# Función para mostrar todos los usuarios en PostgreSQL
function show_users() {
    echo "Mostrando todos los usuarios en PostgreSQL..."
    sudo -u postgres psql -c "SELECT usename FROM pg_user;"
}
# Función principal
function postgresql_create_user() {
    echo "**********MYSQL CREATE USER**********"
    check_user_file
    create_user
    show_users
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
postgresql_create_user
