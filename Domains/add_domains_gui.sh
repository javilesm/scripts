#!/bin/bash
# add_domains_gui.sh
# Variables de configuración
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
PARENT_DIR="$(dirname "$CURRENT_DIR")" # Get the parent directory of the current directory
DOMAINS_DIR="forms"
ENDPOINT="$CURRENT_DIR/$DOMAINS_DIR"     # Directorio donde se almacenarán los archivos CSV
CSV_FILE="domains.csv"
CSV_PATH="$CURRENT_DIR/$CSV_FILE"
CSV_PREFIX="form_"  # Variable para el prefijo del nombre de los archivos CSV
LOG_FILE="$ENDPOINT/forms_log.txt" # Archivo de log
# Función para comprobar y crear el directorio de dominios si no existe
function ensure_ENDPOINTectory() {
    # comprobar y crear el directorio de dominios si no existe
    echo "Comprobando y crear el Endpoint si no existe..."
    if [ ! -d "$ENDPOINT" ]; then
       sudo mkdir -p "$ENDPOINT"
    fi
    echo "El Endpoint '$ENDPOINT' existe." 
}

# Función para obtener el último consecutivo utilizado
function get_last_consecutive() {
    local last_consecutive=$(ls "$ENDPOINT" | grep -oP "(?<=^${CSV_PREFIX})\d+(?=.csv$)" | sort -n | tail -1)
    echo "$last_consecutive"
}

# Función para obtener el siguiente consecutivo disponible
function get_next_consecutive() {
    local last_consecutive=$(get_last_consecutive)
    if [[ -z "$last_consecutive" ]]; then
        echo "00001"
    else
        printf "%05d" "$((10#$last_consecutive + 1))"
    fi
}

# Función para limpiar las variables y salir
function cleanup() {
    unset domain
    unset owner
    unset city
    unset state
    unset phone
    clear   # Autoclear de la terminal al salir del script
    exit
}

# Función para mostrar el menú principal
function show_main_menu() {
    dialog --clear --colors --backtitle "Gestión de Dominios" --title "Menú Principal" --menu "Seleccione una opción:" 15 50 5 \
        1 "Mostrar Dominios" \
        2 "Agregar Dominio" \
        3 "Salir" 2>/tmp/add_domains_gui_choice
}

# Función para mostrar el formulario de agregar dominio
function show_add_domain_form() {
    dialog --clear --colors --backtitle "Gestión de Dominios" --title "Agregar Dominio" \
        --form "Complete los detalles del dominio:" 15 50 5 \
        "Dominio:" 1 1 "$domain" 1 10 50 0 \
        "Propietario:" 2 1 "$owner" 2 13 50 0 \
        "Ciudad:" 3 1 "$city" 3 10 50 0 \
        "Estado:" 4 1 "$state" 4 10 50 0 \
        "Teléfono:" 5 1 "$phone" 5 12 50 0 2> /tmp/add_domains_gui_form

    # Leer los datos ingresados por el usuario en el formulario y almacenarlos en variables
    mapfile -t form_data < /tmp/add_domains_gui_form
    domain="${form_data[0]}"
    owner="${form_data[1]}"
    city="${form_data[2]}"
    state="${form_data[3]}"
    phone="${form_data[4]}"
}

# Función para leer los dominios del archivo CSV y mostrarlos en forma tabulada
function read_domains() {
    echo "Leyendo la lista de dominios: '$CSV_PATH'..."
    echo "-------------------------------------------------------------"
    # Imprimir encabezados de columnas
    printf "%-20s %-20s %-20s %-20s %-15s %-10s\n" "Dominio" "Propietario" "Ciudad" "Estado" "Teléfono" "Flag"
    
    # Leer cada línea del archivo CSV y mostrar los datos en forma tabulada
    while IFS="," read -r domain owner city state phone flag || [[ -n "$domain" ]]; do
        # Imprimir datos de cada dominio en columnas
        printf "%-20s %-20s %-20s %-20s %-15s %-10s\n" "$domain" "$owner" "$city" "$state" "$phone" "$flag"
    done < <(grep -v '^$' "$CSV_PATH")
    echo "-------------------------------------------------------------"
    echo "Todos los dominios han sido leídos."
    
    # Pausa para permitir al usuario ver la lista de dominios
    read -n 1 -s -r -p "Presione Enter para continuar..."
}

# Función para confirmar el registro de los datos ingresados
function confirm_registration() {
    dialog --clear --colors --backtitle "Gestión de Dominios" --title "Confirmación" \
        --yesno "¿Desea registrar el siguiente dominio?\n\nDominio: $domain\nPropietario: $owner\nCiudad: $city\nEstado: $state\nTeléfono: $phone" 12 60

    # $? contiene el código de retorno del comando anterior (0 si se selecciona "Yes", 1 si se selecciona "No")
    return $?
}

# Función para escribir los datos en un nuevo archivo CSV
function write_to_new_csv() {
    flag="CREATE"
    local new_consecutive=$(get_next_consecutive)
    local new_CSV_PATH="$ENDPOINT/${CSV_PREFIX}${new_consecutive}.csv"
    new_record="$CSV_PREFIX$new_consecutive,$domain,$owner,$city,$state,$phone,$flag"
    echo "$new_record" > "$new_CSV_PATH"
    write_to_log  # Llamada a la función para escribir en el log
}

# Función para escribir en el archivo de log
function write_to_log() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp | $CSV_PREFIX$new_consecutive | Dominio: $domain, Propietario: $owner, Ciudad: $city, Estado: $state, Teléfono: $phone, Status:$flag" >> "$LOG_FILE"
}

# Función principal
function add_domains_gui() {
    # Comprobar y crear el directorio de dominios si no existe
    ensure_ENDPOINTectory

    while true; do
        show_main_menu
        menu_choice=$(<"/tmp/add_domains_gui_choice")
        case $menu_choice in
            1) # Mostrar Dominios
                read_domains
                ;;
            2) # Agregar Dominio
                show_add_domain_form

                # Confirmar el registro de los datos ingresados
                confirm_registration
                confirm_result=$?

                if [ $confirm_result -eq 0 ]; then
                    # Se seleccionó "Yes", escribir los datos en un nuevo archivo CSV
                    write_to_new_csv
                    dialog --clear --colors --backtitle "Gestión de Dominios" --title "Mensaje" --msgbox "Nuevo dominio agregado exitosamente." 7 50
                fi
                ;;
            3) # Salir
                cleanup
                ;;
        esac
    done
}

# Llamar a la función principal
add_domains_gui
