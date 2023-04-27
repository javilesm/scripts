#!/bin/bash
# mysql_create_user.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
USERS_FILE="mysql_users.csv"
USERS_PATH="$SCRIPT_DIR/$USERS_FILE"
password="root"
# Función para verificar la existencia del archivo de usuarios
function check_user_file() {
    echo "Verificando la existencia del archivo de usuarios"
    if [ ! -f "$USERS_PATH" ]; then
        echo "El archivo de usuarios '$USERS_FILE' no existe en el directorio $SCRIPT_DIR/"
        exit 1
    fi
    echo "El archivo de usuarios '$USERS_FILE' existe."
}
# Función para crear un usuario en MySQL
function create_user() {
    echo "Creando usuarios en MySQL desde '$USERS_FILE' ..."
    # Leer la lista de usuarios y contraseñas desde el archivo mysql_users.csv
    while IFS="," read -r username password host databases privileges; do
        # Verificar si el usuario ya existe
        if sudo mysql -e "SELECT 1 FROM mysql.user WHERE user='$username'" | grep -q 1; then
            echo "El usuario '$username' ya existe."
            continue
        fi

        # Crear usuario
        sudo mysql -e "CREATE USER '$username'@'$host' IDENTIFIED BY '$password';"

        # Asignar permisos a las bases de datos
        for database in $(echo $databases | tr ',' ' '); do
            echo "Asignando permisos a la base de datos '$database' para el usuario '$username'..."
            sudo mysql -e "GRANT $privileges ON $database.* TO '$username'@'$host';"
        done

        # Verificar que el usuario se ha creado correctamente
        if ! sudo mysql -e "SELECT 1 FROM mysql.user WHERE user='$username'" | grep -q 1
        then
            echo "No se ha podido crear el usuario '$username' en el host '$host'."
            exit 1
        fi
    done < <(sed -e '$a\' "$USERS_PATH")
    echo "Todos los usuarios en '$USERS_FILE' fueron creados."
}
# Función para mostrar todos los usuarios en MySQL
function show_users() {
    echo "Mostrando todos los usuarios en MySQL..."
    sudo mysql -e "SELECT User, Host FROM mysql.user;"
}
# Función principal
function mysql_create_user() {
    echo "**********MYSQL CREATE USER**********"
    check_user_file
    create_user
    show_users
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
mysql_create_user
