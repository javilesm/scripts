#!/bin/bash
# jq_install.sh
# Función para verificar si se ejecuta el script como root
function check_root() {
  if [[ $EUID -ne 0 ]]; then
     echo "Este script debe ser ejecutado como root" 
     exit 1
  fi
}
# Función para actualizar el sistema
function update_system() {
  apt update
}
# Función para instalar JQ
function install_jq() {
  apt install -y jq
}
# Función para imprimir mensaje de instalación exitosa
function print_success() {
  echo "JQ ha sido instalado exitosamente."
}
# Llamar a las funciones en el orden correcto
function jq_install () {
   echo "SCRIPT PARA INSTALAR JQ"
   check_root
   update_system
   install_jq
   print_success
}
# Llamar a las funcion principal
jq_install
# Salir del script
exit 0
