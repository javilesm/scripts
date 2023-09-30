#!/bin/bash
# volumes.sh

# variables
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
CSV_TABLES_DIR="tablas"
CSV_TABLES_PATH="$PARENT_DIR/Antares_project/$CSV_TABLES_DIR"
CSV_PARTITIONS_FILE="t_partitions.csv"
CSV_PARTITIONS_PATH="$CSV_TABLES_PATH/$CSV_PARTITIONS_FILE"

# Configuración de la conexión a MySQL
MYSQL_USER="antares"
MYSQL_PASSWORD="antares1"
MYSQL_HOST="localhost"  # Cambia a la dirección de tu servidor MySQL si es necesario
MYSQL_DATABASE="antares"
MYSQL_STORAGE_TABLE="t_storage"
MYSQL_PARTITIONS_TABLE="t_partition"

# Función para obtener de manera dinamica los encabezados de la tabla t_storage en MYSQL
function get_storage_headers() {
    # obtener de manera dinamica los encabezados de la tabla t_storage en MYSQL
    echo "Obteniendo de manera dinamica los encabezados de la tabla '$MYSQL_STORAGE_TABLE' en MYSQL..."
    local mysql_query="SHOW COLUMNS FROM $MYSQL_STORAGE_TABLE"
    local headers=($(mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -D "$MYSQL_DATABASE" -s -N -e "$mysql_query" | cut -f1))
    
    if [ $? -eq 0 ]; then
        echo "Encabezados de la tabla '$MYSQL_STORAGE_TABLE' obtenidos con éxito:"
        echo "${headers[@]}"
        return 0
    else
        echo "Error al obtener los encabezados de la tabla $MYSQL_STORAGE_TABLE."
        return 1
    fi
}

# Función para obtener de manera dinamica los encabezados de la tabla t_storage en MYSQL
function get_partition_headers() {
    # obtener de manera dinamica los encabezados de la tabla t_storage en MYSQL
    echo "Obteniendo de manera dinamica los encabezados de la tabla '$MYSQL_PARTITIONS_TABLE' en MYSQL..."
    local mysql_query="SHOW COLUMNS FROM $MYSQL_PARTITIONS_TABLE"
    local headers=($(mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -D "$MYSQL_DATABASE" -s -N -e "$mysql_query" | cut -f1))
    
    if [ $? -eq 0 ]; then
        echo "Encabezados de la tabla '$MYSQL_PARTITIONS_TABLE' obtenidos con éxito:"
        echo "${headers[@]}"
        return 0
    else
        echo "Error al obtener los encabezados de la tabla $MYSQL_PARTITIONS_TABLE."
        return 1
    fi
}

# Función principal que consulta MySQL
function read_storage_table() {
    # Ejecutar la consulta SQL
    SQL_QUERY="SELECT * FROM $MYSQL_STORAGE_TABLE"
    MYSQL_RESULT=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -D "$MYSQL_DATABASE" -s -N -e "$SQL_QUERY")

    if [ $? -eq 0 ]; then
        # Procesar los resultados
        echo "Lista de registros y su segunda columna:"
        echo "------------------------------------------------------------------------------------------------"
        while read -r record; do
            third_value=$(echo "$record" | cut -f3)
            echo "$record"
            echo "******************************************"
            get_disk_info $third_value
            echo "******************************************"
            echo "------------------------------------------------------------------------------------------------"
        done <<< "$MYSQL_RESULT"
    else
        echo "Error al ejecutar la consulta SQL en MySQL."
    fi
}

# Función para obtener información detallada sobre una unidad de disco
function get_disk_info() {
    local device_name="dev/$1"

    # Comprobar si el dispositivo existe antes de ejecutar lsblk
    if [ -e "$device_name" ]; then
        # Obtener información de lsblk en formato JSON
        local lsblk_info=$(lsblk -Jbno NAME,SIZE,MOUNTPOINT "$device_name")

        if [ -n "$lsblk_info" ]; then
            echo "Información para el dispositivo '$device_name':"

            # Extraer el tamaño de la unidad de disco
            local size=$(echo "$lsblk_info" | jq -r '.blockdevices[0].size')
            echo "-> Tamaño de la unidad '$device_name': $size bytes"

            # Contador de particiones y espacio particionado
            local partition_count=0
            local partitioned_space=0
            local available_space=0

            # Calcular espacio no particionado
            if [ $size -ge $partitioned_space ]; then
                available_space=$((size - partitioned_space))
            else
                available_space=0
            fi

            echo "-> Cantidad de particiones: $partition_count"
            echo "-> Espacio particionado: $partitioned_space bytes"
            echo "-> Espacio no particionado: $available_space bytes"
        else
            echo "No se pudo obtener información para '$device_name'."
        fi
    else
        echo "El dispositivo '$device_name' no existe"
    fi
}

function volumes() {
    get_storage_headers
    echo "------------------------------------------------------------------------------------------------"
    get_partition_headers
    echo "------------------------------------------------------------------------------------------------"
    read_storage_table
}

# Llamar a la función principal
volumes
