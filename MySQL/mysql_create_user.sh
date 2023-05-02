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
        echo "Verificando si el usuario '$username' ya existe..."
        if sudo mysql -e "SELECT 1 FROM mysql.user WHERE user='$username'" | grep -q 1; then
            echo "El usuario '$username' ya existe."
            continue
        else
            echo "El usuario '$username' no existe, verificando requerimientos..."
            # Verificar que el valor de 'host' sea válido
            echo "Verificando que el valor de "host" sea válido para el usuario '$username'..."
            if [[ "$host" != "localhost" && "$host" != "%" && ! $host =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "El valor de 'host' ($host) para el usuario '$username' no es válido. Debe ser 'localhost', '%' o una dirección IP válida."
                continue 2
            fi
            # Verificar que los valores de 'databases' sean válidos
            echo "Verificando que el valor de "databases" sea válido para el usuario '$username'..."
           for database in $(echo $databases | tr ',' ' '); do
                if ! sudo mysql -e "USE $database" 2>/dev/null; then
                    echo "El valor de 'databases' ($database) para el usuario '$username' no es válido. No existe la base de datos '$database'."
                    continue 2
                fi
            done
            # Verificar que los valores de 'privileges' sean válidos
            echo "Verificando que el valor de "privileges" sea válido para el usuario '$username'..."
            valid_privileges=("ALL PRIVILEGES" "CREATE" "DROP" "ALTER" "SELECT" "INSERT" "UPDATE" "DELETE")
            for privilege in $(echo $privileges | tr ',' ' '); do
                if ! [[ " ${valid_privileges[@]} " =~ " $privilege " ]]; then
                    echo "El valor de 'privileges' ($privilege) para el usuario '$username' no es válido. Debe ser uno de los siguientes: ${valid_privileges[@]}"
                    continue 2
                fi
            done
            # Crear usuario
            echo "Creando al usuario '$username'..."
            if ! sudo mysql -e "CREATE USER '$username'@'$host' IDENTIFIED BY '$password';"; then
                echo "Error al crear al usuario '$username'."
                continue
            fi
            echo "El usuario '$username' ha sido creado exitosamente."
            # Esperar un corto período de tiempo antes de verificar el usuario
            sleep 5
            # Verificar que el usuario se ha creado correctamente
            echo "Verificando que el usuario '$username' se haya creado correctamente..."
            if ! sudo mysql -e "SELECT 1 FROM mysql.user WHERE user='$username'" | grep -q 1
            then
                echo "No se ha podido crear el usuario '$username' en el host '$host'."
                exit 1
            fi
            echo "El usuario '$username' ha sido verificado exitosamente."
            # Verificar que la base de datos exista antes de asignar permisos
           if ! sudo mysql -e "USE $db;" 2>/dev/null; then
                echo "La base de datos '$db' no existe. No se asignarán permisos al usuario '$username' para esta base de datos."
                continue
            fi
            # Otorgar privilegios a cada base de datos
            echo "Otorgando privilegios '$privileges' al usuario '$username' en las bases de datos '$databases'..."
            for database in $(echo $databases | tr ',' ' '); do
                echo "GRANT $privileges ON $database.* TO '$username'@'$host';"
                sudo mysql -e "GRANT $privileges ON $database.* TO '$username'@'$host';"
            done
        fi
    done < <(sed -e '$a\' "$USERS_PATH")
    echo "Todos los usuarios en '$USERS_FILE' fueron creados."
}
# Función para mostrar todos los usuarios en MySQL
function show_users() {
    echo "Mostrando todos los usuarios en MySQL..."
    sudo mysql -e "SELECT User, Host, plugin FROM mysql.user;"
}
# Función para mostrar todos privilegios de un usuario en MySQL
function show_grants() {
    echo "Mostrando todos privilegios de un usuario en MySQL ..."
    # Leer la lista de usuarios y contraseñas desde el archivo mysql_users.csv
    while IFS="," read -r username password host databases privileges; do
        # Verificar que se han otorgado los permisos correctamente
        for user in $(echo $username | tr ',' ' '); do
            if ! sudo mysql -e "SHOW GRANTS FOR $username@$host"; then
                echo "No se han otorgado los permisos correctamente para el usuario '$username' en la base de datos '$database'."
                exit 1
            fi
        done
    done < <(sed -e '$a\' "$USERS_PATH")
    echo "Todos los privilegios en '$USERS_PATH' fueron mostrados."
}
function apply_mysql_privileges() {
     # Aplicar los privilegios en el servidor MySQL
    echo "Aplicando los privilegios en el servidor MySQL..."
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    # Verificar si hubo errores
    if [ $? -eq 0 ]; then
        echo "Los privilegios en el servidor MySQL se han aplicado correctamente."
    else
        echo "Error al aplicar los privilegios en el servidor MySQL."
    fi
}
# Función principal
function mysql_create_user() {
    echo "**********MYSQL CREATE USER**********"
    check_user_file
    show_users
    create_user
    show_users
    show_grants
    apply_mysql_privileges
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
mysql_create_user
