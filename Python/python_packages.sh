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

add_pip_to_path() {
  local pip_path
  pip_path=$(which pip)
  
  if [ -z "$pip_path" ]; then
    echo "El ejecutable pip no se pudo encontrar en el sistema."
  else
    # Agregar pip al PATH
    export PATH="$pip_path:$PATH"
    echo "Ruta al ejecutable pip: $pip_path"
    echo "Se ha agregado pip al PATH."
  fi
}

# Función para comprobar la existencia del archivo de paquetes pip
function verify_list1() {
  if [ ! -f "$PACKAGES_PATH" ]; then
    echo "ERROR: El archivo de paquetes pip '$PACKAGES_FILE' no se puede encontrar en la ruta '$PACKAGES_PATH'."
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

# Leer la lista de entornos y usar solo el primer registro
function read_and_use_first_environment() {
  if [[ -f "$ENVIRONMENTS_PATH" ]]; then
    read -r first_environment < "$ENVIRONMENTS_PATH"
  else
    echo "Error: no se encontró '$ENVIRONMENTS_PATH'"
    exit 1
  fi
  echo "Usando el entorno: $first_environment"
}

# Función para instalar paquetes en el entorno seleccionado
function install_packages() {
  for package in "${packages[@]}"; do
    echo "Instalando el paquete PIP '$package' en el entorno '$first_environment'..."
    echo "$first_environment --> $package" >> "$REPORT_PATH"
    source "$ENV_DIR/$first_environment/bin/activate"
    pip install "$package"
    deactivate
  done
}

# Función principal
function main() {
  add_pip_to_path
  verify_list1
  check_report_file
  read_packages
  read_and_use_first_environment
  install_packages
  check_pip
}

main
