#! /bin/bash
# SCRIPT DE INSTALACION DE PYYHON, DEPENDENCIAS Y AMBIENTES

# Variables de directorios para dependencias y ambientes
PACKAGES="python_installpackages.sh" # Directorio de dependencias
ENVIRONMENTS="python_installenv.sh" # Directorio de ambientes

# Instalar Pyhon3
echo "Instalando python3..."
if ! sudo apt-get install -y python3; then
  echo "Error al instalar Python3. Saliendo..."
  exit 1
fi
echo "python3 se ha instalado correctamente."

# Instalar Pyhon3-pip
echo "Instalando python3-pip..."
if ! sudo apt-get install -y python3-pip; then
  echo "Error al instalar Python3-pip. Saliendo..."
  exit 1
fi
echo "python3-pip se ha instalado correctamente."

sudo apt autoremove

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

# Obtener la ruta actual
CURRENT_PATH=$PWD

# Otorgar permisos de ejecución a los scripts
chmod +x "$CURRENT_PATH/$PACKAGES"
chmod +x "$CURRENT_PATH/$ENVIRONMENTS"

# Instalar paquetes
"$CURRENT_PATH/$PACKAGES"

# Instalar entornos
"$CURRENT_PATH/$ENVIRONMENTS"

echo "¡La instalación de Python, Flask y Django ha sido completada!"
