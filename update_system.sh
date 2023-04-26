#!/bin/bash
# update_system.sh
# Funcion para actualizar sistema
function actualizar_sistema() {
  echo "Actualizando sistema..."
    sudo apt-get update
}

actualizar_sistema
