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
  echo "Se crearán '$num_particiones' particiones en la unidad: '/dev/$unidad'."
  echo "¿Desea proceder?"
  source "$CONFIRM_SCRIPT" # Incluye el archivo confirmacion.sh
  echo "Importando '$CONFIRM_SCRIPT'..."
  # Pide confirmación al usuario
  if confirm " ¿Está seguro de que desea ejecutar la acción?"; then
    echo "El usuario confirmó la ejecución."
    # Coloca aquí las acciones a realizar si el usuario confirma
    format_parts
    iteration
    edit_fstab
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
  sudo mkfs.$formato "/dev/${unidad}"
  echo "Las particiones creadas fueron formateadas exitosamente."
  echo "Filtrando la unidad de disco xvdf:"
  lsblk --paths | grep $unidad
}

function iteration() {
  # Obtenemos la partición correspondiente
  particion="/dev/${unidad}"
    
  # Montar la partición
  echo "Montando la partición: '$particion' --> '$site_root'"
  if sudo mount "$particion" "$site_root"; then
    echo "Partición '$particion' fue montada en '$site_root'."
  else
    echo "Error al montar la partición '$particion' en '$site_root'."
    echo "Asegúrese de que la partición exista y el punto de montaje esté disponible."
    echo "Revise los permisos y la configuración del sistema."
  fi
  lsblk --paths | grep $unidad
}

# Agregar entradas en /etc/fstab para montar las particiones al reiniciar el sistema
function edit_fstab() {
  # Agregar entradas en /etc/fstab para montar las particiones al reiniciar el sistema
  echo "Agregar entradas en /etc/fstab para montar la particion '$particion' al reiniciar el sistema..."
  echo "${particion//\"/} ${site_root//\"/} ${formato//\"/} defaults 0 0" | sudo tee -a /etc/fstab
}

function nextcloud_partitions() {
  echo "****************NEXTCLOUD PARTITIONS****************"
  get_dev
  confirm
  echo "****************ALL DONE****************"
}
nextcloud_partitions
