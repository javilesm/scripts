#!/bin/bash

# Variables
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="packages.txt"
PACKAGES_PATH="$CURRENT_DIR/$PACKAGES_FILE"
ENVIRONMENTS_FILE="environments.txt"
ENVIRONMENTS_PATH="$CURRENT_DIR/$ENVIRONMENTS_FILE"
REPORT_FILE="report.txt"
REPORT_PATH="$CURRENT_DIR/$REPORT_FILE"

# Función para instalar paquetes en el entorno virtual actual
function instalar_paquetes() {
  local ENV_ACTUAL=$(basename $(dirname $VIRTUAL_ENV))
  while read paquete; do
    echo "Comenzando la instalación de $paquete en el entorno virtual $ENV_ACTUAL ..."
    if ! sudo -H pip3 install "$paquete"; then
      echo "Error al instalar $paquete en el entorno virtual $ENV_ACTUAL. Por favor, verifique su conexión a Internet e inténtelo de nuevo."
      exit 1
    fi
    echo "$paquete se ha instalado correctamente en el entorno virtual $ENV_ACTUAL."
    echo "$ENV_ACTUAL,$paquete" >> "$REPORT_PATH"
  done < "$PACKAGES_PATH"
}

# Función para instalar paquetes en cada entorno virtual disponible
function install_packages() {
  local environments=()
  while read -r environment || [ -n "$environment" ]; do
    if [ -z "$environment" ]; then
      continue
    fi
    environments+=("$environment")
  done < "$ENVIRONMENTS_PATH"

  env_counter=0
  while read -r package || [ -n "$package" ]; do
    if [ -z "$package" ]; then
      continue
    fi
    if [ "$env_counter" -ge "${#environments[@]}" ]; then
      echo "No hay más entornos virtuales disponibles para instalar paquetes."
      break
    fi
    echo "Instalando paquete de Python '$package' en el entorno virtual '${environments[env_counter]}'..."
    source "$HOME/${environments[env_counter]}/bin/activate"
    instalar_paquetes "$package"
    echo "Paquetes de Python '$package' instalados en el entorno virtual: '${environments[env_counter]}'" >> "$REPORT_PATH"
    deactivate
    ((env_counter++))
  done < "$PACKAGES_PATH"
}

# Función principal
function python_packages() {
  echo "***SCRIPT DE INSTALACIÓN DE PAQUETES PYTHON***"
  if [ ! -f "$PACKAGES_PATH" ]; then
    echo "ERROR: El archivo de paquetes pip '$PACKAGES_FILE' no se puede encontrar en la ruta '$PACKAGES_PATH'."
    exit 1
  fi
  if [ ! -f "$ENVIRONMENTS_PATH" ]; then
    echo "ERROR: El archivo de entornos virtuales '$ENVIRONMENTS_FILE' no se puede encontrar en la ruta '$ENVIRONMENTS_PATH'."
    exit 1
  fi
  install_packages
}

# Llamada a la función principal
python_packages
