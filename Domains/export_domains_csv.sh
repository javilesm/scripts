#!/bin/bash
# export_domains_csv.sh
# Variables de configuración
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
EXPORT_FILE="$CURRENT_DIR/export_domains.csv"
USERS_FILE="mysql_users.csv"
USERS_PATH="$CURRENT_DIR/$USERS_FILE"
TABLE_NAME="domains"

# Función para obtener las variables de configuración de la base de datos
function read_users() {
    echo "Obteniendo las variables de configuración de la base de datos..."
    while IFS="," read -r DB_USER DB_PASSWORD DB_HOST DB_NAME DB_PRIVILEGES || [[ -n "$domain" ]]; do
        echo "DB_USER: $DB_USER"
        echo "DB_PASSWORD: $DB_PASSWORD"
        echo "DB_HOST: $DB_HOST"
        echo "DB_NAME: $DB_NAME"
        echo "DB_PRIVILEGES: $DB_PRIVILEGES"
        echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    done < <(grep -v '^$' "$USERS_PATH")
}

# Función para exportar la tabla de dominios a un archivo CSV
function export_domains() {
    sql_command="SELECT * FROM $TABLE_NAME INTO OUTFILE '$EXPORT_FILE' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n';"
    mysql_command "$sql_command"
    echo "La tabla de dominios se ha exportado exitosamente a '$EXPORT_FILE'."
}

# Función para ejecutar comandos SQL en la base de datos MySQL
function mysql_command() {
    local sql_command="$1"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "$sql_command"
}

# Función principal
function export_domains_csv() {
    read_users
    export_domains
}

# Llamar a la función principal
export_domains_csv
