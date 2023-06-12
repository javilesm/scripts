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
  unidades=$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -e '^NAME' -e 'disk' | awk '{print $1, $2}')
  unidad=$(dialog --stdout --menu "Seleccione la unidad a particionar:" 10 50 0 $unidades)
  # Validar la unidad ingresada
  if ! [ -b "/dev/$unidad" ]; then
    echo "La unidad especificada no existe."
    exit 1
  fi

  # Comprobar si la unidad ha sido montada previamente
  if lsblk -o MOUNTPOINT | grep -q "^/dev/$unidad"; then
    echo "La unidad seleccionada ya está montada. No se puede particionar."
    exit 1
  fi

}

function confirm() {
  num_particiones=$contador
  # Mostrar la información ingresada y solicitar confirmación al usuario
  dialog --yesno "Se crearán '$num_particiones' particiones, una para cada dominio en la unidad: '/dev/$unidad'. ¿Desea proceder?" 10 50
  response=$?
  if [ $response -eq 0 ]; then
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
