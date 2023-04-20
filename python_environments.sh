#!/bin/bash
# Python_Environments
echo "***SCRIPT INSTALACION DE ENTORNOS VIRTUALES PYTHON***"

instalar_entornos() {
  while read entorno; do
    echo "Comenzando la instalación de $entorno..."
    if ! sudo -H pip3 install virtualenv; then
      echo "Error al instalar virtualenv. Por favor, verifique su conexión a Internet e inténtelo de nuevo."
      exit 1
    fi
    if [ ! -d "$entorno" ]; then
      virtualenv "$entorno"
    fi
    source "$entorno"/bin/activate
    echo "Instalando paquetes en el entorno virtual $entorno..."
    if ! sudo -H pip3 install -r "$entorno/requirements.txt"; then
      echo "Error al instalar paquetes en el entorno virtual $entorno. Por favor, verifique su conexión a Internet e inténtelo de nuevo."
      exit 1
    fi
    echo "Todos los paquetes se han instalado correctamente en el entorno virtual $entorno."
    deactivate
  done < "$1"
}

# Obtenemos la ruta absoluta del directorio actual donde se encuentra el script y el archivo de entornos
DIRECTORIO_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verificamos si el archivo "environments.txt" existe en el directorio actual
ENVIRONMENTS_FILE="$DIRECTORIO_ACTUAL/environments.txt"
if [ ! -f "$ENVIRONMENTS_FILE" ]; then
  echo "Error: el archivo de entornos no se encontró en $DIRECTORIO_ACTUAL. Por favor, asegúrese de que el archivo se llame 'environments.txt' y esté en el directorio correcto."
  exit 1
fi

# Realizamos la instalación de manera recursiva
echo "Comenzando la instalación de los entornos virtuales de Python..."
instalar_entornos "$ENVIRONMENTS_FILE"
echo "Todos los entornos virtuales han sido instalados correctamente."
