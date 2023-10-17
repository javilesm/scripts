#!/bin/bash
# python_packages.sh
# Variables
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$(dirname "$(dirname "$(dirname "$(realpath "$BASH_SOURCE")")")")/envs"
PACKAGES_FILE="packages.txt"
PACKAGES_PATH="$CURRENT_DIR/$PACKAGES_FILE"
ENVIRONMENTS_FILE="environments.txt"
ENVIRONMENTS_PATH="$CURRENT_DIR/$ENVIRONMENTS_FILE"
REPORT_FILE="report.txt"
REPORT_PATH="$CURRENT_DIR/$REPORT_FILE"

# Función para comprobar la existencia del archivo de paquetes pip
function verify_list1() {
  if [ ! -f "$PACKAGES_PATH" ]; then
    echo "ERROR: El archivo de paquetes pip '$PACKAGES_FILE' no se puede encontrar en la ruta '$PACKAGES_PATH'."
    exit 1
  fi
}

# Función para comprobar la existencia del archivo de entornos
function verify_list2() {
  if [ ! -f "$ENVIRONMENTS_PATH" ]; then
    echo "ERROR: El archivo de entornos virtuales '$ENVIRONMENTS_FILE' no se puede encontrar en la ruta '$ENVIRONMENTS_PATH'."
    exit 1
  fi
}

# Función para comprobar la existencia del archivo de reporte
function check_report_file() {
  if [ ! -f "$REPORT_PATH" ]; then
    echo "El archivo de reporte '$REPORT_FILE' no existe en la ruta '$REPORT_PATH'. Creando archivo de reporte..."
    touch "$REPORT_PATH"
    echo "Entorno    //    PIP" >> "$REPORT_PATH"
  fi
}

# Leer la lista de paquetes
function read_packages() {
  if [[ -f "$PACKAGES_PATH" ]]; then
    readarray -t packages < "$PACKAGES_PATH"
  else
    echo "Error: no se encontró '$PACKAGES_PATH'"
    exit 1
  fi
}

# Función para instalar paquetes en un entorno
function install_packages() {
  local environment="$1"
  source "$ENV_DIR/$environment/bin/activate"
  for package in "${packages[@]}"; do
    echo "Instalando el paquete PIP '$package' en el entorno '$environment'..."
    echo "$environment --> $package" >> "$REPORT_PATH"
    pip install "$package"
  done
  deactivate
}

# Función principal
function main() {
  verify_list1
  verify_list2
  check_report_file
  read_packages
  for environment in $(cat "$ENVIRONMENTS_PATH"); do
    install_packages "$environment"
  done
  check_pip
}

main
