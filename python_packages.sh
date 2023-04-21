#!/bin/bash
# python_packages.sh
echo "***SCRIPT INSTALACION DE PAQUETES PYTHON***"
instalar_paquetes() {
  while read paquete; do
    echo "Comenzando la instalación de $paquete..."
    if ! sudo -H pip3 install "$paquete"; then
      echo "Error al instalar $paquete. Por favor, verifique su conexión a Internet e inténtelo de nuevo."
      exit 1
    fi
    echo "$paquete se ha instalado correctamente."
  done < "$1"
}
# Obtenemos la ruta absoluta del directorio actual donde se encuentra el script y el archivo de paquetes
DIRECTORIO_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Verificamos si el archivo "packages.txt" existe en el directorio actual
PACKAGES_FILE="$DIRECTORIO_ACTUAL/packages.txt"
if [ ! -f "$PACKAGES_FILE" ]; then
  echo "Error: el archivo de paquetes no se encontró en $DIRECTORIO_ACTUAL. Por favor, asegúrese de que el archivo se llame 'packages.txt' y esté en el directorio correcto."
  exit 1
fi
# Realizamos la instalación de manera recursiva
echo "Comenzando la instalación de los paquetes de Python..."
instalar_paquetes "$PACKAGES_FILE"
echo "Todos los paquetes fueron instalados correctamente."
