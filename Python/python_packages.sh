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
############################################################################################
declare -A PACKAGES_PATH
declare -A ENVIRONMENTS_PATH

function read_lists() {
  # Leer la lista de colores
  if [[ -f "$PACKAGES_PATH" ]]; then
    readarray -t paquetes < "$PACKAGES_PATH"
    for i in "${!paquetes[@]}"; do
      PACKAGES_PATH[$i]=${paquetes[$i]}
    done
  else
    echo "Error: no se encontró '$PACKAGES_PATH'"
    exit 1
  fi

  # Leer la lista de acciones
  if [[ -f "$ENVIRONMENTS_PATH" ]]; then
    readarray -t entornos < "$ENVIRONMENTS_PATH"
    for i in "${!entornos[@]}"; do
      ENVIRONMENTS_PATH[$i]=${entornos[$i]}
    done
  else
    echo "Error: no se encontró '$ENVIRONMENTS_PATH'"
    exit 1
  fi
}

function min() {
  if [[ ${#PACKAGES_PATH[@]} -lt ${#ENVIRONMENTS_PATH[@]} ]]; then
    echo ${#PACKAGES_PATH[@]}
  else
    echo ${#ENVIRONMENTS_PATH[@]}
  fi
}
function iteration() {
  local num_elementos=$(min)
  # Iteramos sobre la lista de paquetees
  for ((i=0; i<num_elementos; i++))
  do
    # Obtenemos el paquete y la acción correspondiente
    paquete="${PACKAGES_PATH[$i]}"
    entorno="${ENVIRONMENTS_PATH[$i]}"
    # Imprimimos el mensaje correspondiente al paquete
    print_message "$paquete" "$entorno"
    
  done
  
}
function print_message() {
  local paquete="$1"
  # Mostrar item 1
  echo "Paquete: '$paquete'"
  local entorno="$2"
  # Mostrar item 2
  echo "Entorno: '$entorno'"
  # Imprimimos el mensaje
  echo "Activando el entorno '$entorno' e instalando el paquete PIP '$paquete'."
  echo "'$entorno' --> '$paquete'" >> "$REPORT_PATH"
  # Activate environment
  source "$ENV_DIR/$entorno/bin/activate"
  sleep 2
  # Instalar paquete PIP
  pip install "$paquete"
  # Deactivate environment
  deactivate
  sleep 3
}
function check_pip() {
  pip list
}
############################################################################################
# Función principal
function main() {
  verify_list1
  verify_list2
  check_report_file
  read_lists
  iteration
  check_pip
}
main
