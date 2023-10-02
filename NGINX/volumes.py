import os
import subprocess
import mysql.connector
import tempfile
import json
import datetime

# Variables
script_directory = os.path.dirname(os.path.abspath(__file__))
output_file_path = os.path.join(script_directory, 'registros.csv')

# Configuración de la conexión a MySQL
MYSQL_USER = "antares"
MYSQL_PASSWORD = "antares1"
MYSQL_HOST = "localhost"  # Cambia a la dirección de tu servidor MySQL si es necesario
MYSQL_DATABASE = "antares"
MYSQL_STORAGE_TABLE = "t_storage"
MYSQL_PARTITIONS_TABLE = "t_partition"
MYSQL_WORKORDERS_TABLE = "t_workorder"
MYSQL_WORKORDERFLAG_TABLE = "t_workorder_flag"
MYSQL_PRODUCT_TABLE = "t_product"

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

def is_partition_exists_in_sql(name):
    try:
        # Imprimir un mensaje de auditoría para indicar que se está consultando la existencia de la partición
        print(f"Consultando si la partición '{name}' ya existe en la tabla '{MYSQL_PARTITIONS_TABLE}'...")

        # Construir la consulta SQL con los valores reales
        partion_exists_query = f"SELECT COUNT(*) FROM {MYSQL_PARTITIONS_TABLE} WHERE SHORT_DESCRIPTION = %s"
        
        # Ejecutar la consulta SQL
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()
        
        # Consultar si la partición con SHORT_DESCRIPTION ya existe en la tabla
        cursor.execute(partion_exists_query, (name,))
        
        # Mostrar la consulta SQL antes de ejecutarla (Nota: debe ser cursor.statement)
        print(f"-> Consulta SQL para verificar si la partición '{name}' ya existe en la tabla '{MYSQL_PARTITIONS_TABLE}':")
        print(cursor.statement)

        # Obtener el resultado de la consulta
        result = cursor.fetchone()
        
        # Cerrar el cursor y la conexión a la base de datos
        cursor.close()
        connection.close()
        
        # Si el resultado es igual a 1, significa que la partición existe
        return result[0] == 1
    except mysql.connector.Error as e:
        # Manejar errores de MySQL y tratar de reconectar
        print(f"Error al verificar si la partición '{name}' ya existe en la tabla '{MYSQL_PARTITIONS_TABLE}': {str(e)}")
        if "Lost connection" in str(e):
            print("Intentando reconectar...")
            return is_partition_exists_in_sql(name)  # Intentar reconectar
        return False


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
                    print(f"SHORT_DESCRIPTION (name): {name}")
                    print(f"DEVICE_NAME (device_name): {device_name}")
                    print(f"PARTITION_SIZE (size): {size} bytes")
                    print(f"ATTACHMENT_POINT (mountpoint): {mountpoint}")
                    print("-------------------------------------")
                    partition_count += 1
                    partitioned_space += size

                    # Comprobar si la partición ya existe en la tabla SQL
                    if not is_partition_exists_in_sql(name):
                        # Si no existe, escribir en la tabla t_partition las particiones encontradas
                        with open(temp_file, "a") as f:
                            f.write(f"{name},{device_name},{mountpoint}\n")

                        # Llamar a la función para escribir particiones en la tabla t_partition
                        print("Llamando a la función para escribir particiones en la tabla t_partition...")
                        write_partitions_to_mysql(temp_file, name, device_name, mountpoint)

            # Calcular espacio no particionado
            if size >= partitioned_space:
                available_space = size - partitioned_space
            else:
                available_space = 0

            print(f"-> Cantidad de particiones: {partition_count}")
            print(f"-> Espacio particionado: {partitioned_space} bytes")
            print(f"-> Espacio no particionado: {available_space} bytes")

            # Actualizar la columna "comitted_size" en la tabla t_storage
            update_storage_comitted_size(device_name, partitioned_space)
            
        else:
            print(f"La unidad '{device_name}' no existe")
    except Exception as e:
        print(f"La unidad '{device_name}' no se encuentra particionada.")
        print(str(e))

def update_storage_comitted_size(device_name, comitted_size):
    try:
        # Construir la consulta SQL para actualizar la columna "comitted_size"
        update_query = f"UPDATE {MYSQL_STORAGE_TABLE} SET comitted_size = %s WHERE DEVICE_NAME = %s"
        
        # Ejecutar la consulta SQL
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()
        cursor.execute(update_query, (comitted_size, device_name))
        connection.commit()
        cursor.close()
        connection.close()

        print(f"-> Columna 'comitted_size' actualizada para la unidad '{device_name}' con éxito.")
    except Exception as e:
        print(f"Error al actualizar la columna 'comitted_size' para la unidad '{device_name}'.")
        print(str(e))

