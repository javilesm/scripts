#!/bin/bash
# aws_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
AWS_CONFIG="aws_config.sh" # Script configurador
AWS_CONFIG_PATH="$CURRENT_PATH/$AWS_CONFIG"
# Función para validar permisos de administrador
function validate_admin_permissions() {
  if [ "$(id -u)" != "0" ]; then
  echo "Este script debe ser ejecutado como root o con permisos de sudo." 1>&2
  exit 1
  fi
}
# Función para instalar AWS CLI
function install_aws_cli() {
  echo "Instalando AWS CLI."
  install_and_restart awscli
  echo "Instalación de AWS CLI completa."
}
#!/bin/bash
# Función para instalar un paquete y reiniciar los servicios afectados
function install_and_restart() {
  local package="$1"

  # Verificar si el paquete ya está instalado
  if dpkg -s "$package" >/dev/null 2>&1; then
    echo "$package ya está instalado."
    return
  fi

  # Instalar el paquete
  echo "Instalando $package..."
  if sudo apt-get install "$package" -y >/dev/null 2>&1; then
    echo "Instalación de $package completa."
  else
    echo "Error: no se pudo instalar $package."
    return 1
  fi

  # Buscar los servicios que necesitan reiniciarse
  services=$(systemctl list-dependencies --reverse "$package" | grep -oP '^\w+(?=.service)')

  # Reiniciar los servicios que dependen del paquete instalado
  if [[ -n $services ]]; then
    echo "Reiniciando los siguientes servicios: $services"
    if sudo systemctl restart $services >/dev/null 2>&1; then
      echo "Reinicio de servicios completado."
    else
      echo "Error: no se pudieron reiniciar los siguientes servicios: $services."
      return 1
    fi
  else
    echo "No se encontraron servicios que necesiten reiniciarse."
  fi
}
# Función para instalar S3FS
function install_s3fs() {
  echo "Instalando S3FS."
  sudo apt-get install s3fs -y || { echo "Ha ocurrido un error al instalar S3FS."; exit 1; }
  echo "Instalación de S3FS completa."
}
# Función para verificar la existencia del archivo de configuración
function check_aws_config_file() {
  if [ ! -f "$CURRENT_PATH/$AWS_CONFIG" ]; then
  echo "No se ha encontrado el archivo de configuración de AWS. Proporcione un archivo válido antes de continuar." 1>&2
  exit 1
  fi
}
# Función para ejecutar configurador AWS CLI
function run_aws_cli_configurator() {
  echo "Ejecutando configurador de AWS CLI."
  echo "Ubicación del configurador: $AWS_CONFIG_PATH"
  sudo "$AWS_CONFIG_PATH" || { echo "Ha ocurrido un error al ejecutar el configurador de AWS CLI."; exit 1; }
}
# Función principal
function aws_install () {
  echo "**********AWS INSTALL***********"
  validate_admin_permissions
  update_system
  install_aws_cli
  install_s3fs
  check_aws_config_file
  run_aws_cli_configurator
  echo "**********ALL DONE***********"
}
# Llamar a la función principal
aws_install
