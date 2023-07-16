#!/bin/bash
# add_domains.sh
# Variables de configuración
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
DOMAINS_FILE="domains.csv"
CSV_FILE="$CURRENT_DIR/$DOMAINS_FILE"
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

# Función para agregar un nuevo registro a la tabla de dominios
function add_domain() {
    while true; do
        read -p "¿Desea agregar un nuevo registro? (S/N): " choice
        case "$choice" in
            [sS])
                read -p "Dominio: " domain
                read -p "Propietario: " owner
                read -p "Ciudad: " city
                read -p "Estado: " state
                read -p "Teléfono: " phone
                sql_command="INSERT INTO $TABLE_NAME (domain, owner, city, state, phone) VALUES ('$domain', '$owner', '$city', '$state', '$phone');"
                mysql_command "$sql_command"
                ;;
            *)
                echo "No se agregará un nuevo registro."
                return
                ;;
        esac
    done
}

# Función para ejecutar comandos SQL en la base de datos MySQL
function mysql_command() {
    local sql_command="$1"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "$sql_command"
}

# Función principal
function update_domains() {
    read_users
    add_domain
    echo "Actualización de dominios completada."
}

# Llamar a la función principal
update_domains
