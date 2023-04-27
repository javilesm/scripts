#!/bin/bash
# mysql_update_privileges.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
USERS_FILE="mysql_users.csv"
USERS_PATH="$SCRIPT_DIR/$USERS_FILE"
password="root"
# Función para actualizar privilegios a un usuario en una o varias bases de datos de MySQL
function update_privileges() {
    echo "Actualizando privilegios a un usuario en una o varias bases de datos de MySQL..."
    # Leer la información de los usuarios desde el archivo mysql_users.csv
    while IFS="," read -r username password host databases privileges; do
        echo "Otorgando '$privileges' a '$username' en '$databases'..."
        # Verificar si el usuario ya tiene privilegios en cada base de datos
        IFS="," read -ra dbs <<< "$databases"
        for db in "${dbs[@]}"; do
            if mysql -u root -p"$password" -e "SELECT User, Host, Db FROM mysql.db WHERE User='$username' AND Db='$db';" | grep -q "$username"; then
                # Actualizar privilegios del usuario si es necesario
                mysql -u root -p"$password" -e "GRANT $privileges ON $db.* TO '$username'@'$host' WITH GRANT OPTION;"
                echo "Los privilegios del usuario '$username' en la base de datos '$db' en el host '$host' se han actualizado correctamente."
            else
                # Otorgar privilegios al usuario si no los tiene
                mysql -u root -p"$password" -e "GRANT $privileges ON $db.* TO '$username'@'$host' WITH GRANT OPTION;"
                echo "Los privilegios del usuario '$username' en la base de datos '$db' en el host '$host' se han otorgado correctamente."
            fi
        done
    done < <(sed -e '$a\' "$USERS_PATH")
}
# Aplicar los privilegios en el servidor
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
# mostrar todos los privilegios en MySQL
function show_privileges() {
  echo "Mostrando todos los privilegios en MySQL..."
  sudo mysql -e "SELECT * FROM mysql.user\G;"
}
# Función principal
function mysql_update_privileges() {
    echo "**********MYSQL GRANT PRIVILEGES**********"
    update_privileges
    apply_mysql_privileges
    show_privileges
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
mysql_update_privileges
