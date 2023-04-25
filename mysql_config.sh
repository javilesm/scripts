#!/bin/bash
# mysql_config.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
USER_FILE="mysql_users.csv"
USERS_PATH="$SCRIPT_DIR/$USER_FILE"
MYSQL_ROOT_PASSWORD="your_mysql_root_password"

# Función para verificar si se ejecuta el script como root
function check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ser ejecutado como root"
        exit 1
    fi
}

# Función para crear una base de datos en MySQL
function create_db() {
    echo "Creando una base de datos en MySQL..."
    # Solicitar el nombre de la base de datos
    read -p "Introduzca el nombre de la base de datos: " dbname

    # Crear base de datos
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE $dbname;"

    # Verificar que la base de datos se ha creado correctamente
    if ! mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES LIKE '$dbname';" | grep -q "$dbname"
    then
        echo "No se ha podido crear la base de datos."
        exit 1
    fi
}
# Función para crear un usuario en MySQL
function create_user() {
    echo "Creando usuarios en MySQL desde $USERS_PATH ..."
    # Leer la lista de usuarios y contraseñas desde el archivo mysql_users.csv
    while IFS=, read -r username password; do
        # Crear usuario
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '$password';"

        # Verificar que el usuario se ha creado correctamente
        if ! mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$username' AND host = 'localhost');" | grep -q "1"
        then
          echo "No se ha podido crear el usuario $username."
          exit 1
        fi
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
    create_db
    create_user
    grant_access
    restart_mysql_service
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
mysql_config
