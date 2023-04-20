#! /bin/bash
# SCRIPT DE INSTALACION DE PYYHON, DEPENDENCIAS Y AMBIENTES

# Obtener la ruta actual
CURRENT_PATH=$PWD

# Variables de directorios para dependencias y ambientes
PACKAGES="python_packages.sh" # Script para instalar paquetes pip
ENVIRONMENTS="python_environments.sh" # Script para instalar entornos virtuales
DEPENDENCIES="python_dependencies.sh" # Script para instalar dependencias python

# Otorgar permisos de ejecución a los scripts
chmod +x "$CURRENT_PATH/$PACKAGES"
chmod +x "$CURRENT_PATH/$ENVIRONMENTS"
chmod +x "$CURRENT_PATH/$DEPENDENCIES"

# Instalar dependencias python
"$CURRENT_PATH/$DEPENDENCIES"

# Obtener la versión de Python instalada en el sistema
CURRENT_PYTHON_VERSION=$(python3 --version | awk '{print $2}')
echo "La versión de Python instalada en el sistema es: $CURRENT_PYTHON_VERSION"

# Agregar Python al PATH del usuario
echo "Agregando Python al PATH del usuario..."

# Buscar la ruta de ubicación del archivo .bashrc
BASHRC_PATH=$(find /home/ -name ".bashrc" 2>/dev/null)

if [ -z "$BASHRC_PATH" ]; then
    echo "No se encontró el archivo .bashrc en el sistema."
else
    echo "La ruta de ubicación del archivo .bashrc es: $BASHRC_PATH"
    echo 'export PATH="/usr/local/bin:$PATH"' >> "$BASHRC_PATH"
    echo 'export PATH="/usr/local/python/'"$CURRENT_PYTHON_VERSION"'/bin:$PATH"' >>"$BASHRC_PATH"
fi

# Actualizar el .bashrc
source "$BASHRC_PATH"

# Mostrar mensaje de instalación completada
echo "Python $CURRENT_PYTHON_VERSION se ha instalado correctamente."

# Instalar paquetes pip
"$CURRENT_PATH/$PACKAGES"

# Instalar entornos virtuales
"$CURRENT_PATH/$ENVIRONMENTS"

echo "¡La instalación de Python, Flask y Django ha sido completada!"
