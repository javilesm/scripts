import os
import sys
import subprocess
import mysql.connector
import tempfile
import json
import datetime
from colorama import Fore, Style
import logging
from colorlog import getLogger
import time

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

# Variables
script_directory = os.path.dirname(os.path.abspath(__file__))   # el directorio actual del script (donde se encuentra este script)
log_file_name = os.path.join(script_directory, datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S') + '_process_workorders_log.txt')  # el sistema de registro con la fecha y hora actual en el nombre del archivo

logger = getLogger()
logger.setLevel(logging.INFO)

# Define un manejador de colorlog con formato personalizado
handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter(
    f'{Fore.GREEN}%(asctime)s - %(levelname)s - %(message)s{Style.RESET_ALL}'
))

logger.addHandler(handler)

# Añade un manejador de archivo para guardar los registros en un archivo
file_handler = logging.FileHandler(log_file_name)
file_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
logger.addHandler(file_handler)

# Define un diccionario para realizar un seguimiento de las t_workorders que han utilizado cada dispositivo
used_workorders = {}

# función para conversionde bytes
def bytes_to_gigabytes(bytes_value):
    #gigabytes = bytes_value / 1073741824.0
    gigabytes = bytes_value
    return gigabytes

# función para leer tabla t_workorder
def read_workorder_table():
    try:
        logger.info(f"Leyendo la tabla: '{MYSQL_WORKORDER_TABLE}'...")
        # Configuración de la conexión a MySQL
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()

        # Obtener los encabezados de la tabla
        logger.info(f"Obteniendo los encabezados de la tabla '{MYSQL_WORKORDER_TABLE}'...")
        cursor.execute(f"SHOW COLUMNS FROM {MYSQL_WORKORDER_TABLE}")
        headers = [column[0] for column in cursor.fetchall()]

        # Ejecutar la consulta SQL
        SQL_QUERY = f"SELECT * FROM {MYSQL_WORKORDER_TABLE}"
        cursor.execute(SQL_QUERY)
        results = cursor.fetchall()

        logger.info(f"Encabezados de la tabla '{MYSQL_WORKORDER_TABLE}':")
        logger.info(headers)
        logger.info("------------------------------------------------------------------------------------------------")

        for row in results:
            t_workorder = row[headers.index("T_WORKORDER")]  # Obtener el valor de la clave primaria t_workorder
            description = row[headers.index("DESCRIPTION")]
            registered_domain = row[headers.index("REGISTERED_DOMAIN")]  # Extraer REGISTERED_DOMAIN

            # Obtener el valor de workorder_flag directamente de la base de datos
            cursor.execute(f"SELECT WORKORDER_FLAG FROM {MYSQL_WORKORDER_TABLE} WHERE T_WORKORDER = {t_workorder}")
            result = cursor.fetchone()
            if result:
                workorder_flag = result[0]
            else:
                workorder_flag = None

            logger.info(f"Procesando T_WORKORDER: '{t_workorder}', DESCRIPTION: '{description}', WORKORDER_FLAG: '{workorder_flag}', REGISTERED_DOMAIN: '{registered_domain}'")

            if workorder_flag == 1:
                logger.info("******************************************")
                # Consultar la tabla MYSQL_PRODUCT_TABLE
                SQL_PRODUCT_QUERY = f"SELECT REQUIRED_SIZE FROM {MYSQL_PRODUCT_TABLE} WHERE T_PRODUCT = {row[headers.index('T_PRODUCT')]}"
                cursor.execute(SQL_PRODUCT_QUERY)
                product_result = cursor.fetchone()

                if product_result:
                    product_description = product_result[0]  # Obtiene el valor de la primera columna (REQUIRED_SIZE)
                    logger.info(f"Espacio en disco requerido: '{product_description}' bytes.")

                    # Llamar a la función read_storage_table
                    read_storage_table(workorder_flag, product_description, t_workorder, registered_domain)

                    logger.info(f"Procesos de la orden '{t_workorder}' completados.")

                else:
                    logger.error(f"Registro no encontrado en la tabla '{MYSQL_WORKORDER_TABLE}'")

                logger.info("******************************************")

            logger.info("------------------------------------------------------------------------------------------------")

        cursor.close()
        connection.close()
    except Exception as e:
        logger.error("ERROR: Error al ejecutar la consulta SQL en MySQL.")
        logger.error(str(e))

