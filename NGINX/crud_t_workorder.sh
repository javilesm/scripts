#!/bin/bash
# add_workorder.sh

# Variables de conexión a la base de datos
db_user="2309000000"
db_password="antares1"
db_name="antares"
db_table="t_workorder"

# Variables globales
last_consecutive=0
description=""
create_date=""
update_date=""
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
TEMP_FILE="input.csv"
TEMP_PATH="$CURRENT_DIR/$TEMP_FILE"

# Función para cambiar la propiedad del directorio $CURRENT_DIR al usuario actual
function change_directory_ownership_to_user() {
    dialog --infobox  "Cambiando la propiedad del directorio '$CURRENT_DIR' al usuario actual..." 10 40
    sleep 2
    # Obtiene el nombre de usuario actual
    current_user=$(whoami)

    # Cambia la propiedad del directorio al usuario actual
    sudo chown -R "$current_user:$current_user" "$CURRENT_DIR"

    if [ $? -eq 0 ]; then
        dialog --infobox "Propiedad del directorio cambiada a '$current_user'." 10 40
        sleep 2
        sudo touch "$TEMP_PATH"
        if [ $? -eq 0 ]; then
            dialog --infobox "El archivo '$TEMP_PATH' ha sido creado." 10 40
            sleep 2
        else
            dialog --infobox "Error al crear el archivo '$TEMP_PATH'." 10 40
            sleep 2
        fi
    else
        dialog --infobox "Error al cambiar la propiedad del directorio a '$current_user.'" 10 40
        sleep 2
    fi
}


# Función para comprobar las variables de conexión a la base de datos
function check_db_variables() {
    dialog --infobox "Comprobando variables de conexión a la base de datos..." 10 40
    sleep 2

    # Comprobar la variable db_name
    dialog --msgbox "Comprobando la existencia de la base de datos '$db_name'. Presione enter para comprobar..." 10 40
    sleep 1
    if ! sudo mysql -e "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = '$db_name';" > /dev/null 2>&1; then
        dialog --msgbox "ERROR: No se pudo conectar a la base de datos con el nombre de base de datos '$db_name'. Verifica la variable db_name." 10 40
        exit 1
    fi
    dialog --msgbox "La base de datos '$db_name' existe. Presione enter para continuar..." 10 40

    # Comprobar la variable db_table
    dialog --msgbox "Comprobando la existencia de la tabla '$db_table' en la base de datos '$db_name'. Presione enter para comprobar..." 10 40
    sleep 1
    if ! sudo mysql -e "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = '$db_name' AND TABLE_NAME = '$db_table';" > /dev/null 2>&1; then
        dialog --msgbox "ERROR: La tabla '$db_table' no se encuentra en la base de datos especificada. Verifica la variable '$db_table'." 10 40
        exit 1
    fi
    dialog --msgbox "La tabla '$db_table' existe en la base de datos '$db_name' existe. Presione enter para continuar..." 10 40

    # Comprobar la variable db_user
    dialog --msgbox "Comprobando la existencia del usuario '$db_user'. Presione enter para comprobar..." 10 40
    sleep 1
    if ! sudo mysql -e "SELECT user FROM mysql.user WHERE user = '$db_user';" > /dev/null 2>&1; then
        dialog --msgbox "ERROR: No se encontro al usuario '$db_user'. Verifica la variable db_user." 10 40
        exit 1
    fi
    dialog --msgbox "El usuario '$db_user' existe. Presione enter para continuar..." 10 40

    # Comprobar la variable db_password
    dialog --msgbox "Comprobando la conexion a la base de datos '$db_name' con el usuario '$db_user'. Presione enter para comprobar..." 10 40
    sleep 1
    if ! mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "SELECT 1;" > /dev/null 2>&1; then
        dialog --msgbox "ERROR: No se pudo conectar a la base de datos con la contraseña proporcionada. Verifica la variable db_password." 10 40
        exit 1
    fi
    dialog --msgbox "Es posible conectar a la base de datos '$db_name' con el usuario '$db_user'. Presione enter para continuar..." 10 40

    dialog --msgbox "Variables de conexión a la base de datos comprobadas correctamente. Conexiones exitosas." 10 40
}

