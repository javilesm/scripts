#!/bin/bash
# clean_system.sh
# Función para limpiar sistema
function clean_system() {
  echo "Limpiando sistema..."
  if sudo apt-get clean -y && sudo apt autoremove -y; then
    echo "Limpieza de sistema completada."
  else
    echo "Error al limpiar el sistema."
    exit 1
  fi
}
# Llamar a la función principal
clean_system
