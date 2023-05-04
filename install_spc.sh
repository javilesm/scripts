#!/bin/bash
# install_spc.sh
# Funcion para instalar utilidades
function instalar_utilidades() {
  # instalar utilidades
  echo "Instalando utilidades..."
  if sudo apt-get install lsb-release ca-certificates apt-transport-https software-properties-common -y; then
    echo "Utilidades instaladas."
  else
    echo "Error al instalar las utilidades."
    exit 1
  fi
}
# Funcion principal
function install_spc() {
  echo "**********INSTALL SOFTWARE-PROPERTIES-COMMON**********"
  instalar_utilidades
  echo "**********ALL DONE**********"
}
# Llamar a la funcion principal
install_spc
