#!/bin/bash
# crud_t_storage.sh

# Variables de conexión a la base de datos
db_user="2309000000"
db_password="antares1"
db_name="antares"
db_storage_table="t_storage"

# Variables globales
last_consecutive=0
description=""
create_date=""
update_date=""
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
TEMP_FILE="input.csv"
TEMP_PATH="$CURRENT_DIR/$TEMP_FILE"

# Función para verificar si MySQL está en ejecución y, si no, iniciar el servicio
function check_mysql_service() {
    if ! pgrep mysqld > /dev/null; then
        echo "MySQL no está en ejecución. Iniciando el servicio..."
        sudo service mysql start
        if [ $? -ne 0 ]; then
            echo "Error al iniciar MySQL. Verifica la configuración del servicio."
            exit 1
        fi
    fi
}

# Función para mostrar la tabla de workorders
function show_storage_dialog() {
    tmpfile=$(mktemp /tmp/workorders.XXXXXXXXXX)
    show_storage_table > "$tmpfile"
    dialog --textbox "$tmpfile" 20 60
    sudo rm -f "$tmpfile"
}

# Función para mostrar la tabla de workorders
function show_storage_table() {
    dialog --infobox "Ejecutando consulta SQL..." 10 40
    mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "SELECT * FROM $db_storage_table;" > "$tmpfile"
    dialog --infobox "Consulta SQL finalizada." 10 40
}

# Función para eliminar registros SQL
function delete_records_dialog() {
    records=$(mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "SELECT T_STORAGE, DESCRIPTION FROM $db_storage_table;")
    record_count=$(echo "$records" | wc -l)

    if [ $record_count -gt 0 ]; then
        dialog --menu "Selecciona el registro a eliminar:" 20 60 14 $records 2> /tmp/delete_choice.txt

        delete_choice=$(cat /tmp/delete_choice.txt)
        if [ -n "$delete_choice" ]; then
            delete_record "$delete_choice"
        fi
    else
        echo "No hay registros para eliminar."
    fi
}

# Función para eliminar un registro
function delete_record() {
    local record_id="$1"
    mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "DELETE FROM $db_storage_table WHERE T_STORAGE = '$record_id';"
}

# Función principal para la interfaz de usuario
function main_dialog() {
    while true; do
        dialog --menu "Menú principal" 15 40 5 \
            1 "Mostrar tabla $db_storage_table" \
            2 "Eliminar registros SQL" \
            3 "Salir" 2> /tmp/menu_choice.txt
        choice=$(cat /tmp/menu_choice.txt)

        case $choice in
            1)
                show_storage_dialog
                ;;
            2)
                delete_records_dialog
                ;;
            3)
                clear  # Limpiar la terminal
                break
                ;;
            *)
                echo "Opción no válida."
                ;;
        esac
    done
}

function manage_storage() {
    check_mysql_service
    main_dialog
}

manage_storage
