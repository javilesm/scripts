#! /bin/bash
# SCRIPT DE INSTALACION DE PYTHON, DEPENDENCIAS Y AMBIENTES
echo "***SCRIPT DE INSTALACION DE PYTHON, DEPENDENCIAS Y AMBIENTES***"
# Obtener la ruta actual
CURRENT_PATH=$(dirname "$(readlink -f "$0")")

# Función para validar la existencia de un archivo
function file_exists {
    if [ ! -f "$1" ]; then
        echo "El archivo $1 no existe."
        exit 1
    fi
}

# Función para ejecutar un script y manejar errores de manera recursiva
function execute_script {
    if ! bash "$1"; then
        echo "Se produjo un error al ejecutar el script $1."
        exit 1
    fi

    # Buscar sub-scripts y ejecutarlos recursivamente
    for file in "$CURRENT_PATH"/*.sh; do
        if [ "$file" != "$1" ]; then
            execute_script "$file"
        fi
    done
}

# Función para instalar Python
function install_python {
    # Verificar que Python no está instalado
    if ! command -v python3 >/dev/null 2>&1; then
        # Instalar Python
        echo "Instalando Python..."
        sudo apt-get update
        sudo apt-get install -y python3
        echo "Python ha sido instalado."
    else
        echo "Python ya está instalado."
    fi

    # Ejecutar los sub-scripts recursivamente
    for file in "$CURRENT_PATH"/*.sh; do
        if [ "$file" != "$0" ]; then
            execute_script "$file"
        fi
    done
}

# Validar la existencia de los sub-scripts a ejecutar
file_exists "$CURRENT_PATH/python_dependencies"
file_exists "$CURRENT_PATH/python_packages"
file_exists "$CURRENT_PATH/python_environments"

# Instalar Python y ejecutar los sub-scripts
install_python

# Eliminar los paquetes que fueron instalados como dependencias de otros paquetes, pero que ya no son necesarios
echo "Eliminando los paquetes que fueron instalados como dependencias de otros paquetes, pero que ya no son necesarios."
sudo apt autoremove
echo "Paquetes eliminados."

echo "¡La instalación de Python con dependencias, paquetes y entornos ha sido completada!"
