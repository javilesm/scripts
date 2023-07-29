#!/bin/bash
# add_domains.sh
# Variables de configuración
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
PARENT_DIR="$(dirname "$CURRENT_DIR")" # Get the parent directory of the current directory
DOMAINS_FILE="domains.csv"
CSV_FILE="$CURRENT_DIR/$DOMAINS_FILE"
TABLE_NAME="domains"

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
    read_domains
    add_domain
    echo "Actualización de dominios completada."
    read_domains
}

# Llamar a la función principal
add_domains
