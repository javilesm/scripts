#!/bin/bash
# python_install.sh
# Función para verificar si Python está instalado
function verificar_python_instalado () {
  echo "Verificando si Python está instalado"
  if ! command -v python3 >/dev/null 2>&1; then
  echo "Python no está instalado"
    return 1 # Python no está instalado
  fi
  echo "Python está instalado"
  return 0 # Python está instalado
}
# Función para instalar Python
function instalar_python () {
  if verificar_python_instalado; then
    echo "Python ya está instalado."
    return
  fi
  echo "Instalando Python..."
  sudo apt-get update
  sudo apt-get install -y python3
  echo "Python ha sido instalado."
}
# Función para obtener la versión de Python instalada en el sistema
function obtener_version_python () {
  echo "Obteniendo la versión de Python instalada en el sistema"
  CURRENT_PYTHON_VERSION=$(python3 --version | awk '{print $2}')
  echo "La versión de Python instalada en el sistema es: $CURRENT_PYTHON_VERSION"
}
# Función para buscar el archivo .bashrc en el sistema
function find_bashrc () {
  echo "Buscando el archivo .bashrc en el sistema"
  BASHRC_PATH=$(find /home/ -name ".bashrc" 2>/dev/null)
  if [ -z "$BASHRC_PATH" ]; then
    echo "No se encontró el archivo .bashrc en la carpeta home."
    BASHRC_PATH=$(find / -name ".bashrc" 2>/dev/null)
    if [ -z "$BASHRC_PATH" ]; then
      echo "No se pudo encontrar el archivo .bashrc en el sistema."
      exit 1
    fi
  fi
  echo "La ruta de ubicación del archivo .bashrc es: $BASHRC_PATH"
  export BASHRC_PATH
}
# Función para verificar los permisos de edición del archivo .bashrc
function verificar_permisos_bashrc () {
echo "Verificando los permisos de edición del archivo .bashrc"
  if [ ! -w "$BASHRC_PATH" ]; then
    echo "El usuario no tiene permisos para editar el archivo .bashrc."
    exit 1
  fi
}
# Función para actualizar el archivo .bashrc
function add_to_bashrc () {
  echo "Actualizando el archivo .bashrc..."
  echo 'export PATH="/usr/local/bin:$PATH"' >> "$BASHRC_PATH"
  echo 'export PATH="/usr/local/python/'"$CURRENT_PYTHON_VERSION"'/bin:$PATH"' >>"$BASHRC_PATH"
  if ! source "$BASHRC_PATH"; then
        echo "No se pudo actualizar el archivo $BASHRC_PATH."
        exit 1
  fi
  echo "$BASHRC_PATH ha sido actualizado exitosamente." 
}
# Funcion para ejecutar scripts complementarios
function run_python_scripts () {
  echo "Obteniendo parámetros de configuración..."
  CURRENT_PATH=$(dirname "$(readlink -f "$0")") # Obtener la ruta actual del script
  PARAMETERS_FILE="python_config.cfg" # Parámetros de configuración
  echo "La ruta de los parámetros de configuración es: $CURRENT_PATH/$PARAMETERS_FILE"
  source "$CURRENT_PATH/$PARAMETERS_FILE" # Ruta a los parámetros de configuración
  # Ejecutar los sub-scripts recursivamente
  echo "Ejecutando scripts complementarios..."
  for script in "${python_scripts[@]}"; do
    if [ "$script" != "$0" ]; then
      bash "$CURRENT_PATH/$script"
    fi
  done
}
# Función principal
function python_install () {
  echo "***PYTHON INSTALL***"
  verificar_python_instalado
  instalar_python
  obtener_version_python
  find_bashrc
  #verificar_permisos_bashrc
  add_to_bashrc
  run_python_scripts
}
# Llamar a la funcion principal
python_install
