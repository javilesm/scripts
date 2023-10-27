#!/bin/bash
# execute_process_workorders.SH

# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
ENV_DIR="$(dirname "$(dirname "$(dirname "$(realpath "$BASH_SOURCE")")")")/envs"
VIRTUAL_ENVIRONTMENT="$ENV_DIR/venv0/bin/activate"
PROCESS_WORKORDERS_SCRIPT="process_workorders.py"
PROCESS_WORKORDERS_SCRIPT_PATH="$CURRENT_DIR/$PROCESS_WORKORDERS_SCRIPT"

# Función para activar el entorno virtual
function activate_virtualenv() {
    source $VIRTUAL_ENVIRONTMENT
}

# Función para ejecutar el script de Python
function run_python_script() {
    python $PROCESS_WORKORDERS_SCRIPT_PATH
}

# Función para desactivar el entorno virtual
deactivate_virtualenv() {
    deactivate
}

# Función principal
function execute_process_workorders() {
  activate_virtualenv
  run_python_script
  deactivate_virtualenv
}

execute_process_workorders
