#!/bin/bash
# delete_domains.sh
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

#  Función para marcar un registro de dominio como "DELETE" en el archivo CSV
function delete_domain() {
    echo "Marcar un registro de dominio como 'DELETE':"
    read -p "Ingrese el dominio que desea marcar como 'DELETE': " domain_to_mark

    # Verificar si el dominio a marcar como "DELETE" existe en el archivo CSV
    if ! grep -q "^$domain_to_mark," "$CSV_FILE"; then
        echo "El dominio '$domain_to_mark' no existe en la lista de dominios."
        return
    fi

    # Confirmar la acción antes de continuar
    read -p "¿Está seguro de que desea marcar el dominio '$domain_to_mark' como 'DELETE'? (S/N): " confirm
    case "$confirm" in
        [sS])
            # Crear un archivo temporal para almacenar los registros con el cambio
            tmp_file=$(mktemp)

            # Utilizar awk para marcar el dominio a "DELETE" en el archivo CSV
            awk -F ',' -v OFS=',' -v markdomain="$domain_to_mark" '{
                if ($1 == markdomain) {
                    $6 = "DELETE";   # Cambiar el valor del campo "flag" a "DELETE"
                }
                print $0;   # Imprimir la línea modificada o no modificada
            }' "$CSV_FILE" > "$tmp_file"

            # Reemplazar el archivo original con el archivo temporal (efectuando el cambio)
            mv "$tmp_file" "$CSV_FILE"
            echo "Se marcó el dominio '$domain_to_mark' como 'DELETE' correctamente."
            ;;
        *)
            echo "No se realizó ningún cambio."
            ;;
    esac
}

# Función para devolver la propiedad del archivo CSV_FILE al usuario
function restore_ownership() {
    echo "Devolviendo la propiedad del archivo '$CSV_FILE' al usuario..."
    sudo chown $(whoami) "$CSV_FILE"
    echo "La propiedad del archivo '$CSV_FILE' ha sido devuelta al usuario correctamente."
}
# Función principal
function delete_domains() {
    read_users
    read_domains
    delete_domain
    echo "Actualización de dominios completada."
    read_domains
    restore_ownership
}

# Llamar a la función principal
delete_domains
