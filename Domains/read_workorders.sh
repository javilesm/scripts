#!/bin/bash

# Variables
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
PARENT_DIR="$(dirname "$CURRENT_DIR")"
WORKORDERS_FILE="t_workorder.csv"
WORKORDERSFILE_PATH="$CURRENT_DIR/$WORKORDERS_FILE"

# Función para imprimir una línea de progreso
print_progress() {
  local completed="$1"
  local total="$2"
  local percentage=$((completed * 100 / total))
  echo -ne "Progreso: $completed/$total ($percentage%)\r"
}

# Función principal para procesar el archivo CSV
process_csv() {
  local input_dir="$1"
  local filename="$2"
  local file="$input_dir/$filename"
  local total_lines=$(wc -l < "$file")
  local current_line=0
  local skip_first_line=true

  echo "Leyendo el archivo CSV: $file"
  echo "Total de filas: $((total_lines - 1))" # Restar 1 para omitir la primera línea

  # Leer el archivo CSV línea por línea
  while IFS= read -r line; do
    ((current_line++))
    if $skip_first_line; then
      skip_first_line=false
      continue  # Omitir la primera línea
    fi
    print_progress "$current_line" "$((total_lines - 1))" # Restar 1 para omitir la primera línea
    echo "REGISTRO $current_line:"
    IFS=',' read -ra values <<< "$line"
    for ((i = 0; i < ${#values[@]}; i++)); do
      echo "-- VALOR $((i + 1)): ${values[i]}"
    done
  done < "$file"

  echo -e "\nProceso completado."
}

# Llamar a la función principal para procesar el archivo CSV
process_csv "$CURRENT_DIR" "$WORKORDERS_FILE"
