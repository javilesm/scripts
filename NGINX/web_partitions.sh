#!/bin/bash
# web_partitions.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
CONFIRM_SCRIPT="$PARENT_DIR/utilities/confirm"
DOMAINS_FILE="domains.csv"
DOMAINS_ENDPOINT="Domains"
DOMAINS_PATH="$PARENT_DIR/$DOMAINS_ENDPOINT/$DOMAINS_FILE"
target_dir="/var/www"

# Función para leer la lista de dominios y contar cuantos dominios existen
function count_domains() {
  # Leer la lista de dominios
  echo "Leyendo la lista de dominios: '$DOMAINS_PATH'..."
  contador=0
  
  while IFS="," read -r hostname owner city state cellphone flag; do
    if [ "$flag" == "CREATE" ]; then
      local host="${hostname#*@}"
      host="${host}"
      echo "Hostname: $host"
      contador=$((contador + 1))
    fi
  done < <(grep -v '^$' "$DOMAINS_PATH")
  
  echo "El archivo '$DOMAINS_PATH' tiene '$contador' elementos con flag 'CREATE'."
}

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
    split_dev
    make_partitions
    format_parts
    iteration
  else  
    echo "El usuario canceló la ejecución."
    # Coloca aquí las acciones a realizar si el usuario cancela
    exit 1
  fi
}

# Calcular el tamaño de cada partición en base al tamaño de la unidad y el número de particiones
function split_dev() {
  tamanio_unidad=$(sudo blockdev --getsize64 "/dev/$unidad")
  tamanio_particion=$((tamanio_unidad / num_particiones / 1024 / 1024)) # en MB

  dialog --msgbox "Se ha calculado el tamaño de cada partición.\n\nTamaño de la unidad: $tamanio_unidad bytes\nTamaño de cada partición: $tamanio_particion MB" 10 50

  # Validar que el tamaño de la partición sea al menos 1MB
  if [ "$tamanio_particion" -lt 1 ]; then
    dialog --msgbox "El tamaño de la partición calculado es menor a 1MB. Ajusta el número de particiones o la unidad a particionar." 10 50
    exit 1
  fi
}

# Crear las particiones
function make_partitions() {
  echo "Creando las particiones..."
  sudo parted "/dev/$unidad" mklabel gpt
  start_sector=2048
  end_sector=$((tamanio_particion * 2048 - 1))

  for i in $(seq $num_particiones); do
    sudo parted "/dev/$unidad" mkpart primary ext4 ${start_sector}s ${end_sector}s
    start_sector=$((end_sector + 1))
    end_sector=$((end_sector + tamanio_particion * 2048))
  done
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
  # Leer la lista de dominios
  echo "Leyendo la lista de dominios..."
  IFS=$'\n' read -d '' -r -a dominios < <(grep -v '^$' "$DOMAINS_PATH" | grep 'CREATE')
  
  # Verificar que la cantidad de dominios sea suficiente
  echo "Verificando que la cantidad de dominios sea suficiente..."
  if (( ${#dominios[@]} < num_particiones )); then
    echo "No hay suficientes dominios disponibles."
    return
  fi

  # Iteramos sobre la lista de particiones
  echo "Iterando sobre la lista de particiones..."
  for ((i=0; i<num_particiones; i++)); do
    # Obtenemos la partición correspondiente
    particion="/dev/${unidad}$((i+1))"
    
    # Obtenemos el dominio correspondiente
    dominio="${dominios[i]}"
    # Tomamos el primer valor antes del signo de coma (',') como nombre de dominio
    cleaned_host=$(echo "$dominio" | cut -d',' -f1)
    mounting_point="$target_dir/$cleaned_host"

    # Montar la partición
    echo "Montando la partición: $particion $mounting_point"
    if sudo mount "$particion" "$mounting_point"; then
      echo "Partición '$particion' fue montada en '$mounting_point'."
    else
      echo "Error al montar la partición '$particion' en '$mounting_point'."
      echo "Asegúrese de que la partición exista y el punto de montaje esté disponible."
      echo "Revise los permisos y la configuración del sistema."
    fi
    lsblk --paths | grep "$unidad"
    sleep 3
    
    # Agregar entradas en /etc/fstab para montar las particiones al reiniciar el sistema
    echo "${particion//\"/} ${mounting_point//\"/} ${formato//\"/} defaults 0 0" | sudo tee -a /etc/fstab
    echo "-------------------------------------------------------------------------"
  done
  lsblk --paths | grep "$unidad"
}

function web_partitions() {
  echo "****************WEB PARTITIONS****************"
  count_domains
  get_dev
  confirm
  echo "****************ALL DONE****************"
}
web_partitions
