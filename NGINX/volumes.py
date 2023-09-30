import os
import subprocess
import mysql.connector
import tempfile
import json
import datetime

# Variables
script_directory = os.path.dirname(os.path.abspath(__file__))
output_file_path = os.path.join(script_directory, 'registros.txt')

# Configuración de la conexión a MySQL
MYSQL_USER = "antares"
MYSQL_PASSWORD = "antares1"
MYSQL_HOST = "localhost"  # Cambia a la dirección de tu servidor MySQL si es necesario
MYSQL_DATABASE = "antares"
MYSQL_STORAGE_TABLE = "t_storage"
MYSQL_PARTITIONS_TABLE = "t_partition"

def get_storage_headers():
    try:
        # Obtener de manera dinámica los encabezados de la tabla t_storage en MYSQL
        mysql_query = f"SHOW COLUMNS FROM {MYSQL_STORAGE_TABLE}"
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()
        cursor.execute(mysql_query)
        storage_headers = [row[0] for row in cursor.fetchall()]
        cursor.close()
        connection.close()
        
        print(f"Encabezados de la tabla '{MYSQL_STORAGE_TABLE}' obtenidos con éxito:")
        print(storage_headers)
        return storage_headers
    except Exception as e:
        print(f"Error al obtener los encabezados de la tabla {MYSQL_STORAGE_TABLE}.")
        print(str(e))
        return []

def read_storage_table():
    try:
        # Ejecutar la consulta SQL
        SQL_QUERY = f"SELECT * FROM {MYSQL_STORAGE_TABLE}"
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()
        cursor.execute(SQL_QUERY)
        results = cursor.fetchall()
        
        print("Lista de registros y su segunda columna:")
        print("------------------------------------------------------------------------------------------------")
        
        for row in results:
            third_value = row[2]
            print(row)
            print("******************************************")
            get_disk_info(third_value)
            print("******************************************")
            print("------------------------------------------------------------------------------------------------")
        
        cursor.close()
        connection.close()
    except Exception as e:
        print("Error al ejecutar la consulta SQL en MySQL.")
        print(str(e))

def get_disk_info(device_name):
    try:
        device_path = f"/dev/{device_name}"
        
        # Comprobar si el dispositivo existe antes de ejecutar lsblk
        if os.path.exists(device_path):
            # Obtener información de lsblk en formato JSON
            lsblk_info = subprocess.check_output(
                ["lsblk", "-Jbno", "NAME,SIZE,MOUNTPOINT", device_path], text=True
            )
            lsblk_info = json.loads(lsblk_info)
            
            print(f"Información para el dispositivo '{device_name}':")
            
            # Extraer el tamaño de la unidad de disco
            size = lsblk_info["blockdevices"][0]["size"]
            print(f"-> Tamaño de la unidad '{device_name}': {size} bytes")
            
            partition_count = 0
            partitioned_space = 0
            available_space = 0
            
            # Crear un archivo temporal para almacenar las particiones
            temp_file = tempfile.mktemp()
            
            # Iterar a través de las particiones y dispositivos
            for entry in lsblk_info["blockdevices"][0]["children"]:
                name = entry["name"]
                size = entry["size"]
                mountpoint = entry["mountpoint"]
                
                # Comprobar si es una partición
                if mountpoint is not None:
                    print(f"Partición: {name}")
                    print(f"Tamaño: {size} bytes")
                    print(f"Punto de montaje: {mountpoint}")
                    partition_count += 1
                    partitioned_space += size
                    
                    # Escribir en la tabla t_partition las particiones encontradas
                    with open(temp_file, "a") as f:
                        f.write(f"{name},{device_name},{mountpoint}\n")
            
            # Calcular espacio no particionado
            if size >= partitioned_space:
                available_space = size - partitioned_space
            else:
                available_space = 0
            
            print(f"-> Cantidad de particiones: {partition_count}")
            print(f"-> Espacio particionado: {partitioned_space} bytes")
            print(f"-> Espacio no particionado: {available_space} bytes")
            
            # Llamar a la función para escribir particiones en la tabla t_partition
            print("Llamando a la función para escribir particiones en la tabla t_partition...")
            write_partitions_to_mysql(temp_file)
            
            # Eliminar el archivo temporal
            os.remove(temp_file)
        else:
            print(f"El dispositivo '{device_name}' no existe")
    except Exception as e:
        print(f"No se pudo obtener información para '{device_name}'.")
        print(str(e))

