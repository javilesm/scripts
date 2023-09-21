#!/bin/bash

# Variables
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
PARENT_DIR="$(dirname "$CURRENT_DIR")"
WORKORDERS_FILE="t_workorder.csv"
WORKORDERSFILE_PATH="$CURRENT_DIR/$WORKORDERS_FILE"
API_USER="6516516516" # Nuevo valor para el campo #12

# Función para imprimir una línea de progreso
print_progress() {
  local completed="$1"
  local total="$2"
  local percentage=$((completed * 100 / total))
  echo -ne "Progreso: $completed/$total ($percentage%)\r"
}

# Función para cambiar el registro si el valor #7 es igual a 1
change_record() {
  local input_file="$1"
  local output_file="$2"
  local modified_count=0
  local unchanged_count=0
  local modified_lines=()
  local first_line_read=false

  while IFS=',' read -r line || [[ -n "$line" ]]; do
    if ! $first_line_read; then
      echo "$line" >> "$output_file"  # Copiar la primera línea (encabezado)
      first_line_read=true
      continue
    fi
    
    IFS=',' read -ra values <<< "$line"
    if [[ ${values[6]} -eq 1 ]]; then
      values[10]=$(date +"%d-%m-%Y %H:%M:%S")
      values[6]=0
      values[11]="$API_USER" # Modificar el valor #12 con el valor de API_USER
      ((modified_count++))
      modified_lines+=("${values[0]}") # Agregar el primer valor de la fila modificada
    fi
    echo "${values[*]}" >> "$output_file"
  done < "$input_file"

  echo "Filas modificadas: $modified_count"
  echo "Filas sin cambios: $unchanged_count"
  echo "Filas modificadas (por referencia al primer valor):"
  for line in "${modified_lines[@]}"; do
    echo "$line"
  done
}

# Función principal para procesar el archivo CSV
process_csv() {
  local input_dir="$1"
  local filename="$2"
  local file="$input_dir/$filename"
  local total_lines=$(wc -l < "$file")
  local current_line=0

  echo "Leyendo el archivo CSV: $file"
  echo "Total de filas: $total_lines"
  
  echo -e "\nDatos actuales en formato tabulado:"
  cat "$file"

  local temp_output_file="/tmp/workorders_temp.csv"
  > "$temp_output_file"

  # Cambiar registros si el valor #7 es igual a 1
  change_record "$file" "$temp_output_file"

  echo -e "\nProceso de cambio de registros completado. Datos actualizados en formato tabulado:"
  cat "$temp_output_file"

  # Mover el archivo temporal al archivo de trabajo original
  mv "$temp_output_file" "$file"
}

# Llamar a la función principal para procesar el archivo CSV
process_csv "$CURRENT_DIR" "$WORKORDERS_FILE"
