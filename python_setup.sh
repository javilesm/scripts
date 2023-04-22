#!/bin/bash
# python.sh
echo "***SCRIPT DE INSTALACION DE PYTHON, DEPENDENCIAS Y AMBIENTES***"
# Función para instalar Python
function install_python {
  # Verificar que Python no está instalado
  if ! command -v python3 >/dev/null 2>&1; then
    # Instalar Python
    echo "Instalando Python..."
    sudo apt-get update
    sudo apt-get install -y python3
    echo "Python ha sido instalado."
    # Obtener la versión de Python instalada en el sistema
    if ! command -v python3 &> /dev/null; then
        echo "Python no está instalado en el sistema."
        exit 1
    fi
    CURRENT_PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    echo "La versión de Python instalada en el sistema es: $CURRENT_PYTHON_VERSION"
    # Agregar Python al PATH del usuario
    echo "Agregando Python al PATH del usuario..."
    # Buscar la ruta de ubicación del archivo .bashrc
    BASHRC_PATH=$(find /home/ -name ".bashrc" 2>/dev/null)
    if [ -z "$BASHRC_PATH" ]; then
        echo "No se encontró el archivo .bashrc en el sistema. Intentando buscar en otros directorios..."
        BASHRC_PATH=$(find / -name ".bashrc" 2>/dev/null)
        if [ -z "$BASHRC_PATH" ]; then
            echo "No se pudo encontrar la ruta de ubicación del archivo .bashrc."
            exit 1
        fi
    fi
    echo "La ruta de ubicación del archivo .bashrc es: $BASHRC_PATH"
    # Verificar que el usuario tiene permisos para editar el archivo .bashrc
    if [ ! -w "$BASHRC_PATH" ]; then
        echo "El usuario no tiene permisos para editar el archivo .bashrc."
        exit 1
    fi
    # Actualizar el archivo .bashrc
    echo 'export PATH="/usr/local/bin:$PATH"' >> "$BASHRC_PATH"
    echo 'export PATH="/usr/local/python/'"$CURRENT_PYTHON_VERSION"'/bin:$PATH"' >>"$BASHRC_PATH"
    echo "Actualizando $BASHRC_PATH"
    if ! source "$BASHRC_PATH"; then
        echo "No se pudo actualizar el archivo $BASHRC_PATH."
        exit 1
    fi
    echo "$BASHRC_PATH ha sido actualizado exitosamente." 
    
  else
    echo "Python ya está instalado."
  fi
}
# Instalar Python
install_python
# Obtener la ruta actual del script
CURRENT_PATH=$(dirname "$(readlink -f "$0")")
# Obtener parámetros de configuración desde un archivo externo
source "$CURRENT_PATH/python_config.cfg"
# Ejecutar los sub-scripts recursivamente
for script in "${python_scripts[@]}"; do
  if [ "$script" != "$0" ]; then
    bash "$CURRENT_PATH/$script"
  fi
done
echo "¡La instalación de Python con dependencias, paquetes y entornos ha sido completada!"
