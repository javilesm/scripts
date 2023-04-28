#!/bin/bash
# mysql_grant_privileges.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
USERS_FILE="mysql_users.csv"
USERS_PATH="$SCRIPT_DIR/$USERS_FILE"
password="root"
# Función para validar la existencia del archivo de privilegios
function check_privileges_file() {
    echo "Validando la existencia del archivo de privilegios..."
    if [ ! -f "$USERS_PATH" ]; then
        echo "El archivo de privilegios '$USERS_FILE' no existe."
        exit 1
    fi
    echo "El archivo de privilegios '$USERS_FILE' existe en el directorio $SCRIPT_DIR/"
}

# Función para otorgar privilegios a un usuario en una o varias bases de datos de PostgreSQL
function grant_access() {
    echo "Otorgando privilegios a un usuario en una o varias bases de datos de PostgreSQL..."

    # Leer la información de los usuarios desde el archivo postgresql_users.csv
    while IFS=',' read -r username password databases privileges; do
        echo "Otorgando privilegios '$privileges' al usuario '$username' en las bases de datos '$databases'..."

        # Otorgar privilegios a cada base de datos
        IFS=';' read -ra dbs <<< "$databases"
        for db in "${dbs[@]}"; do
            sudo -u postgres psql -c "GRANT $privileges PRIVILEGES ON DATABASE $db TO $username;"
        done

        # Verificar que se han otorgado los privilegios correctamente
        for db in "${dbs[@]}"; do
            if ! sudo -u postgres psql -c "SELECT has_database_privilege('$username', '$db', 'CREATE');" | grep -q "t"
            then
                echo "No se han podido otorgar los privilegios al usuario '$username' en la base de datos '$db'."
                exit 1
            fi
        done
    done < <(sed -e '$a\' "$USERS_PATH")
    echo "Todos los privilegios en '$USERS_FILE' fueron otorgados."
}
# Función para mostrar todos los privilegios en PostgreSQL
function show_privileges() {
    echo "Mostrando todos los privilegios en PostgreSQL..."

    sudo -u postgres psql -c "SELECT grantee, privilege_type, is_grantable, table_catalog, table_schema, table_name, column_name
        FROM information_schema.role_column_grants
        WHERE table_catalog = 'nombre_de_tu_base_de_datos';"

    echo "Fin de la lista de privilegios."
}
# Función principal
function psql_grant_privileges() {
    echo "**********POSTGRESQL GRANT PRIVILEGES**********"
    check_privileges_file
    grant_privileges
    show_privileges
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
psql_grant_privileges
