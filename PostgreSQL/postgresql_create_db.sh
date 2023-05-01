#!/bin/bash
# postgresql_create_db.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DBS_FILE="postgresql_db.csv"
DBS_PATH="$SCRIPT_DIR/$DBS_FILE"
# Función para validar la existencia del archivo de bases de datos
function check_dbs_file() {
    echo "Validando la existencia del archivo de bases de datos..."
    if [ ! -f "$DBS_PATH" ]; then
        echo "El archivo de bases de datos '$DBS_FILE' no existe."
        exit 1
    fi
    echo "El archivo de bases de datos '$DBS_FILE' existe en el directorio $SCRIPT_DIR/"
    echo "El archivo de bases de datos '$DBS_FILE' existe."
}
# Función para crear una base de datos en PostgreSQL
function create_db() {
    echo "Creando bases de datos en PostgreSQL desde '$DBS_PATH'..."
    # Leer la lista de bases de datos desde el archivo postgresql_db.csv
    while IFS=',' read -r dbname; do
        # Verificar si la base de datos ya existe
        echo "Verificando si la base de datos '$dbname' ya existe..."
        if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$dbname"; then
            echo "La base de datos '$dbname' ya existe."
            continue
        else
            # Crear base de datos
            echo "La base de datos '$dbname', creando..."
            if ! sudo -u postgres psql -c "CREATE DATABASE $dbname"; then
                echo "Error al crear la base de datos '$dbname'."
                continue
            fi
            echo "La base de datos '$dbname' ha sido creada exitosamente."
            # Esperar un corto período de tiempo antes de verificar la base de datos
            sleep 5
            # Verificar que la base de datos se ha creado correctamente
            echo "Verificar que la base de datos '$dbname' se haya creado correctamente..."
            if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$dbname"
            then
                echo "No se ha podido crear la base de datos '$dbname'."
                continue
            fi
            echo "La base de datos '$dbname' ha sido verificada exitosamente."
        fi
    done < <(sed -e '$a\' "$DBS_PATH")
    echo "Todas las bases de datos en '$DBS_FILE' fueron creadas."
}
# mostrar todas las bases de datos en PostgreSQL
function show_databases() {
    echo "Mostrando todas las bases de datos en PostgreSQL..."
    sudo -u postgres psql -c "\l"
}
# Función principal
function postgresql_create_db() {
    echo "**********POSTGRESQL CREATE DB**********"
    check_dbs_file
    show_databases
    create_db
    show_databases
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
postgresql_create_db
