import os
import subprocess
import json
import time
import datetime
from colorama import Fore, Style
import logging
from colorlog import getLogger
import pexpect
import shlex
import parted

script_directory = os.path.dirname(os.path.abspath(__file__))
log_directory = os.path.join(script_directory, "partition_module_logs")
log_file_name = os.path.join(log_directory, datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S') + '_create_partition_log.txt')  # el sistema de registro con la fecha y hora actual en el nombre del archivo

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


def configure_partition(device_path, workorder_flag, device_name, t_workorder, name, mountpoint, product_description, registered_domain, filesystem_type):
    created_partition_info = None  # Inicializar la variable fuera del bloque try
    try:
        logger.info(f"(partition_module) Ejecutando sub-script: 'create_partition'...")
        logger.info(f"(partition_module) Particionando el dispositivo '{device_name}' de acuerdo con la orden de trabajo: '{t_workorder}' para el dominio '{registered_domain}'")

        # Obtener el siguiente número de partición disponible
        next_partition_number = calculate_next_partition_number(device_name)

        # Verificar si el dispositivo tiene particiones previas
        lsblk_info = subprocess.check_output(["lsblk", "-Jbno", "NAME,SIZE,MOUNTPOINT", f"/dev/{device_name}"], text=True)
        lsblk_info = json.loads(lsblk_info)
        device_partitions = lsblk_info.get("blockdevices", [])[0].get("children", [])

        if device_partitions:
            last_partition_size_bytes, last_partition_start_bytes, new_partition_start_bytes = calculate_new_partition_start(device_name)

            logger.info(f"(partition_module) Tamaño de la última partición: {last_partition_size_bytes} bytes.")
            logger.info(f"(partition_module) Punto de inicio de la última partición: {last_partition_start_bytes} bytes.")
            logger.info(f"(partition_module) Punto de inicio de la nueva partición (create_partition): {new_partition_start_bytes} bytes")
        else:
            logger.info(f"(partition_module) El dispositivo '{device_path}' no tiene particiones previas. Utilizando punto de inicio predeterminado.")
            new_partition_start_bytes = 1048576  # Punto de inicio predeterminado

        # Calcular un punto de inicio alineado en sectores
        block_size = 512  # Tamaño de bloque típico
        aligned_start_sectors = new_partition_start_bytes // block_size


        # Calcular el tamaño de la partición en sectores
        partition_size_sectors = product_description // block_size

        partition_end_sectors = aligned_start_sectors + partition_size_sectors

        logger.info(f"(partition_module) Procediendo a particionar la unidad: '{device_path}' con un tamaño de: {product_description} bytes, equivalente a {partition_size_sectors} sectores.")
        
        # Verificar si se creó la partición exitosamente
        partition_name = f"{device_path}{next_partition_number}"

        check_gpt(device_path)

        # Esperar a que se complete el proceso de partición
        subprocess.run(["sleep", "2"])

        # Ejecutar el comando de partición
        create_partition(device_path, next_partition_number, filesystem_type, aligned_start_sectors, partition_end_sectors)

        logger.info(f"(partition_module) Esperando a que se complete la partición...")

        # Esperar a que se complete el proceso de partición
        subprocess.run(["sleep", "10"])

        check_gpt(device_path)

    except subprocess.CalledProcessError as e:
        logger.error(f"partition_module: ERROR: Error al crear la partición '/dev/{device_name}/{next_partition_number}': {e}")
    except Exception as e:
        logger.error(f"partition_module: ERROR: Error muy inesperado al crear la partición '{next_partition_number}' en la unidad '/dev/{device_name}': {str(e)}")


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

def create_partition(device_path, next_partition_number, filesystem_type, aligned_start_sectors, partition_end_sectors):
    try:
        partition_command1 = f"sudo parted {device_path} print"
        # Comando parted para crear una partición primaria ext4 con el tamaño requerido y el punto de inicio en sectores
        partition_command2 = f"sudo parted {device_path} mkpart {filesystem_type} {aligned_start_sectors}s {partition_end_sectors}s"

        subprocess.run(partition_command1,  shell=True, check=True)
        subprocess.run(["sleep", "1"])

        response = "y"  # Configura la respuesta como "y" (automática)
        if response not in ('y', 'n', 'i'):
            raise ValueError("Response must be 'y', 'n', or 'i")

        # Utiliza subprocess.Popen para ejecutar el comando y obtener la salida
        process = subprocess.Popen(partition_command2, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
        
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

        time.sleep(10)

    except subprocess.CalledProcessError as e:
        logger.error(f"(auto_confirm_create_partition) ERROR: Error al particionar la unidad {device_path}': {e}")
    except Exception as e:
        logger.error(f"(auto_confirm_create_partition) ERROR: Error inesperado al particionar la unidad {device_path}': {str(e)}")

def check_gpt(device_path):
    try:
        # Comando para comprobar si la unidad tiene una tabla de particiones GPT
        check_command = f"sudo gdisk -l {device_path} | grep 'GPT'"

        # Ejecutar el comando y capturar la salida
        result = subprocess.run(check_command, shell=True, capture_output=True, text=True)

        # Imprimir el resultado
        print(result.stdout)

    except subprocess.CalledProcessError as e:
        print(f"Error al ejecutar el comando: {e}")
