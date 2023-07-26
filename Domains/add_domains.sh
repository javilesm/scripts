#!/bin/bash
# add_domains.sh
# Variables de configuración
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
PARENT_DIR="$(dirname "$CURRENT_DIR")" # Get the parent directory of the current directory
DOMAINS_FILE="domains.csv"
CSV_FILE="$CURRENT_DIR/$DOMAINS_FILE"
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

# Función para leer los dominios del archivo CSV y mostrarlos en forma tabulada
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

# Función para agregar un nuevo registro a la tabla de dominios en el archivo CSV
function add_domain() {
    flag="CREATE"
    while true; do
        read -p "¿Desea agregar un nuevo registro? (S/N): " choice
        case "$choice" in
            [sS])
                read -p "Dominio: " domain
                read -p "Propietario: " owner
                read -p "Ciudad: " city
                read -p "Estado: " state
                read -p "Teléfono: " phone
                
                # Agregar el nuevo registro al archivo CSV
                echo "$domain,$owner,$city,$state,$phone,$flag" >> "$CSV_FILE"
                
                ;;
            *)
                echo "No se agregará un nuevo registro."
                return
                ;;
        esac
    done
    echo "Todos los cambios han sido registrados."
    echo "Los cambios en la base de datos pueden demorar hasta 24 horas."
}

# Función principal
function add_domains() {
    read_users
    read_domains
    add_domain
    echo "Actualización de dominios completada."
    read_domains
}

# Llamar a la función principal
add_domains
