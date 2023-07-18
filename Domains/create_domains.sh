#!/bin/bash
# create_domains.sh
# Variables
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
DOMAINS_FILE="domains.csv"
CSV_FILE="$CURRENT_DIR/$DOMAINS_FILE"
USERS_FILE="mysql_users.csv"
USERS_PATH="$PARENT_DIR/MySQL/$USERS_FILE"
TABLE_NAME="domains" # Nombre de la tabla a crear

DB_PORT="3306"

# Función para obtener las variables de configuración de la base de datos
function read_users() {
    # Obtener las variables de configuración de la base de datos para el usuario "domains_admin"
    echo "Obteniendo las variables de configuración de la base de datos para el usuario 'domains_admin'..."
    while IFS="," read -r DB_USER DB_PASSWORD DB_HOST DB_NAME DB_PRIVILEGES || [[ -n "$domain" ]]; do
        if [ "$DB_USER" == "webmaster" ]; then
            echo "DB_USER: $DB_USER"
            
            # Ocultar parcialmente la contraseña para el usuario "domains_admin"
            password_length=${#DB_PASSWORD}
            hidden_password="${DB_PASSWORD:0:1}"
            hidden_password+="******"
            hidden_password+="${DB_PASSWORD: -1}"
            echo "DB_PASSWORD: $hidden_password"
            
            echo "DB_HOST: $DB_HOST"
            echo "DB_NAME: $DB_NAME"
            echo "DB_PRIVILEGES: $DB_PRIVILEGES"
            echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
            break
        fi
    done < <(grep -v '^$' "$USERS_PATH")
}

# Función para leer los dominios del archivo CSV
function read_domains() {
    echo "Leyendo la lista de dominios: '$CSV_FILE'..."
    while IFS="," read -r domain owner city state phone flag|| [[ -n "$domain" ]]; do
        echo "Dominio: $domain"
        echo "Propietario: $owner"
        echo "Ciudad: $city"
        echo "Estado: $state"
        echo "Tel: $phone"
        echo "Flag: $flag"
        echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    done < <(grep -v '^$' "$CSV_FILE")
    echo "Todos los dominios han sido leídos."
}

# Función para crear la tabla en la base de datos
function create_table() {
    local create_table_sql="CREATE TABLE IF NOT EXISTS $TABLE_NAME (
        domain VARCHAR(255),
        owner VARCHAR(255),
        city VARCHAR(255),
        state VARCHAR(255),
        phone VARCHAR(255),
        flag VARCHAR(255)
    );"

    mysql_command "$create_table_sql"
}

# Función para importar los datos del archivo CSV a la tabla
function import_csv() {
    local import_csv_sql="LOAD DATA LOCAL INFILE '$CSV_FILE'
    INTO TABLE $TABLE_NAME
    FIELDS TERMINATED BY ','
    LINES TERMINATED BY '\n'
    ;"
    echo "Ejecutando query: $import_csv_sql"
    mysql_command "$import_csv_sql"
}

# Función para ejecutar comandos SQL en la base de datos MySQL
function mysql_command() {
    local sql_command="$1"
    sudo mysql --local-infile=1 -u root -h "$DB_HOST" "$DB_NAME" -e "$sql_command"
}

# Función principal
function create_domains() {
    echo "***************CREATE DOMAINS***************"
    read_users
    read_domains
    create_table
    import_csv
    echo "***************ALL DONE***************"
}
# Llamar a la función principal
create_domains