# función para leer la tabla MYSQL_STORAGE_TABLE
def read_storage_table(workorder_flag, product_description, t_workorder, registered_domain):
    try:
        logger.info(f"Leyendo la tabla '{MYSQL_STORAGE_TABLE}'...")
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
        
        for row in results:
            device_name = row[2]  # Obtener el nombre del dispositivo de la fila
            print(row)
            get_disk_info(workorder_flag, device_name, product_description, t_workorder, registered_domain, cursor)  # Pasar el nombre del dispositivo
            print("-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+")
        print("-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+")
                
        cursor.close()
        connection.close()
    except Exception as e:
        logger.error("ERROR: Error al ejecutar la consulta SQL en MySQL.")
        print(str(e))


# función para verificar si la particion ya existe en SQL
def is_partition_exists_in_sql(name):
    try:
        # Imprimir un mensaje de auditoría para indicar que se está verificando la existencia de la partición
        logger.info(f"Verificando si la partición '{name}' ya existe en la tabla '{MYSQL_PARTITIONS_TABLE}'...")

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
        logger.info(f"-> Consulta SQL para verificar si la partición '{name}' ya existe en la tabla '{MYSQL_PARTITIONS_TABLE}':")
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
        logger.error(f"Error al verificar si la partición '{name}' ya existe en la tabla '{MYSQL_PARTITIONS_TABLE}': {str(e)}")
        if "Lost connection" in str(e):
            logger.info("Intentando reconectar...")
            return is_partition_exists_in_sql(name)  # Intentar reconectar
        return False

# Función para obtener información de la unidad de disco
def get_disk_info(workorder_flag, device_name, product_description, t_workorder, registered_domain, cursor):
    name = None
    mountpoint = None
    device_size = 0
    partition_count = 0
    partitioned_space = 0
    available_space = 0
    is_unpartitioned = True

    try:
        # Comprobar el valor de WORKORDER_FLAG antes de proceder
        if workorder_flag != 1:
            logger.info(f"WORKORDER_FLAG no es igual a 1 para la orden '{t_workorder}', no se procesará la unidad.")
            return

        logger.info(f"Procesando T_WORKORDER: '{t_workorder}', WORKORDER_FLAG: '{workorder_flag}' y obteniendo información de la unidad de disco '{device_name}'...")

        # Configuración de la conexión a MySQL
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()

        # Comprobar si el dispositivo existe antes de ejecutar lsblk
        device_path = f"/dev/{device_name}"
        if os.path.exists(device_path):
            logger.info(f"Obteniendo información de la unidad: '{device_path}'...")
            
            # Obtener información de lsblk en formato JSON
            lsblk_info = subprocess.check_output(
                ["lsblk", "-Jbno", "NAME,SIZE,MOUNTPOINT", device_path], text=True
            )
            lsblk_info = json.loads(lsblk_info)

            logger.info(f"Información para el dispositivo '{device_name}':")

            # Extraer el tamaño de la unidad de disco
            device_size = lsblk_info["blockdevices"][0]["size"]
            logger.info(f"-> Tamaño de la unidad '{device_name}': {device_size} bytes")

            partition_count = 0
            partitioned_space = 0
            available_space = 0
            is_unpartitioned = True

            if "children" in lsblk_info["blockdevices"][0]:
                # Iterar a través de las particiones y dispositivos
                for entry in lsblk_info["blockdevices"][0]["children"]:
                    name = entry.get("name")
                    size = entry.get("size")
                    mountpoint = entry.get("mountpoint")

                    if name is not None:
                        # Calcular espacio no particionado
                        partitioned_space += size
                        available_space = device_size - partitioned_space

                        # Comprobar si es una partición
                        if mountpoint is not None:
                            logger.info(f"SHORT_DESCRIPTION (name): {name}")
                            logger.info(f"DEVICE_NAME (device_name): {device_name}")
                            logger.info(f"PARTITION_SIZE (size): {size} bytes")
                            logger.info(f"ATTACHMENT_POINT (mountpoint): {mountpoint}")
                            logger.info("-------------------------------------")
                            partition_count += 1
                            is_unpartitioned = False

                        # Verificar si el espacio no particionado es mayor o igual al espacio requerido
                        if available_space >= product_description:
                            logger.info(f"El espacio libre en la unidad '{device_name}' es mayor o igual que el espacio requerido.")
                            create_partition(workorder_flag, device_name, "primary", "ext4", product_description, t_workorder, name, mountpoint, product_description, registered_domain)  # Aquí se pasa el tamaño requerido

            logger.info(f"-> Cantidad de particiones: {partition_count}")
            logger.info(f"-> Espacio particionado: {partitioned_space} bytes")
            logger.info(f"-> Espacio no particionado: {available_space} bytes")

            # Calcular committed_size_bytes como espacio particionado
            committed_size_bytes = partitioned_space

            # Actualizar la columna "committed_size" en la tabla t_storage
            logger.info("Actualizando la columna 'committed_size' en la tabla t_storage...")
            update_storage_committed_size(device_name, committed_size_bytes)  # Aquí se pasa solo el espacio particionado

            # Mover aquí la sección para crear partición si no está particionada
            if is_unpartitioned:
                logger.warning(f"La unidad '{device_name}' no se encuentra particionada.")
                try:
                    create_partition(workorder_flag, device_name, "primary", "ext4", product_description, t_workorder, name, mountpoint, product_description, registered_domain)  # Aquí se pasa el tamaño requerido
                except Exception as e:
                    logger.error(f"ERROR: Error inesperado al crear la partición en la unidad '{device_name}': {str(e)}")

        else:
            logger.warning(f"La unidad '{device_name}' no existe")

        cursor.close()
        connection.close()

    except Exception as e:
        logger.error(f"ERROR inesperado: {str(e)}")


