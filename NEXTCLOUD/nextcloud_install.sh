#!/bin/bash
# nextcloud_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_FILE="nextcloud_config.sh" # Script configurador
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"
HTML_PATH="/var/www/html"
NEXTCLOUD_DIR="nextcloud"
NEXTCLOUD_HTML_PATH="$HTML_PATH/$NEXTCLOUD_DIR"
# Funcion para crear el directorio Nextcloud
function mkdir_nextcloud() {
  # Verificar si el directorio ya existe
  if [ -d "$NEXTCLOUD_HTML_PATH" ]; then
    echo "El directorio '$NEXTCLOUD_HTML_PATH' ya existe."
    return
  fi
  # Creando el directorio Nextcloud
  echo "Creando el directorio Nextcloud..."
  if sudo mkdir -p "$NEXTCLOUD_HTML_PATH"; then
    echo "El directorio '$NEXTCLOUD_HTML_PATH' se creó correctamente."
  else
    echo "Error al crear el directorio '$NEXTCLOUD_HTML_PATH'."
  fi
}
# Función para darle al directorio de Nextcloud los permisos necesarios
function set_nextcloud_permissions() {
    echo "Dando al directorio '$NEXTCLOUD_HTML_PATH' los permisos necesarios..."
    if sudo chown -R www-data:www-data "$NEXTCLOUD_HTML_PATH"; then
        echo "Los permisos se han establecido correctamente al directorio '$NEXTCLOUD_HTML_PATH'."
    else
        echo "Ha ocurrido un error al establecer los permisos al directorio '$NEXTCLOUD_HTML_PATH'."
        exit 1
    fi
}
# Función para obtener Nextcloud usando wget
function get_nextcloud() {
  # Descargar Nextcloud con wget
  echo "Descargando Nextcloud con wget en '$NEXTCLOUD_HTML_PATH'..."
  if sudo wget "$NEXTCLOUD_HTML_PATH" "https://download.nextcloud.com/server/installer/setup-nextcloud.php"; then
    echo "Nextcloud se descargó correctamente en '$NEXTCLOUD_HTML_PATH'."
    cd "$NEXTCLOUD_HTML_PATH" & ll
  else
    echo "Error al descargar Nextcloud."
    return
  fi
}
# Función para darle al archivo de Nextcloud los permisos necesarios
function set_setup_permissions() {
    echo "Dando al archivo '$NEXTCLOUD_HTML_PATH/setup-nextcloud.php' los permisos necesarios..."
    if sudo chown www-data:www-data "$NEXTCLOUD_HTML_PATH/setup-nextcloud.php"; then
        echo "Los permisos se han establecido correctamente al archivo '$NEXTCLOUD_HTML_PATH/setup-nextcloud.php'."
    else
        echo "Ha ocurrido un error al establecer los permisos al archivo '$NEXTCLOUD_HTML_PATH/setup-nextcloud.php'."
        exit 1
    fi
}
# Función para verificar si el archivo de configuración existe
function validate_config_file() {
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "ERROR: El archivo de configuración de Nextcloud no se puede encontrar."
    exit 1
  fi
  echo "El archivo de configuración de Nextcloud existe."
}
# Función para ejecutar el configurador de Nextcloud
function nextcloud_config() {
  echo "Ejecutar el configurador de Nextcloud..."
    # Intentar ejecutar el archivo de configuración de Nextcloud
  if sudo bash "$CONFIG_PATH"; then
    echo "El archivo de configuración '$CONFIG_FILE' se ha ejecutado correctamente."
  else
    echo "ERROR: No se pudo ejecutar el archivo de configuración '$CONFIG_FILE'."
    exit 1
  fi
  echo "Configurador '$CONFIG_FILE' ejecutado."
}
# Función principal
function nextcloud_install() {
  echo "**********NEXTCLOUD INSTALL***********"
    mkdir_nextcloud
    set_nextcloud_permissions
    get_nextcloud
    set_setup_permissions
    validate_config_file
    nextcloud_config
  echo "*************ALL DONE**************"
}
# Llamar a la función principal
nextcloud_install
