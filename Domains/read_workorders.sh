#!/bin/bash
# read_workorders.sh

# Variables
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
API_USER="root" # Nuevo valor para el campo #12
LOG_DATE=$(date +"%Y%m%d%H%M%S") # Fecha y hora actuales en formato AñoMesDíaHoraMinutoSegundo
LOG_FILE="$CURRENT_DIR/read_workorders_$LOG_DATE.txt" # Nombre del archivo de registro con fecha y hora
MYSQL_USER="root"
MYSQL_PASSWORD=""
MYSQL_HOST="127.0.0.1"
MYSQL_DATABASE="antares"
MYSQL_TABLE="t_workorder"
CREATE_DOMAIN_SCRIPT="print_registered_domain.sh"
CREATE_DOMAIN_PATH="$CURRENT_DIR/$CREATE_DOMAIN_SCRIPT"

# Función para conectarse a MySQL y verificar si la base de datos y la tabla existen
check_mysql_table_existence() {
  # Comando para verificar si la base de datos existe
  local check_db_query="SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='$MYSQL_DATABASE';"

  # Intentar conectarse a MySQL y ejecutar la consulta para verificar la existencia de la base de datos
  if sudo mysql -u "$MYSQL_USER"-e "$check_db_query" 2>/dev/null | grep -q "$MYSQL_DATABASE"; then
    echo "La base de datos '$MYSQL_DATABASE' existe."
    
    # Comando para verificar si la tabla existe
    local check_table_query="SELECT 1 FROM information_schema.tables WHERE table_name='$MYSQL_TABLE' AND table_schema='$MYSQL_DATABASE' LIMIT 1;"

    # Intentar conectarse a MySQL y ejecutar la consulta para verificar la tabla
    if sudo mysql -u "$MYSQL_USER" -e "$check_table_query" 2>/dev/null | grep -q 1; then
      echo "La tabla '$MYSQL_TABLE' existe en la base de datos '$MYSQL_DATABASE'."
    else
      echo "La tabla '$MYSQL_TABLE' no existe en la base de datos '$MYSQL_DATABASE'."
    fi
  else
    echo "La base de datos '$MYSQL_DATABASE' no existe."
    
    # Comando para mostrar las bases de datos
    local show_databases_query="SHOW DATABASES;"
    
    # Mostrar las bases de datos disponibles
    echo "Bases de datos disponibles:"
    sudo mysql -u "$MYSQL_USER" -e "$show_databases_query"
  fi
}

# Función para conectarse a MySQL, buscar registros con WORKORDER_FLAG igual a 1 y contarlos
search_records() {
  local query="SELECT T_WORKORDER, REGISTERED_DOMAIN FROM $MYSQL_TABLE WHERE WORKORDER_FLAG = 1;"
  local record_count=0  # Variable para contabilizar los registros encontrados
  local found_records=()  # Arreglo para almacenar registros encontrados
  
  # Ejecutar la consulta en MySQL y guardar los resultados en una variable
  local result=$(sudo mysql -u "$MYSQL_USER" -D "$MYSQL_DATABASE" -N -e "$query" 2>/dev/null)

  # Verificar si se encontraron registros
  if [ -n "$result" ]; then
    # Pasar los valores de T_WORKORDER y REGISTERED_DOMAIN a otro script como argumentos
    while read -r T_WORKORDER DOMAIN; do
      # Incrementar el contador de registros encontrados
      ((record_count++))
      # Agregar el registro encontrado al arreglo
      found_records+=("$T_WORKORDER")
      # Llamar al otro script y pasar los valores como argumentos
      sudo bash "$CREATE_DOMAIN_PATH" "$DOMAIN"
    done <<< "$result"

    local message="Se encontraron $record_count registros con WORKORDER_FLAG igual a 1 y se pasaron a otro script."
    echo "$message"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" >> "$LOG_FILE"
    
    if [ $record_count -gt 0 ]; then
      echo "Registros encontrados en la tabla '$MYSQL_TABLE' con WORKORDER_FLAG igual a 1:"
      for record in "${found_records[@]}"; do
        echo "$record"
      done
    fi
  else
    local message="No se encontraron registros con WORKORDER_FLAG igual a 1."
    echo "$message"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" >> "$LOG_FILE"
  fi

  # Registrar el número total de registros encontrados
  echo "Número total de registros encontrados: $record_count"
  echo "$(date +"%Y-%m-%d %H:%M:%S") - Número total de registros encontrados: $record_count" >> "$LOG_FILE"
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

# Función principal (main)
main() {
  check_mysql_table_existence
  search_records

}

# Llamar a la función principal
main

# Crear o abrir el archivo de registro de eventos
sudo touch "$LOG_FILE"
