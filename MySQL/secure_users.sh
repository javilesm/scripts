#!/bin/bash
# secure_users.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
PYTHON_SCRIPT="$CURRENT_DIR/secure_users.py"
VENV="venv5"
VENV_PATH="/home/ubuntu/envs/$VENV"
# Función para activar el entorno virtual
function activate_venv() {
    # activar el entorno virtual
    echo "Activando el entorno virtual..."
    source $VENV_PATH/bin/activate
}
# Función para ejecutar el script de Python
function run_script() {
    # ejecutar el script de Python
    echo "Ejecutando el script de Python..."
    python "$PYTHON_SCRIPT"
}
# Función para desactivar el entorno virtual
function deactivate_venv() {
    # desactivar el entorno virtual
    echo "Desactivando el entorno virtual..."
    deactivate
}
# Función principal
function secure_users() {
    echo "**********MYSQL SECURE USERS***********"
    activate_venv
    run_script
    deactivate_venv
    echo "*************ALL DONE**************"
}
# Llamar a la función principal
secure_users
