import os
import sys
import subprocess
import mysql.connector
import tempfile
import json
import datetime
import logging  # Importa la biblioteca de registro

# Configura el sistema de registro con la fecha y hora actual en el nombre del archivo
log_file_name = datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S') + '_process_workorders_log.txt'
logging.basicConfig(filename=log_file_name, level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Variables
script_directory = os.path.dirname(os.path.abspath(__file__))
output_file_path = os.path.join(script_directory, 'registros.csv')

# Configuración de la conexión a MySQL
MYSQL_USER = "2309000000"
MYSQL_PASSWORD = "antares1"
MYSQL_HOST = "localhost"  # Cambia a la dirección de tu servidor MySQL si es necesario
MYSQL_DATABASE = "antares"
MYSQL_STORAGE_TABLE = "t_storage"
MYSQL_PARTITIONS_TABLE = "t_partition"
MYSQL_WORKORDER_TABLE = "t_workorder"
MYSQL_WORKORDERFLAG_TABLE = "t_workorder_flag"
MYSQL_PRODUCT_TABLE = "t_Product"

# función para conversionde bytes
def bytes_to_gigabytes(bytes_value):
    #gigabytes = bytes_value / 1073741824.0
    gigabytes = bytes_value
    return gigabytes

# función para leer tabla t_workorder
def read_workorder_table():
    try:
        print(f"Leyendo la tabla: {MYSQL_WORKORDER_TABLE}...")
        # Configuración de la conexión a MySQL
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()

        # Obtener los encabezados de la tabla
        print(f"Obteniendo los encabezados de la tabla {MYSQL_WORKORDER_TABLE}...")
        cursor.execute(f"SHOW COLUMNS FROM {MYSQL_WORKORDER_TABLE}")
        headers = [column[0] for column in cursor.fetchall()]

        # Ejecutar la consulta SQL
        SQL_QUERY = f"SELECT * FROM {MYSQL_WORKORDER_TABLE}"
        cursor.execute(SQL_QUERY)
        results = cursor.fetchall()

        print(f"Encabezados de la tabla {MYSQL_WORKORDER_TABLE}:")
        print(headers)
        print("------------------------------------------------------------------------------------------------")

        for row in results:
            workorder_flag = row[headers.index("WORKORDER_FLAG")]
            t_workorder = row[headers.index("T_WORKORDER")]  # Obtener el valor de la clave primaria t_workorder
            print(f"Procesando t_workorder: {t_workorder}")  # Indicar el valor de t_workorder

            if workorder_flag == 1:
                print("******************************************")
                # Consultar la tabla MYSQL_PRODUCT_TABLE
                SQL_PRODUCT_QUERY = f"SELECT REQUIRED_SIZE FROM {MYSQL_PRODUCT_TABLE} WHERE T_PRODUCT = {row[headers.index('T_PRODUCT')]}"
                cursor.execute(SQL_PRODUCT_QUERY)
                product_result = cursor.fetchone()

                if product_result:
                    product_description = product_result[0]  # Obtiene el valor de la primera columna (REQUIRED_SIZE)
                    print(f"Espacio en disco requerido: {product_description}")
                    read_storage_table(product_description, t_workorder)

                else:
                    print(f"Registro no encontrado en la tabla {MYSQL_WORKORDER_TABLE}")

                print("******************************************")

            print("------------------------------------------------------------------------------------------------")

        cursor.close()
        connection.close()
    except Exception as e:
        print("Error al ejecutar la consulta SQL en MySQL.")
        print(str(e))

# función para leer la tabla MYSQL_STORAGE_TABLE
def read_storage_table(product_description, t_workorder):
    try:
        print(f"Leyendo la tabla {MYSQL_STORAGE_TABLE}...")
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
            get_disk_info(third_value, product_description, t_workorder)
            print("******************************************")
            print("------------------------------------------------------------------------------------------------")
        
        cursor.close()
        connection.close()
    except Exception as e:
        print("Error al ejecutar la consulta SQL en MySQL.")
        print(str(e))

# función para verificar si la particion ya existe en SQL
def is_partition_exists_in_sql(name):
    try:
        # Imprimir un mensaje de auditoría para indicar que se está verificando la existencia de la partición
        print(f"Verificando si la partición '{name}' ya existe en la tabla '{MYSQL_PARTITIONS_TABLE}'...")

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

# función para obtener informacion de la unidad de disco
def get_disk_info(device_name, product_description, t_workorder):
    try:
        device_path = f"/dev/{device_name}"
        print(f"Obteniendo informacion de la unidad: '{device_path}'...")

        # Comprobar si el dispositivo existe antes de ejecutar lsblk
        if os.path.exists(device_path):
            # Obtener información de lsblk en formato JSON
            lsblk_info = subprocess.check_output(
                ["lsblk", "-Jbno", "NAME,SIZE,MOUNTPOINT", device_path], text=True
            )
            lsblk_info = json.loads(lsblk_info)

            print(f"Información para el dispositivo '{device_name}':")

            # Extraer el tamaño de la unidad de disco
            device_size = lsblk_info["blockdevices"][0]["size"]
            print(f"-> Tamaño de la unidad '{device_name}': {device_size} bytes")

            partition_count = 0
            partitioned_space = 0
            available_space = 0
            is_unpartitioned = True

            # Iterar a través de las particiones y dispositivos
            for entry in lsblk_info["blockdevices"][0]["children"]:
                name = entry["name"]
                size = entry["size"]
                mountpoint = entry["mountpoint"]

                # Calcular espacio no particionado
                partitioned_space += size
                available_space = device_size - partitioned_space

                # Comprobar si es una partición
                if mountpoint is not None:
                    print(f"SHORT_DESCRIPTION (name): {name}")
                    print(f"DEVICE_NAME (device_name): {device_name}")
                    print(f"PARTITION_SIZE (size): {size} bytes")
                    print(f"ATTACHMENT_POINT (mountpoint): {mountpoint}")
                    print("-------------------------------------")
                    partition_count += 1
                    is_unpartitioned = False

            print(f"-> Cantidad de particiones: {partition_count}")
            print(f"-> Espacio particionado: {partitioned_space} bytes")
            print(f"-> Espacio no particionado: {available_space} bytes")

            # Calcular committed_size_bytes como espacio particionado
            committed_size_bytes = partitioned_space

            # Actualizar la columna "committed_size" en la tabla t_storage
            print("Actualizando la columna 'committed_size' en la tabla t_storage...")
            update_storage_committed_size(device_name, committed_size_bytes)  # Aquí se pasa solo el espacio particionado

            # Verificar si el espacio no particionado es mayor o igual al espacio requerido
            if available_space >= product_description:
                print(f"El espacio libre en la unidad '{device_name}' es mayor o igual que el espacio requerido.")
                create_partition(device_name, "primary", "ext4", product_description, t_workorder)  # Aquí se pasa el tamaño requerido
            elif available_space < product_description:
                print(f"El espacio libre en la unidad '{device_name}' es menor que el espacio requerido.")
            
        else:
            print(f"La unidad '{device_name}' no existe")
    except Exception as e:
        print(f"La unidad '{device_name}' no se encuentra particionada.")
        try:
            create_partition(device_name, "primary", "ext4", product_description, t_workorder)  # Aquí se pasa el tamaño requerido
        except Exception as e:
            print(f"Error inesperadoo al crear la partición en la unidad '{device_name}': {str(e)}")

def calculate_new_partition_start(device_name):
    try:
        # Obtener información sobre las particiones existentes en el dispositivo
        print(f"Información sobre el dispositivo '{device_name}':")
        print(f"Obteniendo información sobre las particiones existentes en el dispositivo '{device_name}'...")

        lsblk_info = subprocess.check_output(["lsblk", "-Jbno", "NAME,SIZE,MOUNTPOINT", f"/dev/{device_name}"], text=True)
        lsblk_info = json.loads(lsblk_info)
        device_partitions = lsblk_info.get("blockdevices", [])[0].get("children", [])

        if device_partitions:
            print(f"Calculando el punto de inicio de la nueva partición en el dispositivo '{device_name}'...")
            total_partition_size_bytes = 0

            for partition_info in device_partitions:
                partition_size_bytes = int(partition_info.get("size", 0))
                total_partition_size_bytes += partition_size_bytes

            new_partition_start_bytes = total_partition_size_bytes + 1

            return total_partition_size_bytes, None, new_partition_start_bytes
        else:
            print(f"No se encontraron particiones existentes en el dispositivo '{device_name}'.")
            return None, None, None

    except Exception as e:
        print(f"Error al calcular el punto de inicio de la nueva partición: {str(e)}")
        return None, None, None


def create_partition(device_name, partition_type, filesystem_type, partition_size, t_workorder):
    try:
        print(f"Particionando orden: {t_workorder}")
        print(f"Información para el dispositivo '{device_name}':")

        # Verificar si la unidad ya tiene una etiqueta de disco GPT o MBR
        print("Verificando si la unidad ya tiene una etiqueta de disco GPT o MBR...")
        label_check_command = f"sudo parted /dev/{device_name} print | grep -q 'Partition Table: gpt' || sudo parted /dev/{device_name} print | grep -q 'Partition Table: msdos'"
        label_check_result = subprocess.run(label_check_command, shell=True, stderr=subprocess.PIPE)

        # Si la unidad no tiene una etiqueta de disco GPT o MBR, crea una nueva etiqueta GPT
        print("Si la unidad no tiene una etiqueta de disco GPT o MBR, crea una nueva etiqueta GPT...")
        if label_check_result.returncode != 0:
            print(f"La unidad '{device_name}' no tiene una etiqueta de disco válida. Creando una nueva etiqueta GPT...")
            label_command = f"sudo parted /dev/{device_name} mklabel gpt"  # No es necesario el 'yes'
            subprocess.run(label_command, shell=True, check=True)

        # Calcular el punto de inicio de la nueva partición
        last_partition_size_bytes, last_partition_start_bytes, new_partition_start_bytes = calculate_new_partition_start(device_name)
        
        print(f"Tamaño de la última partición: {last_partition_size_bytes} bytes.")
        print(f"Punto de inicio de la última partición: {last_partition_start_bytes} bytes.")
        print(f"Punto de inicio de la nueva partición: {new_partition_start_bytes} bytes.")
        
        if last_partition_size_bytes is not None and new_partition_start_bytes is not None:
            # Comando parted para crear una partición primaria ext4 con el tamaño requerido y el punto de inicio calculado
            partition_command = f"sudo parted --align optimal /dev/{device_name} mkpart {partition_type} {filesystem_type} {new_partition_start_bytes}B {new_partition_start_bytes + partition_size}B"
            print(f"Procediendo a particionar la unidad: '/dev/{device_name}' con un tamaño de: {partition_size} bytes.")
            print(f"Ejecutando el comando: {partition_command}")

            # Usar 'echo' para enviar "yes" a parted
            subprocess.run(f'echo "yes" | {partition_command}', shell=True)

            # Verificar si se creó la partición exitosamente
            check_partition_command = f"sudo parted /dev/{device_name} print | grep {partition_type}"
            partition_result = subprocess.run(check_partition_command, shell=True, stderr=subprocess.PIPE)

            if partition_result.returncode == 0:
                print(f"Partición creada en la unidad '/dev/{device_name}' como {partition_type} {filesystem_type}.")
                # Si la partición se crea con éxito, actualizar el campo 'workorder_flag' en la tabla correspondiente
                # Llamar a la función para actualizar el campo "workorder_flag" solo para esta t_workorder
                print(f"Procesos de la orden {t_workorder} completados.")

                created_partition_info = {
                    "device_name": device_name,
                    "partition_type": partition_type,
                    "filesystem_type": filesystem_type,
                    "partition_size": partition_size
                }

                update_workorder_table(t_workorder, created_partition_info)
            else:
                print(f"Error al crear la partición en la unidad '/dev/{device_name}': {partition_result.stderr.decode('utf-8')}")
        else:
            print("No se encontraron particiones existentes en el dispositivo. No es posible calcular el punto de inicio de la nueva partición.")

    except subprocess.CalledProcessError as e:
        print(f"Error al crear la partición en la unidad '/dev/{device_name}': {e}")
    except Exception as e:
        print(f"Error inesperado al crear la partición en la unidad '/dev/{device_name}': {str(e)}")


def update_storage_committed_size(device_name, committed_size_bytes):
    try:
        # Convertir el tamaño comprometido a gigabytes
        committed_size_gb = bytes_to_gigabytes(committed_size_bytes)

        # Construir la consulta SQL para actualizar la columna "committed_size"
        update_query = f"UPDATE {MYSQL_STORAGE_TABLE} SET committed_size = %s WHERE DEVICE_NAME = %s"
        
        # Ejecutar la consulta SQL
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()
        cursor.execute(update_query, (committed_size_gb, device_name))
        connection.commit()
        cursor.close()
        connection.close()

        print(f"-> Columna 'committed_size' actualizada para la unidad '{device_name}' con éxito.")
        pass
    except Exception as e:
        print(f"Error al actualizar la columna 'committed_size' para la unidad '{device_name}': {str(e)}")

def write_partitions_to_mysql(temp_file, name, device_name, mountpoint, size):
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
        updated_values = update_t_partition_records(output_file_path, name, device_name, mountpoint, size)

        # Verifica si se obtuvieron valores actualizados
        if updated_values:

            # Construir la consulta SQL con los valores reales
            partitions_load_query = f"INSERT INTO {MYSQL_PARTITIONS_TABLE} ({', '.join(updated_values.keys())}) VALUES ({updated_values['T_PARTITION']}, '{updated_values['SHORT_DESCRIPTION']}', '{updated_values['DEVICE_NAME']}', '{updated_values['ATTACHMENT_POINT']}', '{updated_values['PARTITION_SIZE']}', {updated_values['ENTRY_STATUS']}, '{updated_values['CREATE_DATE']}', '{updated_values['CREATE_BY']}', '{updated_values['UPDATE_DATE']}', '{updated_values['UPDATE_BY']}');"


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
        # Obtener de manera dinámica los encabezados de la tabla t_partition en MYSQL
        print(f"--> Obteniendo de manera dinámica los encabezados de la tabla {MYSQL_PARTITIONS_TABLE} en MYSQL...")
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

def update_t_partition_records(output_file_path, name, device_name, mountpoint, size):
    try:
        print(f"Actualizando registros en la tabla {MYSQL_PARTITIONS_TABLE}.....")

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

        # Escribir en el campo "PARTITION_SIZE" el valor "attachment_point" si existe en la lista
        if "PARTITION_SIZE" in partition_headers:
            index = partition_headers.index("PARTITION_SIZE")
            updated_values["PARTITION_SIZE"] = size

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

# Llamar a esta función después de haber creado la partición con éxito
def update_workorder_table(t_workorder, created_partition_info):
    try:
        print(f"Actualizando datos en la tabla: '{MYSQL_WORKORDER_TABLE}'...")
        # Obtener información sobre la partición creada
        device_name = created_partition_info["device_name"]
        partition_type = created_partition_info["partition_type"]
        filesystem_type = created_partition_info["filesystem_type"]
        partition_size = created_partition_info["partition_size"]

        # Configuración de la conexión a MySQL
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()

        # Obtener la fecha actual en formato "aaaa-mm-dd hh:mm:ss"
        current_datetime = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # Actualizar el campo "workorder_flag" a "2" en la tabla MYSQL_WORKORDER_TABLE
        SQL_UPDATE_WORKORDER_FLAG = f"UPDATE {MYSQL_WORKORDER_TABLE} SET workorder_flag = 2, t_partition = %s, UPDATE_DATE = %s, UPDATE_BY = %s WHERE T_WORKORDER = %s"
        cursor.execute(SQL_UPDATE_WORKORDER_FLAG, (f"{device_name}:{partition_type}:{filesystem_type}:{partition_size}", current_datetime, MYSQL_USER, t_workorder))
        
        connection.commit()
        cursor.close()
        connection.close()

        print(f"Campo 'workorder_flag' actualizado a '2' y 't_partition', 'UPDATE_DATE', 'UPDATE_BY' actualizados para t_workorder: '{t_workorder}'")
    except Exception as e:
        print(f"Error al actualizar los campos en la tabla MYSQL_WORKORDER_TABLE para t_workorder: '{t_workorder}'.")
        print(str(e))


def process_workorders():
    read_workorder_table()
    print("------------------------------------------------------------------------------------------------")

# Llamar a la función principal
process_workorders()
