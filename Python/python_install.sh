#!/bin/bash
# python_install.sh
# Variables
PARAMETERS_FILE="python_config.cfg" # Parámetros de configuración
# Función para instalar Python
function instalar_python() {
  install_and_restart python3
}
# Función para instalar un paquete y reiniciar los servicios afectados
function install_and_restart() {
  local package="$1"
  # Verificar si el paquete ya está instalado
  echo "Verificando si el paquete ya está instalado..."
  if dpkg -s "$package" >/dev/null 2>&1; then
    echo "El paquete '$package' ya está instalado."
    return 0
  fi

  # Instalar el paquete
  echo "Instalando $package..."
  if ! sudo apt-get install "$package" -y; then
    echo "ERROR: no se pudo instalar el paquete '$package'."
    return 1
  fi
  
   # Verificar si el paquete se instaló correctamente
   echo "Verificando si el paquete se instaló correctamente..."
  if [ $? -eq 0 ]; then
    echo "$package se ha instalado correctamente."
  else
    echo "ERROR: Error al instalar $package."
    return 1
  fi
  
  # Buscar los servicios que necesitan reiniciarse
  echo "Buscando los servicios que necesitan reiniciarse..."
  services=$(systemctl list-dependencies --reverse "$package" | grep -oP '^\w+(?=.service)')

  # Reiniciar los servicios que dependen del paquete instalado
  echo "Reiniciando los servicios que dependen del paquete instalado..."
  if [[ -n $services ]]; then
    echo "Reiniciando los siguientes servicios: $services"
    if ! sudo systemctl restart $services; then
      echo "ERROR: no se pudieron reiniciar los servicios después de instalar el paquete '$package'."
      return 1
    fi
  else
    echo "No se encontraron servicios que necesiten reiniciarse después de instalar el paquete '$package'."
  fi

  echo "El paquete '$package' se instaló correctamente."
  return 0
}
# Función para obtener la versión de Python instalada en el sistema
function obtener_version_python() {
  echo "Obteniendo la versión de Python instalada en el sistema"
  CURRENT_PYTHON_VERSION=$(python3 --version | awk '{print $2}')
  echo "La versión de Python instalada en el sistema es: $CURRENT_PYTHON_VERSION"
  export CURRENT_PYTHON_VERSION
}
# Función para buscar el archivo .bashrc en el sistema
function find_bashrc() {
  echo "Buscando el archivo .bashrc en el sistema"
  BASHRC_PATH=$(find /home/ -name ".bashrc" 2>/dev/null)
  if [ -z "$BASHRC_PATH" ]; then
    echo "ERROR: No se encontró el archivo .bashrc en la carpeta home."
    BASHRC_PATH=$(find / -name ".bashrc" 2>/dev/null)
    if [ -z "$BASHRC_PATH" ]; then
      echo "ERROR: No se pudo encontrar el archivo .bashrc en el sistema."
      exit 1
    fi
  fi
  echo "La ruta de ubicación del archivo .bashrc es: $BASHRC_PATH"
  export BASHRC_PATH
}
# Función para actualizar el archivo .bashrc
function add_to_bashrc() {
  PARENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )" # Obtener el directorio padre del script
  echo "Actualizando el archivo .bashrc..."
  echo 'export PATH="/usr/local/bin:$PATH"' >> "$BASHRC_PATH"
  echo 'export PATH="'"$PARENT_PATH"'/utilities:$PATH"' >> "$BASHRC_PATH"
  echo 'export PATH="/usr/local/python/'"$CURRENT_PYTHON_VERSION"'/bin:$PATH"' >>"$BASHRC_PATH"
  if ! source "$BASHRC_PATH"; then
        echo "ERROR: No se pudo actualizar el archivo $BASHRC_PATH."
        exit 1
  fi
  echo "$BASHRC_PATH ha sido actualizado exitosamente."
}
# Funcion para ejecutar scripts complementarios
function run_python_scripts() {
  echo "Obteniendo parámetros de configuración..."
  CURRENT_PATH=$(dirname "$(readlink -f "$0")") # Obtener la ruta actual del script
  echo "La ruta de los parámetros de configuración es: $CURRENT_PATH/$PARAMETERS_FILE"
  source "$CURRENT_PATH/$PARAMETERS_FILE" # Ruta a los parámetros de configuración
  # Ejecutar los sub-scripts recursivamente
  echo "Ejecutando scripts complementarios..."
  for script in "${python_scripts[@]}"; do
    if [ "$script" != "$0" ]; then
      sudo bash "$CURRENT_PATH/$script"
    fi
  done
}
# Función principal
function python_install() {
  echo "*******PYTHON INSTALL*******"
  instalar_python
  obtener_version_python
  find_bashrc
  add_to_bashrc
  run_python_scripts
  echo "*******ALL DONE*******"
}
# Llamar a la funcion principal
python_install
