#!/bin/bash
# update_system.sh
# Funcion para actualizar sistema
function actualizar_sistema() {
  # actualizar sistema
  echo "Actualizando sistema..."
  if sudo apt-get update -y; then
    echo "Sistema actualizado."
  else
    echo "Error al actualizar el sistema."
    exit 1
  fi
}
# Funcion principal
function update_system() {
  echo "**********UPDATE SYSTEM**********"
  actualizar_sistema
  echo "**********ALL DONE**********"
}
# Llamar a la funcion principal
update_system
