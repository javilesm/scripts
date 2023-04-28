#!/bin/bash
# postgresql_config.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Vector de sub-scripts a ejecutar recursivamente
scripts=(
    "postgresql_create_db.sh"
    "postgresql_create_user.sh"
    "postgresql_create_role.sh"
    "postgresql_grant_privileges.sh"
)
# Función para verificar si se ejecuta el script como root
function check_root() {
    echo "Verificando si se ejecuta el script como root..."
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ser ejecutado como root"
        exit 1
    fi
}
# Función para validar si cada script en el vector "scripts" existe y tiene permiso de ejecución
function validate_pysql_scripts() {
  echo "Validando la existencia de cada script en la lista de sub-scripts..."
  for script in "${scripts[@]}"; do
    echo "Compobando '$script' en: $SCRIPT_DIR/..."
    if [ ! -f "$SCRIPT_DIR/$script" ] || [ ! -x "$SCRIPT_DIR/$script" ]; then
      echo "Error: $script no existe o no tiene permiso de ejecución"
      exit 1
    fi
    echo "El script '$script' existe en: $SCRIPT_DIR/"
  done
  echo "Todos los sub-scripts en '$SCRIPT_DIR' existen y tienen permiso de ejecución."
  return 0
}
# Función para ejecutar los sub-scripts contenidos en el vector "scripts"
function execute_psql_scripts() {
  echo "Ejecutando cada script en la lista de sub-scripts..."
  for script in "${scripts[@]}"; do
   echo "Comprobando '$script' en: '$SCRIPT_DIR/$script'..."
    if [ -f "$SCRIPT_DIR/$script" ] && [ -x "$SCRIPT_DIR/$script" ]; then
      echo "Ejecutando script: $script"
      sudo bash "$SCRIPT_DIR/$script"
    else
      echo "Error: $script no existe o no tiene permiso de ejecución"
    fi
    echo "El script: '$script' fue ejecutado."
  done
  echo "Todos los subscripts en '$SCRIPT_DIR' se han ejecutado correctamente."
  return 0
}
# Función para reiniciar el servicio de PostgreSQL
function restart_postgresql_service() {
    echo "Reiniciando el servicio de PostgreSQL..."
    sudo service postgresql restart
    sudo service postgresql status
}
# Función principal
function postgresql_config() {
    echo "**********POSTGRESQL CONFIG**********"
    check_root
    validate_pysql_scripts
    execute_psql_scripts
    restart_postgresql_service
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
postgresql_config
