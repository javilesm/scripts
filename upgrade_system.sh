#!/bin/bash
# upgrade_system.sh
# Variables
# Función para actualizar paquetes
function upgrade_system() {
  echo "Actualizando paquetes...."
  if sudo apt-get upgrade -y; then
    echo "Paquetes actualizados."
  else
    echo "Error al actualizar paquetes."
    exit 1
  fi
}
# Llamar a la función principal
upgrade_system
