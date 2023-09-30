#!/bin/bash
# volumes.sh

# variables
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
CSV_TABLES_DIR="tablas"
CSV_PARTITIONS_FILE="t_partitions.csv"
CSV_PARTITIONS_PATH="$CSV_TABLES_PATH/$CSV_PARTITIONS_FILE"

# Configuración de la conexión a MySQL
MYSQL_USER="antares"
MYSQL_PASSWORD="antares1"
MYSQL_HOST="localhost"  # Cambia a la dirección de tu servidor MySQL si es necesario
MYSQL_DATABASE="antares"
MYSQL_STORAGE_TABLE="t_storage"
MYSQL_PARTITIONS_TABLE="t_partitions"

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

            # Crear un archivo CSV para almacenar la información

            # Comprobar si el archivo CSV ya existe
            if [ ! -e "$CSV_PARTITIONS_PATH" ]; then
                echo "Partición,Disco,Tamaño (bytes),Punto de montaje" > "$CSV_PARTITIONS_PATH"
            fi

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

                    # Guardar información de la partición en el archivo CSV
                    echo "$name,$device_name,$size,$mountpoint" >> "$CSV_PARTITIONS_PATH"
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
        else
            echo "No se pudo obtener información para '$device_name'."
        fi
    else
        echo "El dispositivo '$device_name' no existe"
    fi
}

# Función principal que consulta MySQL
function volumes() {
    # Ejecutar la consulta SQL
    SQL_QUERY="SELECT * FROM $MYSQL_STORAGE_TABLE"
    MYSQL_RESULT=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -D "$MYSQL_DATABASE" -s -N -e "$SQL_QUERY")

    if [ $? -eq 0 ]; then
        # Procesar los resultados
        echo "Lista de registros y su segunda columna:"
        echo "------------------------------------------------------------------------------------------------"
        while read -r record; do
            third_value=$(echo "$record" | cut -f3)
            echo "$record, segunda columna: $third_value"
            echo "******************************************"
            get_disk_info $third_value
            echo "******************************************"
            echo "------------------------------------------------------------------------------------------------"
        done <<< "$MYSQL_RESULT"
    else
        echo "Error al ejecutar la consulta SQL en MySQL."
    fi
}

# Llamar a la función principal
volumes
