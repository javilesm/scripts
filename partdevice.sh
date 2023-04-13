#!/bin/bash
# Incluye el archivo confirmacion.sh
source ./confirm.sh

# Descripcion
echo "***Script para particionar unidades***"

# Obtener la unidad a particionar y el número de particiones del usuario
echo "A continuacion, ingrese la ruta de la unidad a particionar y el número de particiones a crear (ejemplo: /dev/xvdf)"
sleep 2
read -p "/dev/ " unidad
read -p "Ingrese el número de particiones a crear: " num_particiones

# Mostrar la información ingresada y solicitar confirmación al usuario
echo "Se procederá a particionar la siguiente unidad: /dev/$unidad"
echo "Se crearán $num_particiones particiones en esta unidad."

# Pide confirmación al usuario
if confirm "¿Está seguro de que desea ejecutar la acción?"; then
  echo "El usuario confirmó la ejecución."
  # Coloca aquí las acciones a realizar si el usuario confirma
else
  echo "El usuario canceló la ejecución."
  # Coloca aquí las acciones a realizar si el usuario cancela
  exit 1
fi
fi

# Verificar que la unidad exista
if ! [ -b "/dev$unidad" ]; then
  echo "La unidad especificada no existe."
  exit 1
fi

# Calcular el tamaño de cada partición en base al tamaño de la unidad y el número de particiones
tamanio_unidad=$(sudo blockdev --getsize64 "/dev$unidad")
tamanio_particion=$((tamanio_unidad / num_particiones / 1024 / 1024)) # en MB

# Crear las particiones
sudo fdisk "/dev$unidad" <<EOF
g
$(for i in $(seq $num_particiones); do echo "n"; echo ""; echo "+${tamanio_particion}M"; done)
w
EOF

# Formatear las particiones como ext4
for i in $(seq $num_particiones); do
  sudo mkfs.ext4 "/dev${unidad}${i}"
done

# Crear directorios de montaje
for i in $(seq $num_particiones); do
  sudo mkdir "/data/$unidad$i"
done

# Montar las particiones en los directorios de montaje
for i in $(seq $num_particiones); do
  sudo mount "/dev${unidad}${i}" "/data/$unidad$i"
done

# Agregar entradas en /etc/fstab para montar las particiones al reiniciar el sistema
for i in $(seq $num_particiones); do
  echo "/dev${unidad}${i} /data/$unidad$i ext4 defaults 0 0" | sudo tee -a /etc/fstab
done
