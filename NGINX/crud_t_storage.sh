#!/bin/bash
# crud_storage.sh

# Variables de conexión a la base de datos
db_user="2309000000"
db_password="antares1"
db_name="antares"
db_table="t_storage"

# Variables globales
last_consecutive=0
description=""
create_date=""
update_date=""
DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
TEMP_FILE="crud_storage_input.csv"
TEMP_PATH="$DIR/$TEMP_FILE"

# Función para cambiar la propiedad del directorio $DIR al usuario actual
function change_directory_ownership_to_user() {
    dialog --infobox  "Cambiando la propiedad del directorio '$DIR' al usuario actual..." 10 40
    sleep 2
    # Obtiene el nombre de usuario actual
    user=$(whoami)

    # Cambia la propiedad del directorio al usuario actual
    sudo chown -R "$user:$user" "$DIR"

    if [ $? -eq 0 ]; then
        dialog --infobox "Propiedad del directorio cambiada a '$user'." 10 40
        sleep 1

    else
        dialog --infobox "Error al cambiar la propiedad del directorio a '$user.'" 10 40
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

function get_last_consecutive() {
    last_consecutive=$(mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "SELECT MAX(T_STORAGE) FROM $db_table;" | tail -n1)
    dialog --msgbox "Último registro en la tabla $db_table: $last_consecutive" 10 40
    if [ -z "$last_consecutive" ]; then
        last_consecutive=0
    fi
    consecutive=$((last_consecutive + 1))
}

# Función para mostrar la tabla de storage
function show_storage_table() {
    dialog --infobox "Ejecutando consulta SQL..." 10 40
    mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "SELECT * FROM $db_table;" > "$tmpfile"
    dialog --infobox "Consulta SQL finalizada." 10 40
}

# Función para eliminar el archivo temporal
function delete_temp_file() {
    dialog --msgbox "Eliminando el archivo temporal '$TEMP_PATH'..." 10 40
    sleep 1
    sudo rm -f "$TEMP_PATH"
}

# Función para mostrar el formulario de agregar registro
function show_add_record_form() {
    get_last_consecutive

    # Variables por default para almacenar los datos del formulario
    short_description=""
    device_name=""
    instance_attachment_point=""
    volume_size=""
    committed_size=""
    volume_type=""
    iops="3000"
    encrypted=""
    delete_on_termination=""
    instance=""
    storage_flag=""
    entry_status="0"
    create_date=$(date +'%Y-%m-%d %H:%M:%S')
    create_by="$db_user"  # Asigna el valor por defecto o el que corresponda
    update_date=$create_date
    update_by="$db_user"  # Asigna el valor por defecto o el que corresponda

    # Mostrar el formulario con valores actuales y campos de texto para modificarlos
    dialog --form "Agregar registro a la tabla $db_table" 20 60 14 \
        "T_STORAGE (Autoincremental):" 1 1 "$consecutive" 1 30 10 0 \
        "SHORT_DESCRIPTION:" 2 1 "$short_description" 2 30 30 0 \
        "DEVICE_NAME:" 3 1 "$device_name" 3 30 10 0 \
        "INSTANCE_ATTACHMENT_POINT:" 4 1 "$instance_attachment_point" 4 30 30 0 \
        "VOLUME_SIZE:" 5 1 "$volume_size" 5 30 50 0 \
        "COMMITTED_SIZE:" 6 1 "$committed_size" 6 30 50 0 \
        "VOLUME_TYPE:" 7 1 "$volume_type" 7 30 50 0 \
        "IOPS:" 8 1 "$iops" 8 30 50 0 \
        "ENCRYPTED:" 9 1 "$encrypted" 9 30 50 0 \
        "DELETE_ON_TERMINATION:" 10 1 "$delete_on_termination" 10 30 50 0 \
        "INSTANCE:" 11 1 "$instance" 11 30 50 0 \
        "STORAGE_FLAG:" 12 1 "$storage_flag" 12 30 50 0 \
        "entry_status:" 13 1 "$entry_status" 13 30 10 0 \
        "create_date:" 14 1 "$create_date" 14 30 19 0 \
        "create_by:" 15 1 "$create_by" 15 30 10 0 \
        "update_date:" 16 1 "$update_date" 16 30 19 0 \
        "update_by:" 17 1 "$update_by" 17 30 10 0 2> "$TEMP_PATH"

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
    local t_storage="$1"
    local short_description="$2"
    local device_name="$3"
    local intance_attachment_point="$4"
    local volume_size="$5"
    local committed_size="$6"
    local volume_type="$7"
    local iops="$8"
    local encrypted="$9"
    local delete_on_termination="${10}"
    local instance="${11}"
    local storage_flag="${12}"
    local entry_status="${13}"
    local create_date="${14}"
    local create_by="${15}"
    local update_date="${16}"
    local update_by="${17}"

    SQL_UPDATE_QUERY="UPDATE $db_table (T_STORAGE, SHORT_DESCRIPTION, DEVICE_NAME, INTANCE_ATTACHMENT_POINT, VOLUME_SIZE, COMMITED_SIZE, VOLUME_TYPE, IOPS, ENCRYPTED, DELETE_ON_TERMINATION, INSTANCE, STORAGE_FLAG, ENTRY_STATUS, CREATE_DATE, CREATE_BY, UPDATE_DATE, UPDATE_BY) SET ($query_values) WHERE T_STORAGE = $t_storage;"
        # Confirmar inserción
        dialog --yesno "¿Deseas ejecutar el siguiente query?: '$SQL_UPDATE_QUERY'" 7 40
        response=$?

        if [ $response -eq 0 ]; then
            insert_record "$SQL_UPDATE_QUERY"
            show_success_message
        fi
}

# Función para insertar un registro en la base de datos
function insert_record() {
    mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "$SQL_UPDATE_QUERY"
}

# Función para mostrar un mensaje de éxito
function show_success_message() {
    dialog --msgbox "Registro actualizado exitosamente." 10 40
}

# Función para mostrar la tabla de storage
function show_storage_dialog() {
    tmpfile=$(mktemp /tmp/storage.XXXXXXXXXX)
    show_storage_table > "$tmpfile"
    dialog --textbox "$tmpfile" 20 60
    sudo rm -f "$tmpfile"
}

# Función para eliminar registros SQL
function delete_records_dialog() {
    records=$(mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "SELECT T_STORAGE, DESCRIPTION FROM $db_table;")
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
    dialog --yesno "¿Estás seguro de que deseas eliminar el registro con T_STORAGE $record_id?" 7 40

    response=$?
    if [ $response -eq 0 ]; then
        delete_record "$record_id"
        dialog --msgbox "Registro eliminado con éxito." 10 40
    fi
}

# Función para eliminar un registro
function delete_record() {
    local record_id="$1"
    mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "DELETE FROM $db_table WHERE T_STORAGE = '$record_id';"
}

# Función para mostrar el formulario de actualización de un registro
function show_update_record_form() {
    # Dividir la cadena full_record en partes usando comas como separadores
    IFS=',' read -r t_storage short_description device_name instance_attachment_point volume_size committed_size volume_type iops encrypted delete_on_termination instance storage_flag entry_status create_date create_by update_date update_by <<< "$1"

    updated_short_description=""
    updated_device_name=""
    updated_instance_attachment_point=""
    updated_volume_size=""
    updated_committed_size=""
    updated_volume_type=""
    updated_iops=""
    updated_encrypted=""
    updated_delete_on_termination=""
    updated_instance=""
    updated_storage_flag=""

    # Resto del código de la función, sin cambios en la parte de mostrar el formulario
    dialog --form "Editando el registro: $t_storage" 30 100 14 \
        "T_STORAGE (Autoincremental):" 1 1 "$t_storage" 1 30 10 0 \
        "SHORT_DESCRIPTION:" 2 1 "$short_description" 2 30 50 0 "Updated SHORT_DESCRIPTION:" 2 51 "$updated_short_description" 2 80 50 0 \
        "DEVICE_NAME:" 3 1 "$device_name" 3 30 50 0 "Updated DEVICE_NAME:" 3 51 "$updated_device_name" 3 80 50 0 \
        "INSTANCE_ATTACHMENT_POINT:" 4 1 "$instance_attachment_point" 4 30 50 0 "Updated INSTANCE_ATTACHMENT_POINT:" 4 51 "$updated_instance_attachment_point" 4 80 50 0 \
        "VOLUME_SIZE:" 5 1 "$volume_size" 5 30 50 0 "Updated VOLUME_SIZE:" 5 51 "$updated_volume_size" 5 80 50 0 \
        "COMMITTED_SIZE:" 6 1 "$committed_size" 6 30 50 0 "Updated COMMITTED_SIZE:" 6 51 "$updated_committed_size" 6 80 50 0 \
        "VOLUME_TYPE:" 7 1 "$volume_type" 7 30 50 0 "Updated VOLUME_TYPE:" 7 51 "$updated_volume_type" 7 80 50 0 \
        "IOPS:" 8 1 "$iops" 8 30 50 0 "Updated IOPS:" 8 51 "$updated_iops" 8 80 50 0 \
        "ENCRYPTED:" 9 1 "$encrypted" 9 30 50 0 "Updated ENCRYPTED:" 9 51 "$updated_encrypted" 9 80 50 0 \
        "DELETE_ON_TERMINATION:" 10 1 "$delete_on_termination" 10 30 50 0 "Updated DELETE_ON_TERMINATION:" 10 51 "$updated_delete_on_termination" 10 80 50 0 \
        "INSTANCE:" 11 1 "$instance" 11 30 50 0 "Updated INSTANCE:" 11 51 "$updated_instance" 11 80 50 0 \
        "STORAGE_FLAG:" 12 1 "$storage_flag" 12 30 50 0 "Updated STORAGE_FLAG:" 12 51 "$updated_storage_flag" 12 80 50 0 \
        "entry_status:" 13 1 "$entry_status" 13 30 10 0 \
        "create_date:" 14 1 "$create_date" 14 30 19 0 \
        "create_by:" 15 1 "$create_by" 15 30 10 0 \
        "update_date:" 16 1 "$update_date" 16 30 19 0 \
        "update_by:" 17 1 "$update_by" 17 30 10 0 2> /tmp/update_values_$db_table.txt

    updated_short_description=$(sed -n '2p' /tmp/update_values_$db_table.txt)
    updated_device_name=$(sed -n '4p' /tmp/update_values_$db_table.txt)
    updated_instance_attachment_point=$(sed -n '6p' /tmp/update_values_$db_table.txt)
    updated_volume_size=$(sed -n '8p' /tmp/update_values_$db_table.txt)
    updated_committed_size=$(sed -n '10p' /tmp/update_values_$db_table.txt)
    updated_volume_type=$(sed -n '12p' /tmp/update_values_$db_table.txt)
    updated_iops=$(sed -n '14p' /tmp/update_values_$db_table.txt)
    updated_encrypted=$(sed -n '16p' /tmp/update_values_$db_table.txt)
    updated_delete_on_termination=$(sed -n '18p' /tmp/update_values_$db_table.txt)
    updated_instance=$(sed -n '20p' /tmp/update_values_$db_table.txt)
    updated_storage_flag=$(sed -n '22p' /tmp/update_values_$db_table.txt)

    if [ $? -eq 0 ]; then
        # El usuario no canceló el formulario, proceder con la previsualización y confirmación
        preview_and_confirm
    else
        # El usuario canceló el formulario
        dialog --msgbox "Ingreso de datos cancelado." 10 40
    fi
}

# Función para actualizar un registro en la tabla t_storage
function update_records() {
    # Presentacion de registros
    records=$(mysql -u "$db_user" -p"$db_password" -D "$db_name" -e "SELECT T_STORAGE, DEVICE_NAME FROM $db_table;")

    if [ -z "$records" ]; then
        dialog --msgbox "No hay registros disponibles para actualizar." 10 40
        return
    fi

    dialog --menu "Selecciona el registro que deseas modificar (T_STORAGE - DEVICE_NAME):" 20 120 14 $records 2> /tmp/update_choice_$db_table.txt
    record_choice=$(cat /tmp/update_choice_$db_table.txt)

    if [ -z "$record_choice" ]; then
        dialog --msgbox "No se ha seleccionado ningún registro para actualizar." 10 40
        return
    fi

    # Almacena T_STORAGE en una variable
    T_STORAGE_choice=$(echo "$record_choice" | awk -F '-' '{print $1}')

    # Realizar una nueva consulta SQL para obtener todos los atributos del registro
    full_record_query="SELECT T_STORAGE, SHORT_DESCRIPTION, DEVICE_NAME, INSTANCE_ATTACHMENT_POINT, VOLUME_SIZE, COMMITTED_SIZE, VOLUME_TYPE, IOPS, ENCRYPTED, DELETE_ON_TERMINATION, INSTANCE, STORAGE_FLAG, ENTRY_STATUS, CREATE_DATE, CREATE_BY, UPDATE_DATE, UPDATE_BY FROM $db_table WHERE t_storage=$T_STORAGE_choice;"
    dialog --msgbox "Ejecutando el query: $full_record_query" 10 40
    
    full_record=$(mysql -u "$db_user" -p"$db_password" -D "$db_name" --skip-column-names -e "$full_record_query")

    if [ -z "$full_record" ]; then
        dialog --msgbox "Error al obtener el registro completo para edición." 10 40
        return
    fi

    dialog --msgbox "Full record: $full_record" 10 40

    # Exporta la variable FULL_RECORD con el valor de full_record
    export FULL_RECORD="$full_record"

    show_update_record_form "$full_record"
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
                show_add_record_form
                ;;
            2)
                show_storage_dialog
                ;;
            3)
                update_records
                ;;
            4)
                delete_records_dialog
                ;;
            5)
                delete_temp_file
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

function crud_storage() {
    change_directory_ownership_to_user
    #check_mysql_service
    #check_db_variables
    main_dialog
    delete_temp_file
    clear
}

crud_storage