# Función para generar el valor del atributo "description"
function generate_description() {
    current_date=$(date +'%Y%m%d')
    consecutive=$(printf "%03d" $((++last_consecutive)))
    description="${current_date}-${consecutive}"
}

# Función para generar el valor de T_WORKORDER (Autoincremental)
function generate_t_workorder() {
    current_t_workorder=$(mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "SELECT AUTO_INCREMENT FROM information_schema.TABLES WHERE TABLE_SCHEMA = '$db_name' AND TABLE_NAME = '$db_table';" | tail -n1)
    dialog --msgbox "Último registro de T_WORKORDER: $current_t_workorder" 10 40
    if [ -z "$current_t_workorder" ]; then
        current_t_workorder=1
    fi
    next_t_workorder=$((current_t_workorder + 1))
}

function get_last_consecutive() {
    last_consecutive=$(mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "SELECT MAX(T_WORKORDER) FROM $db_table;" | tail -n1)
    dialog --msgbox "Último registro de T_WORKORDER: $last_consecutive" 10 40
    if [ -z "$last_consecutive" ]; then
        last_consecutive=0
    fi
    current_consecutive=$((last_consecutive + 1))
}


# Función para mostrar el contenido de la tabla
function show_workorder_table() {
    dialog --infobox "Ejecutando consulta SQL..." 10 40
    mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "SELECT * FROM $db_table;" > "$tmpfile"
    dialog --infobox "Consulta SQL finalizada." 10 40
}

# Función para mostrar un mensaje de éxito
function show_success_message() {
    dialog --msgbox "Registro agregado exitosamente." 10 40
}

# Función para eliminar el archivo temporal
function delete_temp_file() {
    dialog --infobox "Eliminando el archivo temporal '$TEMP_PATH'..." 10 40
    sudo rm -f "$TEMP_PATH"
}

# Función para mostrar el formulario de agregar registro
# Función para mostrar el formulario de agregar registro
function show_add_record_form() {
    generate_description  # Generar el valor de "description"
    get_last_consecutive

    # Variables por default para almacenar los datos del formulario
    t_product="8"
    registered_domain=""
    t_partition="xvda1"
    fecha_inicio_vigencia="2023-01-01 00:00:00"
    fecha_fin_vigencia="2024-01-01 00:00:00"
    workorder_flag="1"
    entry_status="0"
    create_date=$(date +'%Y-%m-%d %H:%M:%S')
    create_by="$db_user"  # Asigna el valor por defecto o el que corresponda
    update_date=$create_date
    update_by="$db_user"  # Asigna el valor por defecto o el que corresponda

    # Mostrar el valor vigente de "description" en el formulario
    dialog --form "Agregar registro a la tabla $db_table" 20 60 14 \
        "T_WORKORDER (Autoincremental):" 1 1 "$current_consecutive" 1 30 10 0 \
        "DESCRIPTION:" 2 1 "$description" 2 30 30 0 \
        "t_product:" 3 1 "$t_product" 3 30 10 0 \
        "registered_domain:" 4 1 "$registered_domain" 4 30 30 0 \
        "t_partition:" 5 1 "$t_partition" 5 30 10 0 \
        "Fecha inicio de vigencia:" 6 1 "$fecha_inicio_vigencia" 6 30 19 0 \
        "Fecha fin de vigencia:" 7 1 "$fecha_fin_vigencia" 7 30 19 0 \
        "workorder_flag:" 8 1 "$workorder_flag" 8 30 10 0 \
        "entry_status:" 9 1 "$entry_status" 9 30 10 0 \
        "create_date:" 10 1 "$create_date" 10 30 19 0 \
        "create_by:" 11 1 "$create_by" 11 30 10 0 \
        "update_date:" 12 1 "$update_date" 12 30 19 0 \
        "update_by:" 13 1 "$update_by" 13 30 10 0 2> "$TEMP_PATH"

    if [ $? -eq 0 ]; then
        # El usuario no canceló el formulario, proceder con la previsualización y confirmación
        preview_and_confirm
    else
        # El usuario canceló el formulario
        dialog --msgbox "Ingreso de datos cancelado." 10 40
    fi
}


