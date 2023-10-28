#!/bin/bash
# add_workorder.sh

# Variables de conexión a la base de datos
db_user="2309000000"
db_password="antares1"
db_name="antares"
db_workorder_table="t_workorder"

# Variables globales
last_consecutive=0
description=""
create_date=""
update_date=""
TEMP_FILE="/tmp/input.txt"

# Función para generar el valor del atributo "description"
function generate_description() {
    current_date=$(date +'%Y%m%d')
    consecutive=$(printf "%03d" $((++last_consecutive)))
    description="${current_date}-${consecutive}"
}

# Función para generar el valor de T_WORKORDER (Autoincremental)
function generate_t_workorder() {
    current_t_workorder=$(mysql -u"$db_user" -p"$db_password" -D "$db_name" -e "SELECT AUTO_INCREMENT FROM information_schema.TABLES WHERE TABLE_SCHEMA = '$db_name' AND TABLE_NAME = '$db_workorder_table';" | tail -n1)
    if [ -z "$current_t_workorder" ]; then
        current_t_workorder=1
    fi
    next_t_workorder=$((current_t_workorder + 1))
}

# Función para obtener el último valor consecutivo
function get_last_consecutive() {
    last_consecutive=$(mysql -u"$db_user" -p"$db_password" -D "$db_name" -e "SELECT MAX(SUBSTRING(T_WORKORDER, -3)) FROM $db_workorder_table;" | tail -n1)
    if [ -z "$last_consecutive" ]; then
        last_consecutive=0
    fi
    current_consecutive=$((last_consecutive + 1))
}

# Función para mostrar el contenido de la tabla
function show_workorder_table() {
    mysql -u"$db_user" -p"$db_password" -D "$db_name" -e "SELECT * FROM $db_workorder_table;"
}

# Función para mostrar un mensaje de éxito
function show_success_message() {
    dialog --msgbox "Registro agregado exitosamente." 10 40
}

# Función para insertar un registro en la base de datos
function insert_record() {
    local t_product="$1"
    local registered_domain="$2"
    local t_partition="$3"
    local fecha_inicio_vigencia="$4"
    local fecha_fin_vigencia="$5"
    local workorder_flag="$6"
    local entry_status="$7"
    local create_by="$8"
    local update_by="$9"

    generate_description
    create_date=$(date +'%Y-%m-%d %H:%M:%S')
    update_date=$create_date

    mysql -u"$db_user" -p"$db_password" -D "$db_name" -e "INSERT INTO $db_workorder_table (T_WORKORDER, DESCRIPTION, T_PRODUCT, REGISTERED_DOMAIN, T_PARTITION, FECHA_INICIO_DE_VIGENCIA, FECHA_FIN_DE_VIGENCIA, WORKORDER_FLAG, ENTRY_STATUS, CREATE_DATE, CREATE_BY, UPDATE_DATE, UPDATE_BY) VALUES ('$current_consecutive', '$description', '$t_product', '$registered_domain', '$t_partition', '$fecha_inicio_vigencia', '$fecha_fin_vigencia', '$workorder_flag', '$entry_status', '$create_date', '$create_by', '$update_date', '$update_by');"
}

# Función para mostrar la previsualización de datos antes de ingresarlos
function show_preview() {
    dialog --msgbox "Previsualización de datos:\n\nT_WORKORDER (Autoincremental): $next_t_workorder\nT_WORKORDER del último registro: $last_t_workorder\nDESCRIPTION: $description\nt_product: 8\nregistered_domain: $registered_domain\nt_partition: $t_partition\nFecha inicio de vigencia: $fecha_inicio_vigencia\nFecha fin de vigencia: $fecha_fin_vigencia\nworkorder_flag: $workorder_flag\nentry_status: $entry_status" 20 60
}

