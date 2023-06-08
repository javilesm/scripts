#!/bin/bash
# nextcloud_partitions.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
CONFIRM_SCRIPT="$PARENT_DIR/utilities/confirm"
DOMAINS_FILE="domains.txt"
DOMAINS_PATH="$PARENT_DIR/Postfix/$DOMAINS_FILE"
HTML_PATH="/var/www"
host="nextcloud"
site_root="$HTML_PATH/$host"
# Obtener la unidad a particionar y el número de particiones del usuario
function get_dev() {
  echo "Unidades de disco disponibles:"
  lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -e '^NAME' -e 'disk' | awk '{print $1, $2}'
  echo "--------------------------------------------------"

  read -p "Ingrese el nombre de la unidad a particionar (ejemplo: sda, xvdf): " unidad
  # Validar la unidad ingresada
  if ! [ -b "/dev/$unidad" ]; then
    echo "La unidad especificada no existe."
    exit 1
  fi
}

function confirm() {
  num_particiones=1
   # Mostrar la información ingresada y solicitar confirmación al usuario
  echo "Se crearán '$num_particiones' particiones, una para cada dominio en la unidad: '/dev/$unidad'."
  echo "¿Desea proceder?"
  source "$CONFIRM_SCRIPT" # Incluye el archivo confirmacion.sh
  echo "Importando '$CONFIRM_SCRIPT'..."
  # Pide confirmación al usuario
  if confirm " ¿Está seguro de que desea ejecutar la acción?"; then
    echo "El usuario confirmó la ejecución."
    # Coloca aquí las acciones a realizar si el usuario confirma
    format_parts
    iteration
  else  
    echo "El usuario canceló la ejecución."
    # Coloca aquí las acciones a realizar si el usuario cancela
    exit 1
  fi
}


# Formatear las particiones con el formato especificado por el usuario
function format_parts() {
  echo "Procediendo a formatear las particiones creadas."
  formato="ext4"

  for i in $(seq $num_particiones); do
    sudo mkfs.$formato "/dev/${unidad}${i}"
  done
  echo "Las particiones creadas fueron formateadas exitosamente."
  echo "Filtrando la unidad de disco xvdf:"
  lsblk --paths | grep $unidad
}

function iteration() {
  target_dir="/var/www/"
  # Leer la lista de dominios
  IFS=$'\n' read -d '' -r -a dominios < "$DOMAINS_PATH"
  
  # Verificar que la cantidad de dominios sea suficiente
  if (( ${#dominios[@]} < num_particiones )); then
    echo "No hay suficientes dominios disponibles."
    return
  fi

  # Iteramos sobre la lista de particiones
  for ((i=0; i<num_particiones; i++)); do
    # Obtenemos la partición correspondiente
    particion="/dev/${unidad}$((i+1))"
    
    # Obtenemos el dominio correspondiente
    dominio="${dominios[i]}"
    host="${dominio%%.*}"
    mounting_point=$target_dir/$host
    # Montar la partición
    echo "Montando la partición: $particion $mounting_point"
    if sudo mount "$particion" "$mounting_point"; then
      echo "Partición '$particion' fue montada en '$mounting_point'."
    else
      echo "Error al montar la partición '$particion' en '$mounting_point'."
      echo "Asegúrese de que la partición exista y el punto de montaje esté disponible."
      echo "Revise los permisos y la configuración del sistema."
    fi
    lsblk --paths | grep $unidad
    sleep 3
    # Agregar entradas en /etc/fstab para montar las particiones al reiniciar el sistema
    echo "${particion//\"/} ${mounting_point//\"/} ${formato//\"/} defaults 0 0" | sudo tee -a /etc/fstab
    echo "-------------------------------------------------------------------------"
  done
  lsblk --paths | grep $unidad
}

# Agregar entradas en /etc/fstab para montar las particiones al reiniciar el sistema
function edit_fstab() {
  for i in $(seq $num_particiones); do
    echo "$partition_path $mount_path $formato defaults 0 0" | sudo tee -a /etc/fstab
  done
}

function nextcloud_partitions() {
  echo "****************WEB PARTITIONS****************"
  count_domains
  get_dev
  confirm
  echo "****************ALL DONE****************"
}
nextcloud_partitions
