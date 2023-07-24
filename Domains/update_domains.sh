#!/bin/bash

# Variables de configuración
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
USERS_FILE="mysql_users.csv"
USERS_PATH="$PARENT_DIR/MySQL/$USERS_FILE"
TABLE_NAME="domains"
DOMAINS_FILE="domains.csv"
CSV_FILE="$CURRENT_DIR/$DOMAINS_FILE"
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
    echo "-------------------------------------------------------------"
    # Imprimir encabezados de columnas
    printf "%-20s %-20s %-20s %-20s %-15s %-10s\n" "Dominio" "Propietario" "Ciudad" "Estado" "Teléfono" "Flag"
    
    # Leer cada línea del archivo CSV y mostrar los datos en forma tabulada
    while IFS="," read -r domain owner city state phone flag || [[ -n "$domain" ]]; do
        # Imprimir datos de cada dominio en columnas
        printf "%-20s %-20s %-20s %-20s %-15s %-10s\n" "$domain" "$owner" "$city" "$state" "$phone" "$flag"
    done < <(grep -v '^$' "$CSV_FILE")
    echo "-------------------------------------------------------------"
    echo "Todos los dominios han sido leídos."
    
}

# Función para actualizar la tabla de dominios
function update_domains_table() {
    local status1="CREATE"
    local status2="IMPORTED"
    local status3="DELETE"
    echo "Actualizando la tabla de dominios..."
    while IFS="," read -r domain owner city state phone flag || [[ -n "$domain" ]]; do
        case "$flag" in
            "$status1")
                # Insertar nuevo registro y cambiar el valor de "flag" a "IMPORTED" ($status2)
                sql_command="INSERT INTO $TABLE_NAME (domain, owner, city, state, phone, flag) VALUES ('$domain', '$owner', '$city', '$state', '$phone', '$status2') ON DUPLICATE KEY UPDATE flag='$status2';"
                ;;
            "$status3")
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
    sudo mysql -u root -h "$DB_HOST" "$DB_NAME" -e "$sql_command"
}

# Función principal
function update_domains() {
    read_users
    read_domains
    update_domains_table
    echo "Actualización de dominios completada."
}

# Llamar a la función principal
update_domains