# Función para mostrar el formulario de agregar registro
function show_add_record_form() {
    generate_description  # Generar el valor de "description"
    generate_t_workorder

    # Obtener el valor de "T_WORKORDER" del último registro
    last_t_workorder=$(mysql -u"$db_user" -p"$db_password" -D "$db_name" -e "SELECT MAX(T_WORKORDER) FROM $db_workorder_table;" | tail -n1)
    if [ -z "$last_t_workorder" ]; then
        last_t_workorder=0
    fi
    next_t_workorder=$((last_t_workorder + 1))

    # Variables para almacenar los datos del formulario
    t_workorder="$next_t_workorder"
    last_t_workorder="$last_t_workorder"
    t_product="8"
    registered_domain=""
    t_partition="xvda1"
    fecha_inicio_vigencia="2023-01-01 00:00:00"
    fecha_fin_vigencia="2024-01-01 00:00:00"
    workorder_flag="1"
    entry_status="0"

    # Mostrar el formulario para ingresar los datos
    dialog --form "Agregar registro a la tabla $db_workorder_table" 20 60 14 \
        "T_WORKORDER (Autoincremental):" 1 1 "$t_workorder" 1 40 10 0 \
        "T_WORKORDER del último registro:" 2 1 "$last_t_workorder" 2 40 10 0 \
        "DESCRIPTION:" 3 1 "$description" 3 40 30 0 \
        "t_product:" 4 1 "$t_product" 4 40 10 0 \
        "registered_domain:" 5 1 "$registered_domain" 5 40 30 0 \
        "t_partition:" 6 1 "$t_partition" 6 40 10 0 \
        "Fecha inicio de vigencia:" 7 1 "$fecha_inicio_vigencia" 7 40 19 0 \
        "Fecha fin de vigencia:" 8 1 "$fecha_fin_vigencia" 8 40 19 0 \
        "workorder_flag:" 9 1 "$workorder_flag" 9 40 10 0 \
        "entry_status:" 10 1 "$entry_status" 10 40 10 0 2> "$TEMP_FILE"

    # Leer los datos ingresados por el usuario
    read -r t_workorder last_t_workorder description t_product registered_domain t_partition fecha_inicio_vigencia fecha_fin_vigencia workorder_flag entry_status < "$TEMP_FILE"

    # Mostrar la previsualización de los datos con los valores ingresados
    previsualizacion="T_WORKORDER (Autoincremental): $t_workorder\nT_WORKORDER del último registro: $last_t_workorder\nDESCRIPTION: $description\nt_product: $t_product\nregistered_domain: $registered_domain\nt_partition: $t_partition\nFecha inicio de vigencia: $fecha_inicio_vigencia\nFecha fin de vigencia: $fecha_fin_vigencia\nworkorder_flag: $workorder_flag\nentry_status: $entry_status"
    dialog --msgbox "$previsualizacion" 20 60

    # Confirmar inserción
    dialog --yesno "¿Deseas agregar estos registros?" 7 40
    response=$?

    if [ $response -eq 0 ]; then
        insert_record "$t_workorder" "$description" "$t_product" "$registered_domain" "$t_partition" "$fecha_inicio_vigencia" "$fecha_fin_vigencia" "$workorder_flag" "$entry_status" "$db_user" "$db_user"
        show_success_message
    fi

    sudo rm "$TEMP_FILE"
}

# Función para mostrar la tabla de workorders
function show_workorder_dialog() {
    tmpfile=$(mktemp /tmp/workorders.XXXXXXXXXX)
    show_workorder_table > "$tmpfile"
    dialog --textbox "$tmpfile" 20 60
    rm -f "$tmpfile"
}


# Función principal para la interfaz de usuario
function main_dialog() {
    while true; do
        dialog --menu "Menú principal" 15 40 4 \
            1 "Agregar nuevo registro" \
            2 "Mostrar tabla $db_workorder_table" \
            3 "Salir" 2> /tmp/menu_choice.txt

        choice=$(cat /tmp/menu_choice.txt)

        case $choice in
            1)
                show_add_record_form
                ;;
            2)
                show_workorder_dialog
                ;;
            3)
                clear  # Limpiar la terminal
                break
                ;;
        esac
    done
}


# Inicializar el script
get_last_consecutive
main_dialog
