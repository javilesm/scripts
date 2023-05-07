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
# Función para comprobar la existencia del archivo de paquetes
function check_packages_file() {
  if [ ! -f "$PACKAGES_PATH" ]; then
    echo "ERROR: El archivo de paquetes pip '$PACKAGES_FILE' no se puede encontrar en la ruta '$PACKAGES_PATH'."
    exit 1
  fi
  echo "El archivo de paquetes pip '$PACKAGES_FILE' existe"
}
# Función para comprobar la existencia del archivo de entornos
function check_environments_file() {
  if [ ! -f "$ENVIRONMENTS_PATH" ]; then
    echo "ERROR: El archivo de entornos virtuales '$ENVIRONMENTS_FILE' no se puede encontrar en la ruta '$ENVIRONMENTS_PATH'."
    exit 1
  fi
  echo "El archivo de entornos virtuales '$ENVIRONMENTS_FILE' existe"
}
# Función para comprobar la existencia del archivo de reporte
function check_report_file() {
  if [ ! -f "$REPORT_PATH" ]; then
    echo "ERROR: El archivo de reporte '$REPORT_FILE' no existe en la ruta '$REPORT_PATH'. Creando archivo de reporte..."
    sudo touch "$REPORT_PATH"
    echo "Entorno,Paquete" > "$REPORT_PATH"
  fi
  echo "El archivo de reporte '$REPORT_FILE' existe"
}
# Función para instalar paquetes PIP dentro de entornos virtuales
function install_packages() {
  # Read environments file and loop over each environment
  while IFS= read -r environment || [[ -n "$environment" ]]; do
    # Create environment virtual if it does not exist
    if [ ! -d "$ENV_DIR/$environment" ]; then
      echo "Creating virtual environment $environment"
      virtualenv -p python3 "$ENV_DIR/$environment"
    fi

    # Activate environment
    source "$ENV_DIR/$environment/bin/activate"

    # Read packages file and loop over each package
    while IFS= read -r package || [[ -n "$package" ]]; do
      echo "Installing package '$package' in environment '$environment'"
      pip install "$package"
    done < "$PACKAGES_PATH"

    # Deactivate environment
    deactivate
    sleep 15
  done < "$ENVIRONMENTS_PATH"
}

# Función principal
function python_packages() {
  echo "***SCRIPT DE INSTALACIÓN DE PAQUETES PYTHON***"
  check_packages_file
  check_environments_file
  check_report_file

  # Loop over each package
  while read package || [ -n "$package" ]; do
    # Install package in each environment
    while IFS= read -r environment || [[ -n "$environment" ]]; do
      # Activate environment
      source "$ENV_DIR/$environment/bin/activate"

      # Install package
      echo "Installing package '$package' in environment '$environment'"
      pip install "$package"

      # Deactivate environment
      deactivate
      sleep 15
    done < "$ENVIRONMENTS_PATH"
  done < "$PACKAGES_PATH"
  echo "***ALL DONE***"
}
python_packages
