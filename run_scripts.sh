#!/bin/bash

# Vector de sub-scripts a ejecutar recursivamente
scripts=(
  "python.sh"
  "aws.sh"
  "jq.sh"
  "lemp.sh"
)

# Define la función que obtiene la ruta del directorio actual de scripts
get_dir() {
  echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

# Obtiene la ruta del directorio actual de scripts
dir="$(get_dir)"

# Define una función recursiva que ejecutará cada script en la lista de sub-scripts
run_scripts() {
  for script in "$@"; do
    if [ -d "$script" ]; then
      run_scripts "$script"/*
    elif [ -f "$script" ]; then
      if [ -x "$script" ]; then
        echo "Ejecutando script: $script"
        "$script"
      else
        echo "Error: $script no tiene permiso de ejecución"
      fi
    else
      echo "Error: $script no existe"
    fi
  done
}

# Ejecuta los sub-scripts
run_scripts "${dir}/${scripts[@]}"
