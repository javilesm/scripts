#!/bin/bash
# export_domains_csv.sh
# Variables de configuración
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
EXPORT_FILE="export_domains.csv"
EXPORT_DIR="/tmp"
EXPORT_PATH="$EXPORT_DIR/$EXPORT_FILE"
USERS_FILE="mysql_users.csv"
USERS_PATH="$PARENT_DIR/MySQL/$USERS_FILE"
TABLE_NAME="domains"

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

# Función para exportar la tabla de dominios a un archivo CSV
function export_domains() {
    sql_command="SELECT * FROM $DB_NAME.$TABLE_NAME INTO OUTFILE '$EXPORT_FILE' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n';"
    echo "Ejecutando query: $sql_command"
    mysql_command "$sql_command"
    echo "La tabla de dominios se ha exportado exitosamente a '$EXPORT_FILE'."
}

# Función para ejecutar comandos SQL en la base de datos MySQL
function mysql_command() {
    local sql_command="$1"
    sudo mysql -u root -h "$DB_HOST" "$DB_NAME" -e "$sql_command"
}

# Función principal
function export_domains_csv() {
    read_users
    export_domains
}

# Llamar a la función principal
export_domains_csv