def write_partitions_to_mysql(temp_file):
    try:
        # Obtener los encabezados de la tabla t_partition como cadenas
        partition_headers = [str(header) for header in get_partition_headers()]

        # Otorgar permisos de lectura y escritura al archivo temporal
        os.chmod(temp_file, 0o644)

        # Cambiar el propietario y grupo del archivo temporal (ajusta según tus necesidades)
        # sudo chown mysql:mysql "$temp_file"

        print(f"-> Escribiendo en la tabla '{MYSQL_PARTITIONS_TABLE}' las particiones encontradas...")

        # Verificar si se obtuvieron los encabezados correctamente
        if len(partition_headers) == 0:
            print(f"-> No se pudieron obtener los encabezados de la tabla '{MYSQL_PARTITIONS_TABLE}' correctamente.")
            return

        # Crear un string con los encabezados separados por comas y un espacio después de cada coma
        headers_string = ", ".join([header.strip("[]'") for header in partition_headers])

        print("-> Actualizando registros...")
        update_records(output_file_path)

        # Cargar datos en la tabla t_partition
        partitions_load_query = f"LOAD DATA INFILE '{temp_file}' INTO TABLE {MYSQL_DATABASE}.{MYSQL_PARTITIONS_TABLE} FIELDS TERMINATED BY ',' LINES TERMINATED BY '\\n' IGNORE 1 LINES ({headers_string});"

        # Mostrar la consulta SQL antes de ejecutarla
        print(f"-> Consulta SQL para cargar particiones en la tabla '{MYSQL_PARTITIONS_TABLE}':")
        print(f"{partitions_load_query}")

        # Ejecutar la consulta SQL
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()
        cursor.execute(partitions_load_query)
        connection.commit()
        cursor.close()
        connection.close()

        print(f"-> Particiones escritas en la tabla '{MYSQL_PARTITIONS_TABLE}' con éxito.")
    except Exception as e:
        print(f"-> Error al escribir particiones en la tabla '{MYSQL_PARTITIONS_TABLE}'.")
        print(str(e))


def get_partition_headers():
    try:
        # Obtener de manera dinámica los encabezados de la tabla t_storage en MYSQL
        print("--> Obteniendo de manera dinámica los encabezados de la tabla t_storage en MYSQL...")
        mysql_query = f"SHOW COLUMNS FROM {MYSQL_PARTITIONS_TABLE}"
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()
        cursor.execute(mysql_query)
        storage_headers = [row[0].strip("[]'") for row in cursor.fetchall()]  # Eliminar '[' y ']'
        cursor.close()
        connection.close()
        
        print(f"--> Encabezados de la tabla '{MYSQL_PARTITIONS_TABLE}' obtenidos con éxito:")
        print(storage_headers)
        return storage_headers
    except Exception as e:
        print(f"--> Error al obtener los encabezados de la tabla {MYSQL_PARTITIONS_TABLE}.")
        print(str(e))
        return []


def update_records(output_file_path):
    try:
        # Obtener los encabezados de la tabla t_partition como cadenas
        partition_headers = [str(header) for header in get_partition_headers()]

        # Verificar si se obtuvieron los encabezados correctamente
        if len(partition_headers) == 0:
            print(f"--> No se pudieron obtener los encabezados de la tabla '{MYSQL_PARTITIONS_TABLE}' correctamente.")
            return

        # Obtener el último registro de la tabla
        new_partition_value = get_max_partition_value() + 1
        partition_headers[0] = str(new_partition_value)  # Sustituir el primer encabezado

        # Obtener la fecha actual en formato "aaaa-mm-dd hh:mm:ss"
        current_datetime = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # Escribir en el campo "CREATE_DATE" la fecha actual si existe en la lista
        if "CREATE_DATE" in partition_headers:
            index = partition_headers.index("CREATE_DATE")
            partition_headers[index] = current_datetime

        # Escribir en el campo "CREATE_BY" el valor de MYSQL_USER si existe en la lista
        if "CREATE_BY" in partition_headers:
            index = partition_headers.index("CREATE_BY")
            partition_headers[index] = MYSQL_USER

        # Escribir en el campo "UPDATE_DATE" la fecha actual si existe en la lista
        if "UPDATE_DATE" in partition_headers:
            index = partition_headers.index("UPDATE_DATE")
            partition_headers[index] = current_datetime

        # Escribir en el campo "UPDATE_BY" el valor de MYSQL_USER si existe en la lista
        if "UPDATE_BY" in partition_headers:
            index = partition_headers.index("UPDATE_BY")
            partition_headers[index] = MYSQL_USER

        # Escribir en el campo "ENTRY_STATUS" el valor "0" si existe en la lista
        if "ENTRY_STATUS" in partition_headers:
            index = partition_headers.index("ENTRY_STATUS")
            partition_headers[index] = "0"

        # Crear un archivo de texto para guardar los encabezados actualizados
        with open(output_file_path, 'w') as output_file:
            output_file.write(", ".join(partition_headers))

        print(f"--> Encabezados guardados en el archivo '{output_file_path}'")

        return partition_headers
    except Exception as e:
        print(f"-> Error al escribir particiones en la tabla '{MYSQL_PARTITIONS_TABLE}'.")
        print(str(e))


def get_max_partition_value():
    try:
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()
        cursor.execute(f"SELECT MAX(T_PARTITION) FROM {MYSQL_PARTITIONS_TABLE};")
        result = cursor.fetchone()
        cursor.close()
        connection.close()
        
        last_partition = result[0] if result else 0
        return last_partition
    except Exception as e:
        print(f"No se pudo obtener el último registro de la tabla '{MYSQL_PARTITIONS_TABLE}'.")
        print(str(e))
        return 0

def volumes():
    get_storage_headers()
    print("------------------------------------------------------------------------------------------------")
    read_storage_table()

# Llamar a la función principal
volumes()
