#!/bin/bash
# jq_install.sh
# Función para verificar si se ejecuta el script como root
function check_root() {
  echo "Verificando si se ejecuta el script como root..."
  if [[ $EUID -ne 0 ]]; then
     echo "Este script debe ser ejecutado como root" 
     exit 1
  fi
}
# Función para instalar JQ
function install_jq() {
  echo "Instalando JQ..."
  apt install -y jq || { echo "Error al instalar JQ. Saliendo..." ; exit 1; }
}
# Llamar a las funciones en el orden correcto
function jq_install () {
  echo "**********JQ INSTALL**********"
  check_root
  install_jq
  echo "**********ALL DONE**********"
}
# Llamar a las funcion principal
jq_install
