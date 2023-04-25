#!/bin/bash
# python_dependencies.sh
echo "***SCRIPT INSTALACION DE DEPENDENCIAS PYTHON***"
instalar_dependencias() {
  while read dependencia; do
    echo "Comenzando la instalación de $dependencia..."
    if ! sudo apt-get install -y "$dependencia"; then
      echo "Error al instalar $dependencia. Por favor, verifique su conexión a Internet e inténtelo de nuevo."
      exit 1
    fi
    echo "$dependencia se ha instalado correctamente."
  done < "$1"
}
# Obtenemos la ruta absoluta del directorio actual donde se encuentra el script y el listado de dependencias
DIRECTORIO_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Verificamos si el archivo "dependencies.txt" existe en el directorio actual
DEPENDENCIES_FILE="$DIRECTORIO_ACTUAL/dependencies.txt"
if [ ! -f "$DEPENDENCIES_FILE" ]; then
  echo "Error: el archivo de dependencias no se encontró en $DIRECTORIO_ACTUAL. Por favor, asegúrese de que el archivo se llame 'dependencies.txt' y esté en el directorio correcto."
  exit 1
fi
# Realizamos la instalación de manera recursiva
echo "Comenzando la instalación de las dependencias de Python..."
instalar_dependencias "$DEPENDENCIES_FILE"
echo "Todas las dependencias fueron instaladas correctamente."
