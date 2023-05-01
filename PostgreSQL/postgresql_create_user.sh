#!/bin/bash
# postgresql_create_user.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
USERS_FILE="postgresql_users.csv"
USERS_PATH="$SCRIPT_DIR/$USERS_FILE"
# Función para verificar la existencia del archivo de usuarios
echo "Verificar la existencia del archivo de usuarios..."
function check_users_file() {
    if [ ! -f "$USERS_PATH" ]; then
        echo "El archivo de usuarios '$USERS_FILE' no existe."
        exit 1
    fi
    echo "El archivo de usuarios '$USERS_FILE' existe."
}
# Función para crear un usuario en PostgreSQL y asignarle permisos
function create_user() {
    echo "Creando usuarios en PostgreSQL desde '$USERS_FILE' ..."
    # Leer la lista de usuarios y contraseñas desde el archivo postgresql_users.csv
    while IFS="," read -r username password host databases privileges; do
        # Verificar si el usuario ya existe
        echo "Verificando si el usuario '$username' ya existe..."
        if sudo -u postgres psql -c "SELECT 1 FROM pg_user WHERE usename='$username'" | grep -q 1; then
            echo "El usuario '$username' ya existe."
            continue
        else
            echo "El usuario '$username' no existe, verificando..."
            ##########################################
            # Verificar que el valor de "host" sea válido
            echo "Verificando que el valor de "host" sea válido para el usuario '$username'..."
            if ! [[ "$host" =~ ^(%|localhost|127\.0\.0\.1|\*)$ ]]; then
                echo "El valor de 'host' para el usuario '$username' no es válido: '$host'"
                continue
            fi
            # Verificar que el valor de "databases" sea válido
            echo "Verificando que el valor de "databases" sea válido para el usuario '$username'..."
            valid_databases=$(sudo -u postgres psql -Atc "SELECT datname FROM pg_database")
            for db in $(echo "$databases" | tr ',' ' '); do
                if ! echo "$valid_databases" | grep -q "^$db$"; then
                    echo "El valor de 'databases' para el usuario '$username' no es válido: '$db'"
                    continue 2
                fi
            done
            # Verificar que el valor de "privileges" sea válido
            echo "Verificando que el valor de "privileges" sea válido para el usuario '$username'..."
            valid_privileges="ALL, SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER"
            for priv in $(echo "$privileges" | tr ',' ' '); do
                if ! echo "$valid_privileges" | grep -q "\b$priv\b"; then
                    echo "El valor de 'privileges' para el usuario '$username' no es válido: '$priv'"
                    continue 2
                fi
            done
            ##########################################
            # Crear usuario
            echo "Creando al usuario '$username'..."
            if ! sudo -u postgres psql -c "CREATE USER $username WITH PASSWORD '$password';"; then
                echo "Error al crear al usuario '$username'."
                continue
            fi
            echo "El usuario '$username' ha sido creado exitosamente."
            # Esperar un corto período de tiempo antes de verificar el usuario
            sleep 5
            # Verificar que el usuario se ha creado correctamente
            echo "Verificando que el usuario '$username' se haya creado correctamente..."
            if ! sudo -u postgres psql -c "SELECT 1 FROM pg_user WHERE usename='$username'" | grep -q 1; then
                echo "No se ha podido crear el usuario '$username'."
                continue
            fi
            echo "El usuario '$username' ha sido verificado exitosamente."

            # Verificar que la base de datos exista antes de asignar permisos
            echo "Verificando que la base de datos '$databases' exista..."
            if ! sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname='$databases'" | grep -q 1; then
                echo "La base de datos '$databases' no existe."
                continue
            fi
            echo "La base de datos '$databases' existe."
            # Otorgar privilegios a cada base de datos
            echo "Otorgando privilegios '$privileges' al usuario '$username' en las bases de datos '$databases'..."
            IFS=';' read -ra dbs <<< "$databases"
            for db in "${dbs[@]}"; do
                sudo -u postgres psql -c "GRANT $privileges ON DATABASE $db TO $username;"
            done

            # Verificar que se han otorgado los privilegios correctamente
            for db in "${dbs[@]}"; do
                if ! sudo -u postgres psql -c "SELECT has_database_privilege('$username', '$db', 'CREATE');" | grep -q "t"
                then
                    echo "No se han podido otorgar los privilegios al usuario '$username' en la base de datos '$db'."
                    exit 1
                fi
            done
        fi
    done < <(sed -e '$a\' "$USERS_PATH")
    echo "Todos los usuarios en '$USERS_FILE' fueron creados y se les asignaron permisos en las bases de datos especificadas."
}
# Función para mostrar todos los usuarios en PostgreSQL
function show_users() {
    echo "Mostrando todos los usuarios en PostgreSQL..."
    sudo -u postgres psql -c "SELECT usename FROM pg_user;"
}
# Función principal
function postgresql_create_user() {
    echo "**********POSTGRESQL CREATE USER**********"
    check_users_file
    show_users
    create_user
    show_users
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
postgresql_create_user
