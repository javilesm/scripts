#! /bin/bash
# mysql_install.sh
# Variables
CONFIG_FILE="mysql_config.sh"
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"

# Función para verificar si el archivo de configuración existe
function validate_config_file() {
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "El archivo de configuración de MySQL no se puede encontrar."
    exit 1
  fi
  echo "El archivo de configuración de MySQL existe."
}
# Función para ejecutar el archivo de configuración
function mysql_config() {
  echo "Ejecutando el configurador de MySQL..."
  # Intentar ejecutar el archivo de configuración de MySQL
  if sudo bash "$CONFIG_PATH"; then
    echo "El archivo de configuración '$CONFIG_FILE' se ha ejecutado correctamente."
  else
    echo "No se pudo ejecutar el archivo de configuración '$CONFIG_FILE'."
    exit 1
  fi
  echo "Configurador '$CONFIG_FILE' ejecutado."
}

# Función principal
function mysql_install() {
    echo "*******MYSQL INSTALL******"
    validate_config_file
    mysql_config
    echo "*********ALL DONE********"
}
# Llamar a la funcion princial
mysql_install
