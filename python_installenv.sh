#!/bin/bash

# Función recursiva para instalar paquetes
install_package() {
  package=$1
  if ! dpkg -s $package >/dev/null 2>&1; then
    echo "Instalando $package..."
    sudo apt-get update
    sudo apt-get install -y $package
  else
    echo "$package ya está instalado."
  fi
}

# Creación del entorno virtual
virtualenv env
source env/bin/activate

# Instalación de Flask y Django dentro del entorno virtual
pip3 install Flask
pip3 install Django

# Desactivar el entorno virtual
deactivate

echo "Instalación completa."
