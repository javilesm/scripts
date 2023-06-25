#!/bin/bash
# secure_users.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
PYTHON_SCRIPT="$PARENT_DIR/utilities/secure-me.py"
VENV="venv5"
VENV_PATH="/home/ubuntu/envs/$VENV"
USERS_FILE="mysql_users.csv"
USERS_PATH="$CURRENT_DIR/$USERS_FILE"
# Función para activar el entorno virtual
function activate_venv() {
    # activar el entorno virtual
    echo "Activando el entorno virtual..."
    source $VENV_PATH/bin/activate
}
# Función para leer la lista de usuarios y crear sus contrasenas seguras
function read_users() {
    echo "Leyendo la lista de usuarios desde el archivo '$USERS_PATH' ..."
    # Leer la lista de usuarios desde el archivo mysql_users.csv
    while IFS="," read -r username password host database privilege; do
        # Generar contrasena segura para el usuario
    echo "Generando contrasena segura para el usuario '$username'..."
    python "$PYTHON_SCRIPT" << EOF
$username
$database
$host
1
0
EOF

    done < "$USERS_PATH"
    echo "Las contrasenas seguras para todos los usuarios fueron generadas."
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
    read_users
    deactivate_venv
    echo "*************ALL DONE**************"
}
# Llamar a la función principal
secure_users
