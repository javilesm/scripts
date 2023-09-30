#!/bin/bash
# volumes.sh

# variables
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory

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
    local storage_headers=($(mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -D "$MYSQL_DATABASE" -s -N -e "$mysql_query" | cut -f1))
    
    if [ $? -eq 0 ]; then
        echo "Encabezados de la tabla '$MYSQL_STORAGE_TABLE' obtenidos con éxito:"
        echo "${storage_headers[@]}"
        return 0
    else
        echo "Error al obtener los encabezados de la tabla $MYSQL_STORAGE_TABLE."
        return 1
    fi
}

# Función para obtener de manera dinamica los encabezados de la tabla t_storage en MYSQL
function get_partition_headers() {
    # Obtener de manera dinámica los encabezados de la tabla t_storage en MYSQL
    local mysql_query="SHOW COLUMNS FROM $MYSQL_PARTITIONS_TABLE"
    local partition_headers=($(mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -D "$MYSQL_DATABASE" -s -N -e "$mysql_query" | cut -f1))
    
    if [ $? -eq 0 ]; then
        echo "${partition_headers[@]}"
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

            # Crear un archivo temporal para almacenar las particiones
            local temp_file=$(mktemp)

            # Iterar a través de las particiones y dispositivos
            for entry in $(echo "$lsblk_info" | jq -c '.blockdevices[0].children[]?'); do
                local name=$(echo "$entry" | jq -r '.name')
                local size=$(echo "$entry" | jq -r '.size')
                local mountpoint=$(echo "$entry" | jq -r '.mountpoint')

                # Comprobar si es una partición
                if [ "$mountpoint" != "null" ]; then
                    echo "Partición: $name"
                    echo "Tamaño: $size bytes"
                    echo "Punto de montaje: $mountpoint"
                    ((partition_count++))
                    ((partitioned_space += size))

                    # Escribir en la tabla t_partition las particiones encontradas
                    echo "$name,$device_name,$mountpoint" >> "$temp_file"

                fi
            done

            # Calcular espacio no particionado
            if [ $size -ge $partitioned_space ]; then
                available_space=$((size - partitioned_space))
            else
                available_space=0
            fi

            echo "-> Cantidad de particiones: $partition_count"
            echo "-> Espacio particionado: $partitioned_space bytes"
            echo "-> Espacio no particionado: $available_space bytes"

            # Llamar a la función para escribir particiones en la tabla t_partition
            write_partitions_to_mysql "$temp_file"

            # Eliminar el archivo temporal
            rm -f "$temp_file"
        else
            echo "No se pudo obtener información para '$device_name'."
        fi
    else
        echo "El dispositivo '$device_name' no existe"
    fi
}

# Función para escribir en la tabla t_partition las particiones encontradas
function write_partitions_to_mysql() {
    local temp_file="$1"
    # Otorgar permisos de lectura y escritura al archivo temporal
    sudo chmod 644 "$temp_file"

    # Cambiar el propietario y grupo del archivo temporal (ajusta según tus necesidades)
    sudo chown mysql:mysql "$temp_file"
    
    echo "Escribiendo en la tabla '$MYSQL_PARTITIONS_TABLE' las particiones encontradas..."
    
    # Obtener los encabezados de la tabla t_partition
    partition_headers=($(get_partition_headers))

    # Verificar si se obtuvieron los encabezados correctamente
    if [ ${#partition_headers[@]} -eq 0 ]; then
        echo "No se pudieron obtener los encabezados de la tabla '$MYSQL_PARTITIONS_TABLE' correctamente."
        return 1
    fi

    # Crear un string con los encabezados separados por comas
    local headers_string=$(IFS=,; echo "${partition_headers[*]}")

    # Cargar datos en la tabla t_partition
    local partitions_load_query="LOAD DATA INFILE '$temp_file' INTO TABLE $MYSQL_DATABASE.$MYSQL_PARTITIONS_TABLE FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES ($headers_string);"

    # Mostrar la consulta SQL antes de ejecutarla
    echo "Consulta SQL para cargar particiones en la tabla '$MYSQL_PARTITIONS_TABLE':"
    echo "$partitions_load_query"

    # Ejecutar la consulta SQL
    if mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -e "$partitions_load_query"; then
        echo "Particiones escritas en la tabla '$MYSQL_PARTITIONS_TABLE' con éxito."
    else
        echo "Error al escribir particiones en la tabla '$MYSQL_PARTITIONS_TABLE'."
    fi
}


function volumes() {
    get_storage_headers
    echo "------------------------------------------------------------------------------------------------"
    read_storage_table
    
}

# Llamar a la función principal
volumes