function preview_and_confirm() {
    # Mostrar la previsualización de los datos con los valores ingresados
    previsualizacion=$(cat "$TEMP_PATH")
    dialog --msgbox "Previsualización de datos:\n\n$previsualizacion" 20 60

    if [ -s "$TEMP_PATH" ]; then
        # Confirmar inserción
        dialog --yesno "¿Deseas agregar estos registros?" 7 40
        response=$?

        if [ $response -eq 0 ]; then
            data_file="$TEMP_PATH"
            query_values=""
            while IFS= read -r line; do
                query_values="$query_values'$line', "
            done < "$data_file"

            # Elimina la coma y el espacio extra al final de la cadena
            query_values="${query_values%, }"
            preload_sql_query "$query_values"
            show_success_message
        fi
    else
        dialog --msgbox "El archivo temporal no existe. No se puede continuar." 10 40
    fi
}


# Función para insertar un registro en la base de datos
function preload_sql_query() {
    local t_workorder="$1"
    local description="$2"
    local t_product="$3"
    local registered_domain="$4"
    local t_partition="$5"
    local fecha_inicio_vigencia="$6"
    local fecha_fin_vigencia="$7"
    local workorder_flag="$8"
    local entry_status="$9"
    local create_date="${10}"
    local create_by="${11}"
    local update_date="${12}"
    local update_by="${13}"

    SQL_INTERT_QUERY="INSERT INTO $db_table (T_WORKORDER, DESCRIPTION, T_PRODUCT, REGISTERED_DOMAIN, T_PARTITION, FECHA_INICIO_DE_VIGENCIA, FECHA_FIN_DE_VIGENCIA, WORKORDER_FLAG, ENTRY_STATUS, CREATE_DATE, CREATE_BY, UPDATE_DATE, UPDATE_BY) VALUES ($query_values);"
        # Confirmar inserción
        dialog --yesno "¿Deseas ejecutar el siguiente query?: '$SQL_INTERT_QUERY'" 7 40
        response=$?

        if [ $response -eq 0 ]; then
            insert_record "$SQL_INTERT_QUERY"
            show_success_message
        fi
}

# Función para insertar un registro en la base de datos
function insert_record() {
    mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "$SQL_INTERT_QUERY"
}

# Función para mostrar la tabla de workorders
function show_workorder_dialog() {
    tmpfile=$(mktemp /tmp/workorders.XXXXXXXXXX)
    show_workorder_table > "$tmpfile"
    dialog --textbox "$tmpfile" 20 60
    sudo rm -f "$tmpfile"
}

# Función para eliminar registros SQL
function delete_records_dialog() {
    records=$(mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "SELECT T_WORKORDER, DESCRIPTION FROM $db_table;")
    record_count=$(dialog --infobox "$records" | wc -l)

    if [ $record_count -gt 0 ]; then
        dialog --menu "Selecciona el registro a eliminar:" 20 60 14 $records 2> /tmp/delete_choice.txt

        delete_choice=$(cat /tmp/delete_choice.txt)
        if [ -n "$delete_choice" ]; then
            confirm_delete "$delete_choice"
        fi
    else
        dialog --msgbox "No hay registros para eliminar." 10 40
    fi
}