def write_partitions_to_mysql(temp_file, name, device_name, mountpoint):
    try:
        print(f"--SHORT_DESCRIPTION: {name}")
        print(f"--DEVICE_NAME: {device_name}")
        print(f"--ATTACHMENT_POINT: {mountpoint}")
        print("-------------------------------------")

        # Obtener los encabezados de la tabla t_partition como cadenas
        partition_headers = [str(header) for header in get_partition_headers()]

        # Otorgar permisos de lectura y escritura al archivo temporal
        os.chmod(temp_file, 0o755)

        # Ejecutar el comando para cambiar la propiedad
        comando_chown = f"sudo chown mysql:mysql {temp_file}"
        subprocess.run(comando_chown, shell=True, check=True)

        print(f"-> Escribiendo en la tabla '{MYSQL_PARTITIONS_TABLE}' las particiones encontradas...")

        # Verificar si se obtuvieron los encabezados correctamente
        if len(partition_headers) == 0:
            print(f"-> No se pudieron obtener los encabezados de la tabla '{MYSQL_PARTITIONS_TABLE}' correctamente.")
            return

        print("-> Actualizando registros...")

        # En la función write_partitions_to_mysql, obtén los valores actualizados
        updated_values = update_records(output_file_path, name, device_name, mountpoint)

        # Verifica si se obtuvieron valores actualizados
        if updated_values:

            # Construir la consulta SQL con los valores reales
            partitions_load_query = f"INSERT INTO {MYSQL_PARTITIONS_TABLE} ({', '.join(updated_values.keys())}) VALUES ({updated_values['T_PARTITION']}, '{updated_values['SHORT_DESCRIPTION']}', '{updated_values['DEVICE_NAME']}', '{updated_values['ATTACHMENT_POINT']}', {updated_values['ENTRY_STATUS']}, '{updated_values['CREATE_DATE']}', '{updated_values['CREATE_BY']}', '{updated_values['UPDATE_DATE']}', '{updated_values['UPDATE_BY']}');"


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


def update_records(output_file_path, name, device_name, mountpoint):
    try:
        print("Actualizando registros.....")

        # Obtener los encabezados de la tabla t_partition como cadenas
        partition_headers = [str(header) for header in get_partition_headers()]

        # Verificar si se obtuvieron los encabezados correctamente
        if len(partition_headers) == 0:
            print(f"--> No se pudieron obtener los encabezados de la tabla '{MYSQL_PARTITIONS_TABLE}' correctamente.")
            return {}

        # Obtener la fecha actual en formato "aaaa-mm-dd hh:mm:ss"
        current_datetime = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

         # Crear un diccionario para almacenar los valores actualizados
        updated_values = {}

        # Escribir en el campo "T_PARTITION" el ultimo registro incrementando en 1 si existe en la lista
        if "T_PARTITION" in partition_headers:
            index = partition_headers.index("T_PARTITION")
            updated_values["T_PARTITION"] = str(get_max_partition_value() + 1)

        # Escribir en el campo "SHORT_DESCRIPTION" el valor "short_description" si existe en la lista
        if "SHORT_DESCRIPTION" in partition_headers:
            index = partition_headers.index("SHORT_DESCRIPTION")
            updated_values["SHORT_DESCRIPTION"] = name
        
        # Escribir en el campo "DEVICE_NAME" el valor "device_name" si existe en la lista
        if "DEVICE_NAME" in partition_headers:
            index = partition_headers.index("DEVICE_NAME")
            updated_values["DEVICE_NAME"] = device_name
        
        # Escribir en el campo "ATTACHMENT_POINT" el valor "attachment_point" si existe en la lista
        if "ATTACHMENT_POINT" in partition_headers:
            index = partition_headers.index("ATTACHMENT_POINT")
            updated_values["ATTACHMENT_POINT"] = mountpoint

         # Escribir en el campo "ENTRY_STATUS" el valor "0" si existe en la lista
        if "ENTRY_STATUS" in partition_headers:
            index = partition_headers.index("ENTRY_STATUS")
            updated_values["ENTRY_STATUS"] = "0"

        # Escribir en el campo "CREATE_DATE" la fecha actual si existe en la lista
        if "CREATE_DATE" in partition_headers:
            index = partition_headers.index("CREATE_DATE")
            updated_values["CREATE_DATE"] = current_datetime

        # Escribir en el campo "CREATE_BY" el valor de MYSQL_USER si existe en la lista
        if "CREATE_BY" in partition_headers:
            index = partition_headers.index("CREATE_BY")
            updated_values["CREATE_BY"] = MYSQL_USER

        # Escribir en el campo "UPDATE_DATE" la fecha actual si existe en la lista
        if "UPDATE_DATE" in partition_headers:
            index = partition_headers.index("UPDATE_DATE")
            updated_values["UPDATE_DATE"] = current_datetime

        # Escribir en el campo "UPDATE_BY" el valor de MYSQL_USER si existe en la lista
        if "UPDATE_BY" in partition_headers:
            index = partition_headers.index("UPDATE_BY")
            updated_values["UPDATE_BY"] = MYSQL_USER

        print(f"Valores actualizados: {updated_values}")
        return updated_values

        return partition_headers
    except Exception as e:
        print(f"-> Error al escribir particiones en la tabla '{MYSQL_PARTITIONS_TABLE}'.")
        print(str(e))
        return []


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