def calculate_new_partition_start(device_name):
    try:
        # Obtener información sobre las particiones existentes en el dispositivo
        logger.info(f"Información sobre el dispositivo '{device_name}':")
        logger.info(f"Obteniendo información sobre las particiones existentes en el dispositivo '{device_name}'...")

        lsblk_info = subprocess.check_output(["lsblk", "-Jbno", "NAME,SIZE,MOUNTPOINT", f"/dev/{device_name}"], text=True)
        lsblk_info = json.loads(lsblk_info)
        device_partitions = lsblk_info.get("blockdevices", [])[0].get("children", [])

        if device_partitions:
            logger.info(f"Calculando el punto de inicio de la nueva partición en el dispositivo '{device_name}'...")
            total_partition_size_bytes = 0

            for partition_info in device_partitions:
                partition_size_bytes = int(partition_info.get("size", 0))
                total_partition_size_bytes += partition_size_bytes

            new_partition_start_bytes = total_partition_size_bytes + 1

            return total_partition_size_bytes, None, new_partition_start_bytes
        else:
            logger.warning(f"No se encontraron particiones existentes en el dispositivo '{device_name}'.")
            # Retorna un punto de inicio predeterminado
            return 0, None, 1

    except Exception as e:
        logger.error(f"Error al calcular el punto de inicio de la nueva partición: {str(e)}")
        return None, None, None

# Función para calcular el numero de partición
def calculate_next_partition_number(device_name):
    try:
        # Obtener información sobre las particiones existentes en el dispositivo
        logger.info(f"Obteniendo información sobre las particiones existentes en el dispositivo '{device_name}'...")

        lsblk_info = subprocess.check_output(["lsblk", "-Jbno", "NAME", f"/dev/{device_name}"], text=True)
        lsblk_info = json.loads(lsblk_info)
        device_partitions = lsblk_info.get("blockdevices", [])[0].get("children", [])

        # Crear una lista de números de partición existentes
        existing_partition_numbers = [int(entry["name"].replace(f"{device_name}", "")) for entry in device_partitions]

        # Calcular el siguiente número de partición disponible
        next_partition_number = 1
        while next_partition_number in existing_partition_numbers:
            next_partition_number += 1

        logger.info(f"Siguiente número de partición disponible para '{device_name}': {next_partition_number}")
        return next_partition_number

    except Exception as e:
        logger.error(f"Error al calcular el siguiente número de partición: {str(e)}")
        return None