# Función para confirmar la eliminación de un registro
function confirm_delete() {
    local record_id="$1"
    dialog --yesno "¿Estás seguro de que deseas eliminar el registro con T_WORKORDER $record_id?" 7 40

    response=$?
    if [ $response -eq 0 ]; then
        delete_record "$record_id"
        dialog --msgbox "Registro eliminado con éxito." 10 40
    fi
}

# Función para eliminar un registro
function delete_record() {
    local record_id="$1"
    mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "DELETE FROM $db_table WHERE T_WORKORDER = '$record_id';"
}

# Función para actualizar un registro en la tabla t_workorder
function update_records() {
    # Obtener la lista de registros actuales
    records=$(mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "SELECT T_WORKORDER, DESCRIPTION FROM $db_table;")
    
    if [ -z "$records" ]; then
        dialog --msgbox "No hay registros disponibles para actualizar." 10 40
        return
    fi

    # Mostrar los registros actuales y pedir al usuario que elija uno
    dialog --menu "Selecciona el registro que deseas modificar (T_WORKORDER - DESCRIPCIÓN):" 20 60 14 $records 2> /tmp/update_choice.txt
    record_choice=$(cat /tmp/update_choice.txt)

    if [ -z "$record_choice" ]; then
        dialog --msgbox "No se ha seleccionado ningún registro para actualizar." 10 40
        return
    fi

    # Dividir la elección del usuario en T_WORKORDER y DESCRIPCIÓN
    IFS="-" read -r t_workorder current_description <<< "$record_choice"

    # Mostrar un formulario para editar la descripción
    dialog --form "Editar Registro (T_WORKORDER: $t_workorder)" 20 60 4 \
        "Nueva Descripción:" 1 1 "$current_description" 1 30 30 0 2> /tmp/update_values.txt
    
    new_description=$(cat /tmp/update_values.txt)

    # Actualizar la descripción en la base de datos
    mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "UPDATE $ SET DESCRIPTION = '$new_description' WHERE t_workorder = $t_workorder;"

    dialog --msgbox "Registro actualizado con éxito." 10 40
}

# Función principal para la interfaz de usuario
function main_dialog() {
    while true; do
        dialog --menu "CRUD $db_table" 15 40 5 \
            1 "Crear un nuevo registro" \
            2 "Leer registros" \
            3 "Actualizar registros" \
            4 "Eliminar registros" \
            5 "Eliminar archivo temporal" \
            6 "Salir" 2> /tmp/menu_choice.txt

        choice=$(cat /tmp/menu_choice.txt)

        case $choice in
            1)
                show_add_record_form  # Llama a la función para agregar un nuevo registro
                ;;
            2)
                show_workorder_dialog
                ;;
            3)
                update_records
                ;;
            4)
                delete_records_dialog  # Llama a la función para eliminar registros SQL
                ;;
            5)
                delete_temp_file
                dialog --msgbox "Archivo temporal eliminado." 10 40
                ;;
            6)
                clear  # Limpiar la terminal
                break
                ;;
            *)
                echo "Opción no válida."
                ;;
        esac
    done
}

# Función para verificar si MySQL está en ejecución y, si no, iniciar el servicio
function check_mysql_service() {
    dialog --infobox "Comprobando si MySQL está en ejecución..." 10 40
    sleep 2
    if pgrep mysqld > /dev/null; then
        dialog --infobox "MySQL ya está en ejecución." 10 40
    else
        dialog --infobox "MySQL no está en ejecución. Iniciando el servicio..." 10 40
        sudo service mysql start  # Puedes cambiar "mysql" por el nombre del servicio de MySQL en tu sistema
        if [ $? -eq 0 ]; then
            dialog --infobox "MySQL iniciado con éxito." 10 40
        else
            dialog --infobox "Error al iniciar MySQL. Verifica la configuración del servicio." 10 40
            exit 1
        fi
    fi
    sleep 2
}

function add_workorder() {
    change_directory_ownership_to_user
    check_mysql_service
    delete_temp_file
    check_db_variables
    main_dialog
}

add_workorder
