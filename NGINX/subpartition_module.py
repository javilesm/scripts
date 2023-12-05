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
log_directory = os.path.join(script_directory, "subpartition_module_logs")
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
        logger.info(f"(subpartition_module) Ejecutando sub-script: 'create_partition'...")
        logger.info(f"(subpartition_module) Particionando el dispositivo '{device_name}' de acuerdo con la orden de trabajo: '{t_workorder}' para el dominio '{registered_domain}'")

        # Obtener el siguiente número de partición disponible
        next_partition_number = calculate_next_partition_number(device_name)

        # Verificar si el dispositivo tiene particiones previas
        lsblk_info = subprocess.check_output(["lsblk", "-Jbno", "NAME,SIZE,MOUNTPOINT", f"/dev/{device_name}"], text=True)
        lsblk_info = json.loads(lsblk_info)
        device_partitions = lsblk_info.get("blockdevices", [])[0].get("children", [])

        if device_partitions:
            last_partition_size_bytes, last_partition_start_bytes, new_partition_start_bytes = calculate_new_partition_start(device_name)

            logger.info(f"(subpartition_module) Tamaño de la última partición: {last_partition_size_bytes} bytes.")
            logger.info(f"(subpartition_module) Punto de inicio de la última partición: {last_partition_start_bytes} bytes.")
            logger.info(f"(subpartition_module) Punto de inicio de la nueva partición (create_partition): {new_partition_start_bytes} bytes")
        else:
            logger.info(f"(subpartition_module) El dispositivo '{device_name}' no tiene particiones previas. Utilizando punto de inicio predeterminado.")
            new_partition_start_bytes = 1048576  # Punto de inicio predeterminado

        # Calcular un punto de inicio alineado en sectores
        block_size = 512  # Tamaño de bloque típico
        aligned_start_sectors = new_partition_start_bytes // block_size


        # Calcular el tamaño de la partición en sectores
        partition_size_sectors = product_description // block_size

        partition_end_sectors = aligned_start_sectors + partition_size_sectors

        partition_command1 = f"sudo parted {device_path} print"
        subprocess.run(partition_command1,  shell=True, check=True)
        subprocess.run(["sleep", "1"])

     
        # Verificar si se creó la partición exitosamente
        partition_name = f"{device_path}{next_partition_number}"

        # Ejecutar el comando de partición
        create_partition(device_path, next_partition_number, filesystem_type, aligned_start_sectors, partition_end_sectors, product_description)

        # Esperar a que se complete el proceso de partición
        subprocess.run(["sleep", "10"])
    except subprocess.CalledProcessError as e:
        logger.error(f"subpartition_module: ERROR: Error al crear la partición '{device_path}/{next_partition_number}': {e}")
    except Exception as e:
        logger.error(f"subpartition_module: ERROR: Error muy inesperado al crear la partición '{next_partition_number}' en la unidad '{device_path}': {str(e)}")


# Función para calcular el punto de inicio de una nueva particion
def calculate_new_partition_start(device_name):
    try:
        factor = 17920
        logger.info(f"(subpartition_module) Información sobre el dispositivo '{device_name}':")
        logger.info(f"(subpartition_module) Obteniendo información sobre las particiones existentes en el dispositivo '{device_name}'...")

        lsblk_info = subprocess.check_output(["lsblk", "-Jbno", "NAME,SIZE,MOUNTPOINT", f"/dev/{device_name}"], text=True)
        lsblk_info = json.loads(lsblk_info)
        device_partitions = lsblk_info.get("blockdevices", [])[0].get("children", [])

        if device_partitions:
            logger.info(f"(subpartition_module) Calculando el punto de inicio de la nueva partición en el dispositivo '{device_name}'...")
            total_partition_size_bytes = 0

            for partition_info in device_partitions:
                partition_size_bytes = int(partition_info.get("size", 0))
                total_partition_size_bytes += partition_size_bytes

           
            new_partition_start_bytes = total_partition_size_bytes + factor

            logger.info(f"(subpartition_module) Punto de inicio de la nueva partición (calculate_new_partition_start): {new_partition_start_bytes} bytes")

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
        logger.info(f"(subpartition_module) Obteniendo información sobre las particiones existentes en el dispositivo '{device_name}'...")

        lsblk_info = subprocess.check_output(["lsblk", "-Jbno", "NAME", f"/dev/{device_name}"], text=True)
        lsblk_info = json.loads(lsblk_info)
        device_partitions = lsblk_info.get("blockdevices", [])[0].get("children", [])

        # Crear una lista de números de partición existentes
        existing_partition_numbers = [int(entry["name"].replace(f"{device_name}", "")) for entry in device_partitions]

        # Calcular el siguiente número de partición disponible
        next_partition_number = 1  # Inicializar con 1
        while next_partition_number in existing_partition_numbers:
            next_partition_number += 1

        logger.info(f"(subpartition_module) Siguiente número de partición disponible para '{device_name}': {next_partition_number}")
        return next_partition_number

    except Exception as e:
        logger.error(f"Error al calcular el siguiente número de partición: {str(e)}")
        return None


class PedDevice:
    def __init__(self, device_path):
        self.device_path = device_path
        self.partitions = []

    def wipe(self):
        # Implement the wiping logic here
        print(f"Wiping device: {self.device_path}")
        self.partitions = []

    def addPartition(self, partition):
        self.partitions.append(partition)

    def commit(self):
        # Implement the logic to commit changes here
        print(f"Committing changes to device: {self.device_path}")

    def getPedDevice(self):
        return self

def convert_to_parted_disk(device_path):
    # Replace this with your logic for converting device_path to parted.Disk
    # For simplicity, we'll just return a PedDevice in this example
    return PedDevice(device_path)

def create_partition(device_path, next_partition_number, filesystem_type, aligned_start_sectors, partition_end_sectors, product_description):
    try:
        megabytes = product_description / (1024 * 1024)

        print(f"filesystem: '{filesystem_type}'")
        print(f"size: '{megabytes}'")
        print(f"start: '{aligned_start_sectors}'")

        # Convert device_path to parted.Disk
        disk = convert_to_parted_disk(device_path)

        # Clear existing partitions (optional, be cautious!)
        disk.getPedDevice().wipe()

        # Define partition parameters
        # (size in MiB)
        partition1 = parted.Partition(disk.getPedDevice())
        disk.getPedDevice().addPartition(partition1)

        # Align partitions for optimal performance (optional)
        for partition in disk.getPedDevice().partitions:
            partition.align(optimal=True)

        # Set the filesystem type after aligning the partition
        # Note: Replace 'ext4' with the desired filesystem type
        disk.getPedDevice().partitions[0].setFilesystem(parted.FileSystem(type=filesystem_type, geometry=partition.geometry))

        # Set the starting sector for the partition
        disk.getPedDevice().partitions[0].setStart(aligned_start_sectors)

        # Commit changes to the disk
        disk.getPedDevice().commit()

        print("Partitions created successfully!")

    except Exception as e:
        print(f"Error al crear la partición: {e}")
