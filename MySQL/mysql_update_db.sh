#!/bin/bash
# mysql_update_db.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DBS_FILE="mysql_db.csv"
DBS_PATH="$SCRIPT_DIR/$DBS_FILE"
password="root"
# Función para actualizar una base de datos en MySQL
function update_db() {
    echo "Actualizando bases de datos en MySQL desde '$SCRIPT_DIR/$DBS_FILE' ..."
    # Leer la lista de bases de datos desde el archivo mysql_databases.csv
    while read -r dbname || [[ -n "$dbname" ]]; do
    
    done < <(sed -e '$a\' "$DBS_PATH")
    echo "Todas las bases de datos en '$DBS_FILE' fueron actualizadas."
}
# mostrar todas las bases de datos en MySQL
function show_databases() {
    echo "Mostrando todas las bases de datos en MySQL..."
    sudo mysql -e "SHOW DATABASES;"
}
# Función principal
function mysql_update_db() {
    echo "**********MYSQL CREATE DB**********"
    update_db
    show_databases
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
mysql_update_db
