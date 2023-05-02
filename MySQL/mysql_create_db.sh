#!/bin/bash
# mysql_create_db.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DBS_FILE="mysql_db.csv"
DBS_PATH="$SCRIPT_DIR/$DBS_FILE"
password="root"
# Función para validar la existencia del archivo de bases de datos
function check_dbs_file() {
    echo "Validando la existencia del archivo de bases de datos..."
    if [ ! -f "$DBS_PATH" ]; then
        echo "El archivo de bases de datos '$DBS_FILE' no existe en el directorio $SCRIPT_DIR/"
        exit 1
    fi
    echo "El archivo de bases de datos '$DBS_FILE' existe."
}
# Función para crear una base de datos en MySQL
function create_db() {
    echo "Creando bases de datos en MySQL desde '$SCRIPT_DIR/$DBS_FILE' ..."
    # Leer la lista de bases de datos desde el archivo mysql_databases.csv
    while read -r dbname || [[ -n "$dbname" ]]; do
        # Verificar si la base de datos existe
        echo "Verificando si la base de datos '$dbname' ya existe..."
        if sudo mysql -e "USE $dbname" 2> /dev/null; then
            echo "La base de datos '$dbname' ya existe. Saltando..."
            continue
        else
            # Crear base de datos
            echo "La base de datos '$dbname' no existe, creando..."
            if ! sudo mysql -e "CREATE DATABASE $dbname"; then
                echo "Error al crear la base de datos '$dbname'."
                continue
            fi
            echo "La base de datos '$dbname' ha sido creada exitosamente."
            # Esperar un corto período de tiempo antes de verificar la base de datos
            sleep 5
            # Verificar que la base de datos se ha creado correctamente
            echo "Verificar que la base de datos '$dbname' se haya creado correctamente..."
            # Verificar que la base de datos se ha creado correctamente
            if sudo mysql -e "USE $dbname; SELECT 1" 2> /dev/null; then
                echo "La base de datos '$dbname' se ha creado correctamente."
            else
                echo "Error al crear la base de datos '$dbname'."
                continue
            fi
        fi
    done < <(sed -e '$a\' "$DBS_PATH")
    echo "Todas las bases de datos en '$DBS_FILE' fueron creadas."
}
# mostrar todas las bases de datos en MySQL
function show_databases() {
    echo "Mostrando todas las bases de datos en MySQL..."
    sudo mysql -e "SHOW DATABASES;"
}
# Función principal
function mysql_create_db() {
    echo "**********MYSQL CREATE DB**********"
    check_dbs_file
    show_databases
    create_db
    show_databases
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
mysql_create_db
