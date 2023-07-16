#!/bin/bash

# Variables de configuración
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
DOMAINS_FILE="domains.csv"
CSV_FILE="$CURRENT_DIR/$DOMAINS_FILE"
USERS_FILE="mysql_users.csv"
USERS_PATH="$CURRENT_DIR/MySQL/$USERS_FILE"
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

# Función para actualizar la tabla de dominios
function update_domains_table() {
    echo "Actualizando la tabla de dominios..."
    while IFS="," read -r domain owner city state phone flag || [[ -n "$domain" ]]; do
        case "$flag" in
            "CREATE")
                # Insertar nuevo registro
                sql_command="INSERT INTO $TABLE_NAME (domain, owner, city, state, phone) VALUES ('$domain', '$owner', '$city', '$state', '$phone');"
                ;;
            "DELETE")
                # Eliminar registro existente
                sql_command="DELETE FROM $TABLE_NAME WHERE domain='$domain';"
                ;;
            *)
                # Acción no reconocida
                echo "Acción no reconocida para el dominio '$domain'."
                continue
                ;;
        esac

        mysql_command "$sql_command"
    done < <(grep -v '^$' "$CSV_FILE")
}

# Función para ejecutar comandos SQL en la base de datos MySQL
function mysql_command() {
    local sql_command="$1"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "$sql_command"
}

# Función principal
function update_domains() {
    read_users
    update_domains_table
    echo "Actualización de dominios completada."
}

# Llamar a la función principal
update_domains
