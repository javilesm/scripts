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
    echo "El archivo de bases de datos '$DBS_FILE' existe."
}
# Función para crear una base de datos en PostgreSQL
function create_db() {
    echo "Creando bases de datos en PostgreSQL desde $DBS_PATH..."
    # Leer la lista de bases de datos desde el archivo postgresql_db.csv
    while IFS=',' read -r dbname owner encoding; do
        # Crear base de datos
        sudo -u postgres createdb --owner="$owner" --encoding="$encoding" "$dbname"

        # Verificar que la base de datos se ha creado correctamente
        if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$dbname"
        then
            echo "No se ha podido crear la base de datos '$dbname'."
            exit 1
        fi
    done < <(sed -e '$a\' "$DBS_PATH")
}
# mostrar todas las bases de datos en PostgreSQL
function show_databases() {
    echo "Mostrando todas las bases de datos en PostgreSQL..."
    sudo -u postgres psql -c "SELECT datname FROM pg_database WHERE datistemplate = false;"
}
# Función principal
function postgresql_create_db() {
    echo "**********POSTGRESQL CONFIG**********"
    check_dbs_file
    create_db
    show_databases
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
postgresql_create_db
