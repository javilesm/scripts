#! /bin/bash
# sqlite_install.sh
# Variables
CONFIG_FILE="sqlite_config.sh"
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"

# Función para instalar paquetes
function install_packages() {
  install_and_restart sqlite3
  install_and_restart libsqlite3-dev
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
    echo "ERROR: error al instalar $package."
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
# Función para verificar si el archivo de configuración existe
function validate_config_file() {
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "ERROR: El archivo de configuración de SQLite no se puede encontrar."
    exit 1
  fi
  echo "El archivo de configuración de SQLite existe."
}
# Función para ejecutar el archivo de configuración
function SQLite_config() {
  echo "Ejecutando el configurador de SQLite..."
  # Intentar ejecutar el archivo de configuración de SQLite
  if sudo bash "$CONFIG_PATH"; then
    echo "El archivo de configuración '$CONFIG_FILE' se ha ejecutado correctamente."
  else
    echo "ERROR: No se pudo ejecutar el archivo de configuración '$CONFIG_FILE'."
    exit 1
  fi
  echo "Configurador '$CONFIG_FILE' ejecutado."
}

# Función principal
function sqlite_install() {
    echo "*******SQL-LITE INSTALL******"
    install_packages
    validate_config_file
    SQLite_config
    echo "*********ALL DONE********"
}
# Llamar a la funcion princial
sqlite_install
