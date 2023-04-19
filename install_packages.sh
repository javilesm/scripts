#!/bin/bash

# Verificar si el archivo packages.txt existe
if [ ! -f packages.txt ]; then
  echo "No se encontró el archivo packages.txt. Saliendo..."
  exit 1
fi

# Leer el archivo packages.txt e instalar cada paquete de manera aislada
while read -r package; do
  echo "Instalando $package"
  if ! pip install --user --isolated "$package"; then
    echo "Error al instalar $package. Saliendo..."
    exit 1
  fi
  echo "$package se ha instalado correctamente."
done < packages.txt

echo "Todos los paquetes se han instalado correctamente."