# Función para crear particiones
def create_partition(workorder_flag, device_name, partition_type, filesystem_type, partition_size, t_workorder, name, mountpoint, product_description, registered_domain):
    try:
        logger.info(f"Particionando el dispositivo '{device_name}' de acuerdo con la orden de trabajo: '{t_workorder}' para el dominio '{registered_domain}'")

        # Obtener el siguiente número de partición disponible
        next_partition_number = calculate_next_partition_number(device_name)

        # Verificar si el dispositivo tiene particiones previas
        lsblk_info = subprocess.check_output(["lsblk", "-Jbno", "NAME,SIZE,MOUNTPOINT", f"/dev/{device_name}"], text=True)
        lsblk_info = json.loads(lsblk_info)
        device_partitions = lsblk_info.get("blockdevices", [])[0].get("children", [])

        if device_partitions:
            last_partition_size_bytes, last_partition_start_bytes, new_partition_start_bytes = calculate_new_partition_start(device_name)
        else:
            logger.info(f"El dispositivo '{device_name}' no tiene particiones previas. Utilizando punto de inicio predeterminado.")
            last_partition_size_bytes, last_partition_start_bytes, new_partition_start_bytes = 0, None, 1

        logger.info(f"Tamaño de la última partición: {last_partition_size_bytes} bytes.")
        logger.info(f"Punto de inicio de la última partición: {last_partition_start_bytes} bytes.")
        logger.info(f"Punto de inicio de la nueva partición: {new_partition_start_bytes} bytes")
        
        if last_partition_size_bytes is not None and new_partition_start_bytes is not None:
            # Comando parted para crear una partición primaria ext4 con el tamaño requerido y el punto de inicio calculado
            partition_command = f"sudo parted --align optimal /dev/{device_name} mkpart {next_partition_number} {partition_type} {filesystem_type} {new_partition_start_bytes}B {new_partition_start_bytes + partition_size}B > /dev/null 2>&1"
            logger.info(f"Procediendo a particionar la unidad: '/dev/{device_name}' con un tamaño de: {partition_size} bytes.")
            logger.info(f"Ejecutando el comando: '{partition_command}'")

            # Usar 'yes' para enviar automáticamente "y" a las preguntas y no detener la ejecución
            subprocess.Popen(f"yes | {partition_command}", shell=True)

            logger.info(f"Esperando a que se complete la partición...")

            # Esperar a que se complete el proceso de partición
            subprocess.Popen(["sleep", "10"])

            # Verificar si se creó la partición exitosamente
            check_partition_command = f"sudo parted /dev/{device_name} print | grep {next_partition_number}"
            partition_result = subprocess.run(check_partition_command, shell=True, stderr=subprocess.PIPE)

            if partition_result.returncode == 0:
                # Obtener el nombre de la partición recién creada
                partition_info = subprocess.check_output(f"sudo parted /dev/{device_name} print | grep {next_partition_number}", shell=True, text=True)
                partition_lines = partition_info.strip().split('\n')
                
                # Extraer el nombre de la partición de las líneas obtenidas
                partition_name = partition_lines[-1].split()[0]
                
                logger.info(f"Partición creada en la unidad '/dev/{device_name}' como '{partition_name}', tipo '{partition_type}' y formato '{filesystem_type}'.")

                created_partition_info = {
                    "device_name": device_name,
                    "partition_name": partition_name,
                    "partition_number": next_partition_number,
                    "partition_type": partition_type,
                    "filesystem_type": filesystem_type,
                    "registered_domain": registered_domain,
                    "partition_size": partition_size
                }

                # Luego de crear la partición con éxito, llama a format_partition
                format_partition(workorder_flag, device_name, partition_name, filesystem_type, registered_domain, partition_size, t_workorder, created_partition_info)
                 
            else:
                logger.error(f"ERROR: Error al crear la partición en la unidad '/dev/{device_name}': {partition_result.stderr.decode('utf-8')}")
        else:
            logger.warning("No se encontraron particiones existentes en el dispositivo. No es posible calcular el punto de inicio de la nueva partición.")

    except subprocess.CalledProcessError as e:
        logger.error(f"ERROR: Error al crear la partición en la unidad '/dev/{device_name}': {e}")
    except Exception as e:
        logger.error(f"ERROR: Error muy inesperado al crear la partición en la unidad '/dev/{device_name}': {str(e)}")

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

        logger.info(f"-> Columna 'committed_size' actualizada para la unidad '{device_name}' con éxito.")
        pass
    except Exception as e:
        logger.error(f"ERROR: Error al actualizar la columna 'committed_size' para la unidad '{device_name}': {str(e)}")

