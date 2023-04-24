#!/bin/bash
# python_environments.sh
# Variables
FILE="environments.txt"
PACKAGES="python_packages.sh"
# Funciones
function usage() {
  echo "Este script crea entornos virtuales de Python."
  echo "Se espera que haya un archivo $FILE con una lista de nombres de entornos virtuales, uno por línea."
  echo "El sub-script $PACKAGES se utiliza para instalar paquetes de Python."
  echo ""
  echo "Uso: ./$PACKAGES"
  echo ""
}
function read_directory() {
  echo "Obteniendo la ruta absoluta del script y el directorio padre..."
  CURRENT_DIR=$(dirname "$(realpath "$BASH_SOURCE")") # Obtener la ruta absoluta del script y el directorio padre
  export CURRENT_DIR
}
function create_envs() {
  echo "Creando entornos virtuales..."

  # Verificar si el archivo "environments.txt" existe y no está vacío
  if [ ! -f "$CURRENT_DIR/$FILE" ] || [ ! -s "$CURRENT_DIR/$FILE" ]; then
    echo "El archivo $CURRENT_DIR/$FILE no existe o está vacío."
    exit 1
  fi

  echo "Leyendo la lista de entornos virtuales desde el archivo $CURRENT_DIR/$FILE..."

  # Iterar sobre la lista de entornos virtuales y crearlos uno por uno
  while read -r env || [ -n "$env" ]; do
    if [ -z "$env" ]; then
      continue
    fi
    echo "Creando entorno virtual $env..."
    sudo python3 -m venv "$env"
  done < "$CURRENT_DIR/$FILE"
}
function install_python_packages () {
  echo "Ejecutando el sub-script para instalar paquetes de Python..."
  # Ejecuta el sub-script para instalar paquetes de Python
  sudo bash $CURRENT_DIR/$PACKAGES
}
function python_environments () {
  echo "****PYTHON ENVIRONMENTS****"
  usage
  read_directory
  create_envs
  #install_python_packages
  echo "El proceso de instalación de entornos virtuales ha finalizado."
}
# Llamar a la función principal
python_environments
