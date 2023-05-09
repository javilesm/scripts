#!/bin/bash
# postfix_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_FILE="postfix_config.sh" # Script configurador
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"
# Function for installing the core components of postfix
function install_packages() {
  # Configurar las opciones de debconf
  echo "Configurando debconf..."
  sudo debconf-set-selections <<< "postfix postfix/main_mailer_type select Internet Site"
  sudo debconf-set-selections <<< "postfix postfix/mailname string example.com"
  sudo debconf-set-selections <<< "postfix postfix/sqlite/dbconfig-install boolean true"
  sudo debconf-set-selections <<< "postfix postfix/sqlite/dbconfig-upgrade boolean true"
  sudo debconf-set-selections <<< "postfix-sqlite postfix-sqlite/dbconfig-install boolean true"
  sudo debconf-set-selections <<< "postfix-sqlite postfix-sqlite/dbconfig-upgrade boolean true"
  
  # Instalar y reiniciar postfix y postfix-sqlite
  install_and_restart postfix
  install_and_restart postfix-sqlite
}
# Función para instalar un paquete y reiniciar los servicios afectados
function install_and_restart() {
  local package="$1"
  # Verificar si el paquete ya está instalado
  echo "Verificando si el paquete '$package' ya está instalado..."
  if dpkg -s "$package" >/dev/null 2>&1; then
    echo "El paquete '$package' ya está instalado."
    return 0
  fi

  # Instalar el paquete
  echo "Instalando el paquete '$package'..."
  if ! sudo apt-get install "$package" -y; then
    echo "ERROR: no se pudo instalar el paquete '$package'."
    return 1
  fi
  
   # Verificar si el paquete se instaló correctamente
   echo "Verificando si el paquete '$package' se instaló correctamente..."
  if [ $? -eq 0 ]; then
    echo "$package se ha instalado correctamente."
  else
    echo "ERROR: Error al instalar el paquete '$package'."
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
      echo "Error: no se pudieron reiniciar los servicios después de instalar el paquete '$package'."
      return 1
    fi
  else
    echo "No se encontraron servicios que necesiten reiniciarse después de instalar el paquete '$package'."
  fi

  echo "El paquete '$package' se instaló correctamente."
  return 0
}

# Función para verificar si el archivo de configuración existe
function validate_config_file() {
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "ERROR: El archivo de configuración '$CONFIG_FILE' no se puede encontrar en la ruta '$CONFIG_PATH'."
    exit 1
  fi
  echo "El archivo de configuración '$CONFIG_FILE' existe."
}
# Función para ejecutar el configurador de Postfix
function run_config() {
  echo "Ejecutar el configurador '$CONFIG_FILE'..."
    # Intentar ejecutar el archivo de configuración de Postfix
  if sudo bash "$CONFIG_PATH"; then
    echo "El archivo de configuración '$CONFIG_FILE' se ha ejecutado correctamente."
  else
    echo "ERROR: No se pudo ejecutar el archivo de configuración '$CONFIG_FILE'."
    exit 1
  fi
  echo "Configurador '$CONFIG_FILE' ejecutado."
}
# funcion principal
function postfix_install() {
    echo "***************POSTFIX INSTALL***************"
    install_packages
    validate_config_file
    run_config
    echo "***************ALL DONE***************"
}
# Llamar a la funcion principal
postfix_install
