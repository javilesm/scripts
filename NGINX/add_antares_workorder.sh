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

# Función para generar el valor del atributo "description"
function generate_description() {
    current_date=$(date +'%Y%m%d')
    consecutive=$(printf "%03d" $((++last_consecutive)))
    description="${current_date}-${consecutive}"
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

# Función principal para la interfaz de usuario
function main_dialog() {
    local t_product="8"
    local registered_domain=""
    local t_partition="xvda1"
    local fecha_inicio_vigencia="2023-01-01 00:00:00"
    local fecha_fin_vigencia="2024-01-01 00:00:00"
    local workorder_flag="1"
    local entry_status="0"

    dialog --form "Agregar registro a la tabla $db_workorder_table" 20 60 14 \
        "t_product:" 1 1 "$t_product" 1 12 10 0 \
        "registered_domain:" 2 1 "$registered_domain" 2 19 30 0 \
        "t_partition:" 3 1 "$t_partition" 3 14 10 0 \
        "Fecha inicio de vigencia:" 4 1 "$fecha_inicio_vigencia" 4 25 19 0 \
        "Fecha fin de vigencia:" 5 1 "$fecha_fin_vigencia" 5 23 19 0 \
        "workorder_flag:" 6 1 "$workorder_flag" 6 16 10 0 \
        "entry_status:" 7 1 "$entry_status" 7 15 10 0 2> /tmp/input.txt

    read -r t_product registered_domain t_partition fecha_inicio_vigencia fecha_fin_vigencia workorder_flag entry_status < /tmp/input.txt

    insert_record "$t_product" "$registered_domain" "$t_partition" "$fecha_inicio_vigencia" "$fecha_fin_vigencia" "$workorder_flag" "$entry_status" "$db_user" "$db_user"
    show_success_message
    sudo rm /tmp/input.txt

    # Mostrar la tabla después de la inserción
    dialog --msgbox "Contenido de la tabla $db_workorder_table después de la inserción:" 10 40
    show_workorder_table
}

# Inicializar el script
get_last_consecutive
main_dialog
