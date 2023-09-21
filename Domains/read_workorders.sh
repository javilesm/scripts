#!/bin/bash

# Variables
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
PARENT_DIR="$(dirname "$CURRENT_DIR")"
WORKORDERS_FILE="t_workorder.csv"
WORKORDERSFILE_PATH="$CURRENT_DIR/$WORKORDERS_FILE"
API_USER="6516516516" # Nuevo valor para el campo #12
LOG_DATE=$(date +"%Y%m%d%H%M%S") # Fecha y hora actuales en formato AñoMesDíaHoraMinutoSegundo
LOG_FILE="$CURRENT_DIR/read_workorders_$LOG_DATE.txt" # Nombre del archivo de registro con fecha y hora
MYSQL_USER="$API_USER"
MYSQL_PASSWORD="tu_contraseña"
MYSQL_HOST="127.0.0.1"
MYSQL_DATABASE="antares"
MYSQL_TABLE="t_workorder"

# Función para conectarse a MySQL y verificar si la base de datos y la tabla existen
check_mysql_table_existence() {
  local db_user="$1"
  local db_password="$2"
  local db_host="$3"
  local db_name="$4"
  local table_name="$5"

  # Comando para verificar si la base de datos existe
  local check_db_query="SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='$db_name';"

  # Ejecutar la consulta para verificar la existencia de la base de datos
  if mysql -u "$db_user" -p"$db_password" -h "$db_host" -e "$check_db_query" 2>/dev/null | grep -q "$db_name"; then
    echo "La base de datos $db_name existe."
    
    # Comando para verificar si la tabla existe
    local check_table_query="SELECT 1 FROM information_schema.tables WHERE table_name='$table_name' AND table_schema='$db_name' LIMIT 1;"

    # Intentar conectarse a MySQL y ejecutar la consulta para verificar la tabla
    if mysql -u "$db_user" -p"$db_password" -h "$db_host" -e "$check_table_query" 2>/dev/null | grep -q 1; then
      echo "La tabla $table_name existe en la base de datos $db_name."
    else
      echo "La tabla $table_name no existe en la base de datos $db_name."
    fi
  else
    echo "La base de datos $db_name no existe."
  fi
}

# Función para imprimir una línea de progreso y registrar en el archivo de log
log_progress() {
  local completed="$1"
  local total="$2"
  local percentage=$((completed * 100 / total))
  local log_message="Progreso: $completed/$total ($percentage%)"
  echo -ne "$log_message\r"
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $log_message" >> "$LOG_FILE"
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
      values[6]=3
      values[11]="$API_USER" # Modificar el valor #12 con el valor de API_USER
      ((modified_count++))
      modified_lines+=("${values[0]}") # Agregar el primer valor de la fila modificada
    fi
    echo "${values[*]}" >> "$output_file"
  done < "$input_file"

  echo "Filas modificadas: $modified_count"
  echo "Filas sin cambios: $unchanged_count"
  echo "Filas modificadas (por referencia al primer valor):${modified_lines[*]}"

  # Registrar eventos en el archivo de log
  echo "$(date +"%Y-%m-%d %H:%M:%S") - Filas modificadas: $modified_count" >> "$LOG_FILE"
  echo "$(date +"%Y-%m-%d %H:%M:%S") - Filas sin cambios: $unchanged_count" >> "$LOG_FILE"
  echo "$(date +"%Y-%m-%d %H:%M:%S") - Filas modificadas (por referencia al primer valor):${modified_lines[*]}" >> "$LOG_FILE"
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

# Función principal (main)
main() {
  # Verificar si la tabla MySQL existe
  check_mysql_table_existence "$MYSQL_USER" "$MYSQL_PASSWORD" "$MYSQL_HOST" "$MYSQL_DATABASE" "$MYSQL_TABLE"

  # Crear o limpiar el archivo de registro de eventos
  > "$LOG_FILE"

  # Llamar a la función principal para procesar el archivo CSV
  process_csv "$CURRENT_DIR" "$WORKORDERS_FILE"
}

# Llamar a la función principal
main