# Función para formatear particiones
def format_partition(workorder_flag, device_name, partition_name, filesystem_type, registered_domain, partition_size, t_workorder, created_partition_info):
    try:
        device_path = f"/dev/{device_name}"
        logger.info(f"Procediendo a formatear la particion '{partition_name}' en la unidad '{device_path}' con sistema de archivos '{filesystem_type}' para el dominio '{registered_domain}'.")
        # Formatear la partición con el sistema de archivos especificado
        format_command = f"sudo mkfs -t {filesystem_type} {device_path}"
        process = subprocess.Popen(format_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = process.communicate()

        if process.returncode == 0:
            logger.info(f"Partición '{partition_name}' formateada con éxito en '{device_path}' con sistema de archivos '{filesystem_type}' para el dominio '{registered_domain}'.")
            # Llamar a la función para montar la partición después de formatear
            mount_partition(workorder_flag, device_name, partition_name, registered_domain, partition_size, t_workorder, created_partition_info)
        else:
            error_message = err.decode("utf-8").strip()
            raise Exception(f"ERROR: Error al formatear la partición '{partition_name}' en '{device_path}': {error_message}")

    except Exception as e:
        logger.error(f"ERROR: Error al intentar formatear la partición '{partition_name}' en '{device_path}': {str(e)}")

# Función para montar partición con REGISTERED_DOMAIN
def mount_partition(workorder_flag, device_name, partition_name, registered_domain, partition_size, t_workorder, created_partition_info):
    try:
        target_dir = "/var/www"  # Definir la variable target_dir

        if not os.path.exists(target_dir):
            raise Exception(f"ERROR: El directorio '{target_dir}' no existe.")

        # Concatenar target_dir y registered_domain para obtener mounting_path
        mounting_path = os.path.join(target_dir, registered_domain)

        logger.info(f"Montando la partición '{partition_name}' en la unidad '{device_name}' del dominio '{registered_domain}' en '{mounting_path}'...")

        # Verificar si el dispositivo existe antes de montarlo
        device_path = f"/dev/{device_name}"
        if not os.path.exists(device_path):
            raise Exception(f"ERROR: El dispositivo '{device_name}' no existe.")

        # Verificar si el punto de montaje existe
        if not os.path.exists(mounting_path):
            logger.info(f"El punto de montaje '{mounting_path}' no existe. Creándolo...")
            os.makedirs(mounting_path)

        # Montar la partición
        mount_command = f"sudo mount {device_path} {mounting_path}"
        process = subprocess.Popen(mount_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = process.communicate()

        if process.returncode == 0:
            logger.info(f"Partición '{partition_name}' montada con éxito en '{mounting_path}'.")

            # Luego de montar la partición con éxito, llama a write_partitions_to_mysql
            write_partitions_to_mysql(workorder_flag, partition_name, device_name, mounting_path, partition_size, t_workorder, created_partition_info)
     
        else:
            error_message = err.decode("utf-8").strip()
            raise Exception(f"ERROR: Error al montar la partición '{partition_name}' en '{mounting_path}': {error_message}")

    except Exception as e:
        logger.error(f"ERROR: Error al montar la partición en '{mounting_path}': {str(e)}")

def write_partitions_to_mysql(workorder_flag, partition_name, device_name, mounting_path, partition_size, t_workorder, created_partition_info):
    try:
        logger.info(f"Escribiendo en la tabla '{MYSQL_PARTITIONS_TABLE}' las particiones encontradas...")
        logger.info(f"--SHORT_DESCRIPTION: {partition_name}")
        logger.info(f"--DEVICE_NAME: {device_name}")
        logger.info(f"--ATTACHMENT_POINT: {mounting_path}")
        print("-------------------------------------")

        # Obtener los encabezados de la tabla t_partition como cadenas
        partition_headers = [str(header) for header in get_partition_headers()]
      
        # Verificar si se obtuvieron los encabezados correctamente
        if len(partition_headers) == 0:
            logger.info(f"-> No se pudieron obtener los encabezados de la tabla '{MYSQL_PARTITIONS_TABLE}' correctamente.")
            return

        logger.info("-> Actualizando registros...")

        # En la función write_partitions_to_mysql, obtén los valores actualizados
        updated_values = update_t_partition_records(partition_name, device_name, mounting_path, partition_size)

        # Verifica si se obtuvieron valores actualizados
        if updated_values:

            # Construir la consulta SQL con los valores reales
            partitions_load_query = f"INSERT INTO {MYSQL_PARTITIONS_TABLE} ({', '.join(updated_values.keys())}) VALUES ({updated_values['T_PARTITION']}, '{updated_values['SHORT_DESCRIPTION']}', '{updated_values['DEVICE_NAME']}', '{updated_values['ATTACHMENT_POINT']}', '{updated_values['PARTITION_SIZE']}', {updated_values['ENTRY_STATUS']}, '{updated_values['CREATE_DATE']}', '{updated_values['CREATE_BY']}', '{updated_values['UPDATE_DATE']}', '{updated_values['UPDATE_BY']}');"


            # Mostrar la consulta SQL antes de ejecutarla
            logger.info(f"-> Consulta SQL para cargar particiones en la tabla '{MYSQL_PARTITIONS_TABLE}':")
            logger.info(f"{partitions_load_query}")

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

            logger.info(f"-> Particiones escritas en la tabla '{MYSQL_PARTITIONS_TABLE}' con éxito.")
            
            # Llamar a la funcion para agregar entradas en /etc/fstab para montar las particiones al reiniciar el sistema
            add_to_fstab(workorder_flag, device_name, mounting_path, created_partition_info, t_workorder, filesystem_type="ext4", options="defaults", dump=0, pass_num=0)

    except Exception as e:
        logger.error(f"ERROR: Error al escribir particiones en la tabla '{MYSQL_PARTITIONS_TABLE}'.")
        logger.error(str(e))

def get_partition_headers():
    try:
        # Obtener de manera dinámica los encabezados de la tabla t_partition en MYSQL
        logger.info(f"--> Obteniendo de manera dinámica los encabezados de la tabla {MYSQL_PARTITIONS_TABLE} en MYSQL...")
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
        
        logger.info(f"--> Encabezados de la tabla '{MYSQL_PARTITIONS_TABLE}' obtenidos con éxito:")
        logger.info(storage_headers)
        return storage_headers
    except Exception as e:
        logger.error(f"ERROR: Error al obtener los encabezados de la tabla {MYSQL_PARTITIONS_TABLE}.")
        logger.error(str(e))
        return []

def update_t_partition_records(partition_name, device_name, mounting_path, partition_size):
    try:
        logger.info(f"Actualizando registros en la tabla '{MYSQL_PARTITIONS_TABLE}'.....")

        # Obtener los encabezados de la tabla t_partition como cadenas
        partition_headers = [str(header) for header in get_partition_headers()]

        # Verificar si se obtuvieron los encabezados correctamente
        if len(partition_headers) == 0:
            logger.info(f"--> No se pudieron obtener los encabezados de la tabla '{MYSQL_PARTITIONS_TABLE}' correctamente.")
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
            updated_values["SHORT_DESCRIPTION"] = partition_name
        
        # Escribir en el campo "DEVICE_NAME" el valor "device_name" si existe en la lista
        if "DEVICE_NAME" in partition_headers:
            index = partition_headers.index("DEVICE_NAME")
            updated_values["DEVICE_NAME"] = device_name
        
        # Escribir en el campo "ATTACHMENT_POINT" el valor "attachment_point" si existe en la lista
        if "ATTACHMENT_POINT" in partition_headers:
            index = partition_headers.index("ATTACHMENT_POINT")
            updated_values["ATTACHMENT_POINT"] = mounting_path

        # Escribir en el campo "PARTITION_SIZE" el valor "attachment_point" si existe en la lista
        if "PARTITION_SIZE" in partition_headers:
            index = partition_headers.index("PARTITION_SIZE")
            updated_values["PARTITION_SIZE"] = partition_size

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
        logger.error(f"ERROR: Error al escribir particiones en la tabla '{MYSQL_PARTITIONS_TABLE}'.")
        logger.error(str(e))
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
        logger.error(f"ERROR: No se pudo obtener el último registro de la tabla '{MYSQL_PARTITIONS_TABLE}'.")
        logger.error(str(e))
        return 0

# funcion para agregar entradas en /etc/fstab para montar las particiones al reiniciar el sistema
def add_to_fstab(workorder_flag, device_name, mounting_path, created_partition_info, t_workorder, filesystem_type="ext4", options="defaults", dump=0, pass_num=0):
    try:
        fstab_path = "/etc/fstab"

        logger.info(f"Agregando entradas en '{fstab_path}' para montar las particiones al reiniciar el sistema...")
        
        # Comprobar si el archivo /etc/fstab ya contiene una entrada para el dispositivo
        with open(fstab_path, "r") as fstab_file:
            fstab_content = fstab_file.read()
            if f"{device_name} " in fstab_content:
                logger.info(f"La entrada para '{device_name}' ya existe en '{fstab_path}'.")
                update_workorder_table(workorder_flag, t_workorder, created_partition_info)
                return

        # Agregar una nueva entrada al archivo /etc/fstab
        with open(fstab_path, "a") as fstab_file:
            fstab_file.write(f"{device_name} {mounting_path} {filesystem_type} {options} {dump} {pass_num}\n")

        logger.info(f"Entrada para '{device_name}' agregada a '{fstab_path}'. La partición se montará automáticamente al reiniciar el sistema.")

        # Luego de agregar entradas en /etc/fstab con éxito, llama a update_workorder_table
        update_workorder_table(workorder_flag, t_workorder, created_partition_info)

    except FileNotFoundError:
        logger.error(f"ERROR: El archivo '{fstab_path}' no existe. Asegúrate de estar ejecutando el script con permisos de superusuario (sudo).")

    except PermissionError:
        logger.error(f"ERROR: No tienes permiso para modificar '{fstab_path}'. Asegúrate de estar ejecutando el script con permisos de superusuario (sudo).")

    except Exception as e:
        logger.error(f"ERROR: Error al agregar entrada a '{fstab_path}': {str(e)}")

# Llamar a esta función después de haber creado la partición con éxito
def update_workorder_table(workorder_flag, t_workorder, created_partition_info):
    try:
        logger.info(f"Actualizando WORKORDER_FLAG '{workorder_flag}' en la orden '{t_workorder}' de la tabla: '{MYSQL_WORKORDER_TABLE}'...")
        
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
        
        # Usar una transacción para realizar los cambios
        try:
            cursor.execute(SQL_UPDATE_WORKORDER_FLAG, (f"{device_name}:{partition_type}:{filesystem_type}:{partition_size}", current_datetime, MYSQL_USER, t_workorder))
            connection.commit()  # Confirmar la transacción
            cursor.close()
            connection.close()
            logger.info(f"Campo 'workorder_flag' actualizado a '2' y 't_partition', 'UPDATE_DATE', 'UPDATE_BY' actualizados para t_workorder: '{t_workorder}'")
            time.sleep(10)
            
            # Repetir la consulta y mostrar el valor de workorder_flag
            connection = mysql.connector.connect(
                user=MYSQL_USER,
                password=MYSQL_PASSWORD,
                host=MYSQL_HOST,
                database=MYSQL_DATABASE
            )
            cursor = connection.cursor()
            cursor.execute(f"SELECT workorder_flag FROM {MYSQL_WORKORDER_TABLE} WHERE T_WORKORDER = %s", (t_workorder,))
            result = cursor.fetchone()
            if result:
                workorder_flag_value = result[0]
                logger.info(f"Valor actualizado de workorder_flag para la orden '{t_workorder}': {workorder_flag_value}")
            else:
                logger.info(f"No se encontró la orden '{t_workorder}' en la tabla '{MYSQL_WORKORDER_TABLE}'.")

            cursor.close()
            connection.close()
            
            logger.info(f"********************************************************************************************************************************************")
        except Exception as e:
            connection.rollback()  # Deshacer la transacción si ocurre un error
            raise e  # Re-lanzar la excepción para manejarla en un nivel superior

    except Exception as e:
        logger.error(f"ERROR: Error al actualizar los campos en la tabla '{MYSQL_WORKORDER_TABLE}' para la orden: '{t_workorder}'.")
        logger.error(str(e))

def process_workorders():
    read_workorder_table()
    print("------------------------------------------------------------------------------------------------")

# Llamar a la función principal
process_workorders()
