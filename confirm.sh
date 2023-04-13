#!/bin/bash

# Función para obtener la confirmación del usuario
confirm() {
  while true; do
    read -p "$1 (y/n): " yn
    case $yn in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Por favor, responda con 'y' o 'n'.";;
    esac
  done
}
