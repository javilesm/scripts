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
import math
import pexpect

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
target_dir = "/var/www" 
script_directory = os.path.dirname(os.path.abspath(__file__))
log_directory = os.path.join(script_directory, "logs")
log_file_name = os.path.join(log_directory, datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S') + '_process_workorders_log.txt')  # el sistema de registro con la fecha y hora actual en el nombre del archivo


# Define un diccionario para realizar un seguimiento de las t_workorders que han utilizado cada dispositivo
used_workorders = {}

def setup_logging(log_directory, log_file_name):
    # Obtiene el nombre del usuario actual
    current_user = os.getlogin()  # o puedes usar os.getenv("USER")

    try:
        
        # Crear el directorio con sudo
        subprocess.run(["sudo", "mkdir", "-p", log_directory])

        # Cambiar los permisos con sudo (por ejemplo, 0o755 para propietario:lectura/escritura/ejecución, otros:lectura/ejecución)
        subprocess.run(["sudo", "chmod", "755", log_directory])

        subprocess.run(["sudo", "chown", "-R", f"{current_user}:{current_user}", log_directory])

        # Ruta completa para el archivo de registro
        log_file_path = os.path.join(log_directory, log_file_name)

        logger = getLogger()
        logger.setLevel(logging.INFO)

        # Define un manejador de colorlog con formato personalizado
        handler = logging.StreamHandler()
        handler.setFormatter(logging.Formatter(
            f'{Fore.GREEN}%(asctime)s - %(levelname)s - %(message)s{Style.RESET_ALL}'
        ))

        logger.addHandler(handler)

        # Añade un manejador de archivo para guardar los registros en un archivo
        file_handler = logging.FileHandler(log_file_path)
        file_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
        logger.addHandler(file_handler)

        return logger
    except Exception as e:
        print(f"Error al configurar el registro: {str(e)}")

logger = setup_logging(log_directory, log_file_name)

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

            # Agregar un registro de depuración aquí para verificar el valor de workorder_flag
            logger.info(f"DEBUG: Valor de workorder_flag: {workorder_flag}")

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
                    created_partition_info = read_storage_table(workorder_flag, product_description, t_workorder, registered_domain)

                    # Agregar un registro de depuración aquí para verificar que read_storage_table se ejecutó
                    logger.info("DEBUG: read_storage_table ejecutada")

                    if created_partition_info is not None:
                        # Llamar a la función update_workorder_table después de haber creado la partición con éxito
                        if update_workorder_table(workorder_flag, device_name, mounting_path, created_partition_info, t_workorder):
                            # Registrar que los procesos se completaron
                            logger.info(f"Procesos de la orden '{t_workorder}' completados.")
                        else:
                            logger.error(f"No se pudo actualizar la orden '{t_workorder}' en la tabla '{MYSQL_WORKORDER_TABLE}'.")

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
        # Configuración de la conexión a MySQL
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()

        # Consultar el valor de WORKORDER_FLAG desde la tabla MYSQL_WORKORDER_TABLE
        cursor.execute(f"SELECT WORKORDER_FLAG FROM {MYSQL_WORKORDER_TABLE} WHERE T_WORKORDER = {t_workorder}")
        result = cursor.fetchone()

        if result:
            workorder_flag = result[0]

            if workorder_flag != 1:
                logger.info(f"WORKORDER_FLAG is not equal to 1 for order '{t_workorder}', the unit will not be processed.")
                return

            logger.info(f"Procesando T_WORKORDER: '{t_workorder}', WORKORDER_FLAG: '{workorder_flag}' y obteniendo información de la unidad de disco '{device_name}'...")

        # Comprobar si el dispositivo existe antes de ejecutar lsblk
        device_path = f"/dev/{device_name}"

        if os.path.exists(device_path):
            logger.info(f"Obteniendo información de la unidad: '{device_path}'...")

            # Obtener información de lsblk en formato JSON
            lsblk_info = subprocess.check_output(
                ["lsblk", "-Jbno", "NAME,SIZE,MOUNTPOINT", device_path], text=True
            )
            lsblk_info = json.loads(lsblk_info)

            logger.info(f"Información para el dispositivo '{device_path}':")

            # Extraer el tamaño de la unidad de disco
            device_size = lsblk_info["blockdevices"][0]["size"]
            logger.info(f"-> Tamaño de la unidad '{device_path}': {device_size} bytes")

            if "children" in lsblk_info["blockdevices"][0]:
                # Iterar a través de las particiones y dispositivos
                for entry in lsblk_info["blockdevices"][0]["children"]:
                    name = entry.get("name")
                    size = entry.get("size")
                    mountpoint = entry.get("mountpoint")

                    if name is not None:
                        if mountpoint == "/":
                            logger.warning(f"La unidad '{device_path}' tiene el punto de montaje '/' y será omitida.")
                            return  # Omitir la unidad y buscar otra
                        # Calcular espacio no particionado
                        partitioned_space += size
                        partition_count += 1  # Contabilizar particiones
                        is_unpartitioned = False  # Indicar que no es un disco sin particiones

                        logger.info(f"SHORT_DESCRIPTION (name): {name}")
                        logger.info(f"DEVICE_NAME (device_name): {device_name}")
                        logger.info(f"PARTITION_SIZE (size): {size} bytes")
                        logger.info(f"ATTACHMENT_POINT (mountpoint): {mountpoint}")
                        logger.info("-------------------------------------")

            # Calcular espacio no particionado
            available_space = device_size - partitioned_space

            logger.info(f"-> Cantidad de particiones: {partition_count}")
            logger.info(f"-> Espacio particionado: {partitioned_space} bytes")
            logger.info(f"-> Espacio no particionado: {available_space} bytes")

            # Calcular committed_size_bytes como espacio particionado
            committed_size_bytes = partitioned_space

            
            # Actualizar la columna "committed_size" en la tabla t_storage
            logger.info("Actualizando la columna 'committed_size' en la tabla t_storage...")
            update_storage_committed_size(device_name, committed_size_bytes)  # Aquí se pasa solo el espacio particionado

            if is_unpartitioned:
                logger.warning(f"La unidad '{device_path}' no se encuentra particionada.")
                if available_space >= product_description:
                    try:
                        # Inicializar la unidad con una etiqueta de disco
                        logger.info(f"Inicializando la unidad '{device_path}' con una etiqueta de disco...")
                        initialize_disk(workorder_flag, device_name, product_description, t_workorder, name, mountpoint, registered_domain)

                    except Exception as e:
                        logger.error(f"ERROR: Error inesperado al Inicializar la unidad  '{device_path}': {str(e)}")
                else:
                    logger.error(f"ERROR: No hay suficiente espacio disponible para crear una partición de {product_description} bytes.")
            else:
                logger.warning(f"La unidad '{device_path}' se encuentra particionada previamente.")
                if available_space >= product_description:
                    # Llamar a la función create_subsequencing_partition
                    create_subsequencing_partition(workorder_flag, device_name, "logical", "ext4", product_description, t_workorder, name, mountpoint, product_description, registered_domain)
                else:
                    logger.error(f"ERROR: No hay suficiente espacio disponible para crear una partición de {product_description} bytes.")
        else:
            logger.warning(f"La unidad '{device_path}' no existe")

        cursor.close()
        connection.close()

    except Exception as e:
        logger.error(f"ERROR inesperado: {str(e)}")

# Función para calcular el punto de inicio de una nueva particion
def calculate_new_partition_start(device_name):
    try:
        factor = 17920
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

           
            new_partition_start_bytes = total_partition_size_bytes + factor

            logger.info(f"Punto de inicio de la nueva partición (calculate_new_partition_start): {new_partition_start_bytes} bytes")

            return total_partition_size_bytes, None, new_partition_start_bytes
        else:
            logger.warning(f"No se encontraron particiones existentes en el dispositivo '{device_name}'.")
            # Retorna un punto de inicio predeterminado en bytes
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
        next_partition_number = 1  # Inicializar con 1
        while next_partition_number in existing_partition_numbers:
            next_partition_number += 1

        logger.info(f"Siguiente número de partición disponible para '{device_name}': {next_partition_number}")
        return next_partition_number

    except Exception as e:
        logger.error(f"Error al calcular el siguiente número de partición: {str(e)}")
        return None

# Función para inicializar el disco con una tabla de particiones GPT
def initialize_disk(workorder_flag, device_name, product_description, t_workorder, name, mountpoint, registered_domain):
    try:
        # Conexión a la base de datos MySQL
        conn = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        
        cursor = conn.cursor(buffered=True)

        # Consultar el valor actual de 'storage_flag' para el dispositivo especificado
        cursor.execute(f"SELECT storage_flag FROM t_storage WHERE DEVICE_NAME = %s", (device_name,))
        storage_flag = cursor.fetchone()

        if storage_flag and storage_flag[0] == 0:
            # La unidad no tiene una tabla de particiones GPT, por lo que podemos proceder con la inicialización
            logger.info(f"Inicializando el disco '/dev/{device_name}' con una tabla de particiones GPT...")

            # Comando para inicializar el disco con una tabla de particiones GPT
            initialize_command = f"sudo parted /dev/{device_name} mklabel gpt"

            logger.info(f"Ejecutando el comando de inicialización: '{initialize_command}'")

            # Ejecutar el comando "initialize_command"
            auto_confirm_initialize_disk(initialize_command)
            subprocess.run(["sleep", "30"])

            partition_label_check_command = f"sudo parted /dev/{device_name} print"

            subprocess.run(partition_label_check_command, shell=True, check=True)
            subprocess.run(["sleep", "10"])

            # Comprobar si la tabla de particiones GPT se creó exitosamente
            check_command = f"sudo gdisk -l /dev/{device_name} | grep 'GPT'"
            check_result = subprocess.run(check_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

            if check_result.returncode == 0:
                logger.info(f"Tabla de particiones GPT creada con éxito en '/dev/{device_name}'.")

                # Llamar a la función update_storage_flag
                update_storage_flag(workorder_flag, device_name, product_description, t_workorder, name, mountpoint, registered_domain)
            else:
                logger.error(f"ERROR: Fallo al crear la tabla de particiones GPT en '/dev/{device_name}': {check_result.stderr}")
        else:
            # La unidad ya tiene una inicialización previa o storage_flag no es 0
            logger.info(f"La unidad '/dev/{device_name}' ya cuenta con una inicialización previa o no es necesario inicializar.")

            # Llamar a la función create_partition
            create_partition(workorder_flag, device_name, "logical", "ext4", product_description, t_workorder, name, mountpoint, product_description, registered_domain)

        # Cerrar el cursor y la conexión a la base de datos
        cursor.close()
        conn.close()

    except Exception as e:
        logger.error(f"ERROR inesperado: {str(e)}")

# Función para autoconfirmar la ejecución del comando "initialize_command"
def auto_confirm_initialize_disk(initialize_command):
    try:
        response = "Yes"  # Configura la respuesta como "Yes" (automática)
        logger.info(f"(auto_confirm_initialize_disk) Ejecutando el comando 'initialize_command': '{initialize_command}'")

        # Utiliza subprocess.Popen para ejecutar el comando y obtener la salida
        process = subprocess.Popen(initialize_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
        
        # Monitorea la salida para detectar la pregunta y responder automáticamente
        output, _ = process.communicate(input=response.encode('utf-8'), timeout=30)

        # Registra la salida en el archivo de registro
        logger.info(output.decode('utf-8').strip())

        process.wait()  # Espera a que el proceso termine
        
        logger.info(f"Esperando a que se ejecute el comando '{initialize_command}'...")

        time.sleep(10)

    except subprocess.CalledProcessError as e:
        logger.error(f"(auto_confirm_initialize_disk) ERROR: Error al ejecutar el comando '{initialize_command}': {e}")
    except Exception as e:
        logger.error(f"(auto_confirm_initialize_disk) ERROR: Error inesperado al ejecutar el comando '{initialize_command}': {str(e)}")

def update_storage_flag(workorder_flag, device_name, product_description, t_workorder, name, mountpoint, registered_domain):
    try:
        logger.info(f"Leyendo la tabla: '{MYSQL_STORAGE_TABLE}'...")
        # Configuración de la conexión a MySQL
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()

        # Obtener los encabezados de la tabla
        logger.info(f"Actualizando la tabla '{MYSQL_STORAGE_TABLE}'...")
        cursor.execute(f"UPDATE {MYSQL_STORAGE_TABLE} SET storage_flag = 1 WHERE device_name = %s", (device_name,))

        # Confirmar los cambios en la base de datos
        logger.info("Confirmando los cambios en la base de datos...")
        connection.commit()

        # Cerrar la conexión
        logger.info("Cerrando la conexión a la base de datos...")
        connection.close()

        logger.info(f"El atributo 'storage_flag' para '{device_name}' se ha actualizado a 1 en la base de datos.")

        # Llamar a la función create_partition
        logger.info("Llamando a la función create_partition...")
        create_partition(workorder_flag, device_name, "logical", "ext4", product_description, t_workorder, name, mountpoint, product_description, registered_domain)

    except Exception as e:
        logger.error(f"Error al actualizar 'storage_flag': {str(e)}")


def create_partition(workorder_flag, device_name, partition_type, filesystem_type, partition_size, t_workorder, name, mountpoint, product_description, registered_domain):
    created_partition_info = None  # Inicializar la variable fuera del bloque try
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

            logger.info(f"Tamaño de la última partición: {last_partition_size_bytes} bytes.")
            logger.info(f"Punto de inicio de la última partición: {last_partition_start_bytes} bytes.")
            logger.info(f"Punto de inicio de la nueva partición (create_partition): {new_partition_start_bytes} bytes")
        else:
            logger.info(f"El dispositivo '{device_name}' no tiene particiones previas. Utilizando punto de inicio predeterminado.")
            new_partition_start_bytes = 1048576  # Punto de inicio predeterminado

        # Calcular un punto de inicio alineado en sectores
        block_size = 512  # Tamaño de bloque típico
        aligned_start_sectors = new_partition_start_bytes // block_size


        # Calcular el tamaño de la partición en sectores
        partition_size_sectors = partition_size // block_size

        partition_end_sectors = aligned_start_sectors + partition_size_sectors

        # Comando parted para crear una partición primaria ext4 con el tamaño requerido y el punto de inicio en sectores
        partition_command = f"sudo parted /dev/{device_name} mkpart {partition_type} {aligned_start_sectors}s {partition_end_sectors}s"

        logger.info(f"(create_partition) Procediendo a particionar la unidad: '/dev/{device_name}' con un tamaño de: {partition_size} bytes, equivalente a {partition_size_sectors} sectores.")
        
        # Verificar si se creó la partición exitosamente
        partition_name = f"/dev/{device_name}{next_partition_number}"

        # Ejecutar el comando de partición
        auto_confirm_create_partition(partition_command)
        logger.info(f"(create_partition) Ejecutando el comando: '{partition_command}'")

        #subprocess.run(partition_command,  shell=True, check=True)

        logger.info(f"Esperando a que se complete la partición...")

        # Esperar a que se complete el proceso de partición
        subprocess.run(["sleep", "10"])

        # Llamar a la funcion check_partition
        check_partition(workorder_flag, device_name, partition_name, filesystem_type, registered_domain, partition_size, t_workorder, created_partition_info, next_partition_number, aligned_start_sectors, partition_end_sectors)

            
    except subprocess.CalledProcessError as e:
        logger.error(f"ERROR: Error al crear la partición en la unidad '/dev/{device_name}': {e}")
    except Exception as e:
        logger.error(f"ERROR: Error muy inesperado al crear la partición en la unidad '/dev/{device_name}': {str(e)}")

# Función para autoconfirmar la ejecución del comando "partition_command"
def auto_confirm_create_partition(partition_command):
    try:
        response = "y"  # Configura la respuesta como "y" (automática)
        if response not in ('y', 'n', 'i'):
            raise ValueError("Response must be 'y', 'n', or 'i")

        logger.info(f"(auto_confirm_create_partition) Ejecutando el comando 'partition_command': '{partition_command}'")

        # Utiliza subprocess.Popen para ejecutar el comando y obtener la salida
        process = subprocess.Popen(partition_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
        
        # Inicializa una variable para rastrear si la pregunta se ha detectado
        question_detected = False
        
        # Monitorea la salida para detectar la pregunta y responder automáticamente
        while True:
            output = process.stdout.readline().decode('utf-8')
            if output:
                logger.info(output.strip())  # Registra la salida en el archivo de registro
                if "Is this still acceptable to you?" in output:
                    question_detected = True
                    process.stdin.write(f"{response}\n".encode('utf-8'))
                    process.stdin.flush()
            else:
                break  # Sal del bucle cuando la salida está vacía
            
        process.wait()  # Espera a que el proceso termine
        
        if question_detected:
            logger.info("Pregunta detectada y respondida automáticamente.")
        else:
            logger.info("No se detectó la pregunta.")

        logger.info(f"Esperando a que se ejecute el comando '{partition_command}'...")

        time.sleep(10)

    except subprocess.CalledProcessError as e:
        logger.error(f"(auto_confirm_create_partition) ERROR: Error al ejecutar el comando '{partition_command}': {e}")
    except Exception as e:
        logger.error(f"(auto_confirm_create_partition) ERROR: Error inesperado al ejecutar el comando '{partition_command}': {str(e)}")

def create_subsequencing_partition(workorder_flag, device_name, partition_type, filesystem_type, partition_size, t_workorder, name, mountpoint, product_description, registered_domain, autoconfirm=False):

    created_partition_info = None  # Inicializar la variable fuera del bloque try
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

            logger.info(f"Tamaño de la última partición: {last_partition_size_bytes} bytes.")
            logger.info(f"Punto de inicio de la última partición: {last_partition_start_bytes} bytes.")
            logger.info(f"Punto de inicio de la nueva partición (create_subsequencing_partition): {new_partition_start_bytes} bytes")
        else:
            logger.info(f"El dispositivo '{device_name}' no tiene particiones previas. Utilizando punto de inicio predeterminado.")
            new_partition_start_bytes = 1048576  # Punto de inicio predeterminado

        # Calcular un punto de inicio alineado en sectores
        block_size = 512  # Tamaño de bloque típico
        aligned_start_sectors = new_partition_start_bytes // block_size

        # Calcular el tamaño de la partición en sectores
        partition_size_sectors = partition_size // block_size
        partition_end_sectors = aligned_start_sectors + partition_size_sectors + 1

        # Comando parted para crear una partición primaria ext4 con el tamaño requerido y el punto de inicio en sectores
        partition_command = f"sudo parted /dev/{device_name} mkpart {filesystem_type} {aligned_start_sectors}s {partition_end_sectors}s"


        logger.info(f"(create_subsequencing_partition) Procediendo a particionar la unidad: '/dev/{device_name}' con un tamaño de: {partition_size} bytes, equivalente a {partition_size_sectors} sectores.")

        # Verificar si se creó la partición exitosamente
        partition_name = f"/dev/{device_name}{next_partition_number}"

        logger.info(f"(create_subsequencing_partition) Ejecutando el comando: '{partition_command}'")

        auto_confirm_create_subsequencing_partition(partition_command)
        #subprocess.run(partition_command, shell=True, check=True)


        logger.info(f"create_subsequencing_partition: Esperando a que se complete la partición '{partition_name}'...")

        # Esperar a que se complete el proceso de partición
        subprocess.run(["sleep", "10"])

        # Llamar a la funcion check_partition
        check_partition(workorder_flag, device_name, partition_type, partition_name, filesystem_type, registered_domain, partition_size, t_workorder, created_partition_info, next_partition_number, name, mountpoint, product_description, aligned_start_sectors, partition_end_sectors)

    except subprocess.CalledProcessError as e:
        logger.error(f"create_subsequencing_partition: ERROR: Error al crear la partición en la unidad '/dev/{device_name}': {e}")
    except Exception as e:
        logger.error(f"create_subsequencing_partition: ERROR: Error muy inesperado al crear la partición '{next_partition_number}' en la unidad '/dev/{device_name}': {str(e)}")

# Función para autoconfirmar la ejecución del comando "partition_command"
def auto_confirm_create_subsequencing_partition(partition_command):
    try:
        response = "y"  # Configura la respuesta como "y" (automática)
        if response not in ('y', 'n', 'i'):
            raise ValueError("Response must be 'y', 'n', or 'i")

        logger.info(f"(auto_confirm_create_partition) Ejecutando el comando 'partition_command': '{partition_command}'")

        # Utiliza subprocess.Popen para ejecutar el comando y obtener la salida
        process = subprocess.Popen(partition_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
        
        # Inicializa una variable para rastrear si la pregunta se ha detectado
        question_detected = False
        
        # Monitorea la salida para detectar la pregunta y responder automáticamente
        while True:
            output = process.stdout.readline().decode('utf-8')
            if output:
                logger.info(output.strip())  # Registra la salida en el archivo de registro
                if "Is this still acceptable to you?" in output:
                    question_detected = True
                    process.stdin.write(f"{response}\n".encode('utf-8'))
                    process.stdin.flush()
            else:
                break  # Sal del bucle cuando la salida está vacía
            
        process.wait()  # Espera a que el proceso termine
        
        if question_detected:
            logger.info("Pregunta detectada y respondida automáticamente.")
        else:
            logger.info("No se detectó la pregunta.")

        logger.info(f"Esperando a que se ejecute el comando '{partition_command}'...")

        time.sleep(10)

    except subprocess.CalledProcessError as e:
        logger.error(f"(auto_confirm_create_partition) ERROR: Error al ejecutar el comando '{partition_command}': {e}")
    except Exception as e:
        logger.error(f"(auto_confirm_create_partition) ERROR: Error inesperado al ejecutar el comando '{partition_command}': {str(e)}")

# Función para verificar si se creó la partición exitosamente
def check_partition(workorder_flag, device_name, partition_type, partition_name, filesystem_type, registered_domain, partition_size, t_workorder, created_partition_info, next_partition_number, name, mountpoint, product_description, aligned_start_sectors, partition_end_sectors):
    try:
        # Verificar si se creó la partición exitosamente
        check_partition_command = f"sudo parted /dev/{device_name} print | grep {next_partition_number}"
        partition_result = subprocess.run(check_partition_command, shell=True, stderr=subprocess.PIPE)

        if partition_result.returncode == 0:
            # Obtener el ID de la partición recién creada
            partition_name = f"/dev/{device_name}{next_partition_number}"

            created_partition_info = {
                "device_name": device_name,
                "partition_name": partition_name,
                "partition_number": next_partition_number,
                "filesystem_type": filesystem_type,
                "registered_domain": registered_domain,
                "partition_size": partition_size
            }

            # Esperar hasta que la partición esté completamente disponible
            while not os.path.exists(partition_name):
                logger.info(f"La partición '{partition_name}' aún no está disponible. Reintentando particionar...")
                time.sleep(2)
                # Comando parted para crear una partición primaria ext4 con el tamaño requerido y el punto de inicio en sectores
                partition_command = f"sudo parted /dev/{device_name} mkpart {filesystem_type} {aligned_start_sectors}s {partition_end_sectors}s"

                logger.info(f"Procediendo a reintentar particionar la unidad: '/dev/{device_name}'...")

                subprocess.run(partition_command, shell=True, check=True)
                subprocess.run(["sleep", "10"])

            logger.info(f"Partición '{partition_name}' detectada. Procediendo con el formateo.")

            # Luego de crear la partición con éxito, llama a format_partition
            format_partition(workorder_flag, device_name, partition_name, filesystem_type, registered_domain, partition_size, t_workorder, created_partition_info)
        else:
            logger.error(f"ERROR: Error al crear la partición en la unidad '/dev/{device_name}': {partition_result.stderr.decode('utf-8')}")

    except Exception as e:
        logger.error(f"ERROR: Error al comprobar la particion '{next_partition_number}' de la unidad '/dev/{device_name}' : {str(e)}")


# Función para actualizar datos de la unidad de disco
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
        logger.info(f"Procediendo a formatear la particion '{partition_name}' con sistema de archivos '{filesystem_type}' para el dominio '{registered_domain}'.")

        
        # Formatear la partición con el sistema de archivos especificado
        format_command = f"sudo mkfs -t {filesystem_type} {partition_name}"
        logger.info(f"Ejecutando el comando '{format_command}'.")

        process = subprocess.Popen(format_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = process.communicate()

        if process.returncode == 0:
            logger.info(f"Partición '{partition_name}' formateada con éxito con sistema de archivos '{filesystem_type}'.")
            # Llamar a la función para montar la partición después de formatear
            mount_partition(workorder_flag, device_name, partition_name, registered_domain, partition_size, t_workorder, created_partition_info)
        else:
            error_message = err.decode("utf-8").strip()
            raise Exception(f"ERROR: Error al formatear la partición '{partition_name}': {error_message}")

    except Exception as e:
        logger.error(f"ERROR: Error al intentar formatear la partición '{partition_name}': {str(e)}")

# Función para montar partición con REGISTERED_DOMAIN
def mount_partition(workorder_flag, device_name, partition_name, registered_domain, partition_size, t_workorder, created_partition_info):
    try:
        if not os.path.exists(target_dir):
            raise Exception(f"ERROR: El directorio '{target_dir}' no existe.")

        mounting_path = os.path.join(target_dir, registered_domain)
        logger.info(f"Montando la partición '{partition_name}' en '{mounting_path}'...")

        # Verificar si el punto de montaje existe
        if not os.path.exists(mounting_path):
            logger.info(f"El punto de montaje '{mounting_path}' no existe. Creándolo...")

            # Usar 'sudo mkdir' para crear el directorio
            create_dir_command = f"sudo mkdir -p {mounting_path}"
            create_dir_process = subprocess.Popen(create_dir_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            create_dir_process.communicate()  # Esperar a que se complete el proceso

            if create_dir_process.returncode == 0:
                logger.info(f"Directorio '{mounting_path}' creado con éxito.")
            else:
                error_message = create_dir_process.stderr.decode("utf-8").strip()
                raise Exception(f"ERROR: Error al crear el directorio '{mounting_path}': {error_message}")

        # Montar la partición
        mount_command = f"sudo mount -t auto {partition_name} {mounting_path}"
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
        logger.error(f"ERROR: Error al montar la partición '{partition_name}' en '{mounting_path}': {str(e)}")

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
            
            update_workorder_table(workorder_flag, device_name, mounting_path, created_partition_info, t_workorder)

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

# Llamar a esta función después de haber creado la partición con éxito
def update_workorder_table(workorder_flag, device_name, mounting_path, created_partition_info, t_workorder):
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
                logger.info(f"Valor actualizado de workorder_flag para la orden '{t_workorder}': {workorder_flag_value}")\

                # Llamar a la funcion para agregar entradas en /etc/fstab para montar las particiones al reiniciar el sistema
                add_to_fstab(workorder_flag, device_name, mounting_path, created_partition_info, t_workorder, filesystem_type="ext4", options="defaults", dump=0, pass_num=0)
            
            else:
                logger.info(f"No se encontró la orden '{t_workorder}' en la tabla '{MYSQL_WORKORDER_TABLE}'.")

            cursor.close()
            connection.close()
            
            # Forzar un cambio de registro para evitar la repetición
            return True
            
        except Exception as e:
            connection.rollback()  # Deshacer la transacción si ocurre un error
            raise e  # Re-lanzar la excepción para manejarla en un nivel superior

    except Exception as e:
        logger.error(f"ERROR: Error al actualizar los campos en la tabla '{MYSQL_WORKORDER_TABLE}' para la orden: '{t_workorder}'.")
        logger.error(str(e))

# Función para agregar entradas en /etc/fstab para montar las particiones al reiniciar el sistema
def add_to_fstab(workorder_flag, device_name, mounting_path, created_partition_info, t_workorder, filesystem_type="ext4", options="defaults", dump=0, pass_num=0):
    try:
        fstab_path = "/etc/fstab"

        logger.info(f"Agregando entradas en '{fstab_path}' para montar las particiones al reiniciar el sistema...")

        # Comprobar si el archivo /etc/fstab ya contiene una entrada para el dispositivo
        with open(fstab_path, "r") as fstab_file:
            fstab_content = fstab_file.read()
            if f"{device_name} " in fstab_content:
                logger.info(f"La entrada para '{device_name}' ya existe en '{fstab_path}'.")
                return

        # Agregar una nueva entrada al archivo /etc/fstab con "sudo"
        add_fstab_command = f"echo '{device_name} {mounting_path} {filesystem_type} {options} {dump} {pass_num}' | sudo tee -a {fstab_path}"

        logger.info(f"Agregando entrada para '{device_name}' en '{fstab_path}' usando sudo...")

        subprocess.run(add_fstab_command, shell=True, check=True)

        logger.info(f"Entrada para '{device_name}' agregada a '{fstab_path}'. La partición se montará automáticamente al reiniciar el sistema.")

    except subprocess.CalledProcessError as e:
        logger.error(f"ERROR: Error al agregar entrada a '{fstab_path}' usando sudo: {e}")

    except FileNotFoundError:
        logger.error(f"ERROR: El archivo '{fstab_path}' no existe. Asegúrate de estar ejecutando el script con permisos de superusuario (sudo).")

    except PermissionError:
        logger.error(f"ERROR: No tienes permiso para modificar '{fstab_path}'. Asegúrate de estar ejecutando el script con permisos de superusuario (sudo).")

    except Exception as e:
        logger.error(f"ERROR: Error al agregar entrada a '{fstab_path}': {str(e)}")


def process_workorders():
    read_workorder_table()
    print("------------------------------------------------------------------------------------------------")

# Llamar a la función principal
process_workorders()
