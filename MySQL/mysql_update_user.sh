#!/bin/bash
# mysql_update_user.sh
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
# Función para actualizar usuarios en MySQL
function update_users() {
    echo "Actualizando el host de los usuarios en la base de datos de MySQL..."

    # Leer la información de los usuarios desde el archivo mysql_users.csv
    while IFS=',' read -r username password old_host databases privileges; do
        echo "Actualizando el host del usuario '$username'..."
        # Verificar si el host ha cambiado
        if [ "$old_host" == "$new_host" ]; then
            echo "El host del usuario '$username' no ha cambiado."
            continue
        fi

        # Actualizar el host del usuario en cada base de datos
        IFS=',' read -ra dbs <<< "$databases"
        for db in "${dbs[@]}"; do
            # Eliminar el usuario existente
            mysql -u root -p"$password" -e "DROP USER '$username'@'$old_host';" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "Error al eliminar el usuario '$username' en el host '$old_host'."
                continue
            fi

            # Crear el usuario con el nuevo host
            mysql -u root -p"$password" -e "CREATE USER '$username'@'$new_host' IDENTIFIED BY '$password';" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "Error al crear el usuario '$username' en el host '$new_host'."
                continue
            fi

            # Otorgar privilegios al usuario en la base de datos
            mysql -u root -p"$password" -e "GRANT $privileges ON $db.* TO '$username'@'$new_host';" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "Error al otorgar privilegios al usuario '$username' en la base de datos '$db' en el host '$new_host'."
                continue
            fi

            echo "El usuario '$username' en la base de datos '$db' ha sido actualizado correctamente con el nuevo host '$new_host'."
        done
    done < <(sed -e '$a\' "$USERS_PATH")
}
# Función para mostrar todos los usuarios en MySQL
function show_users() {
    echo "Mostrando todos los usuarios en MySQL..."
    sudo mysql -e "SELECT User, Host FROM mysql.user;"
}
# Función principal
function mysql_update_user() {
    echo "**********MYSQL CONFIG**********"
    check_user_file
    update_users
    show_users
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
mysql_update_user
