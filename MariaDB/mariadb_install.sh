#! /bin/bash
# mariadb_install.sh
# Variables
CONFIG_FILE="mariadb_config.sh"
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"

# Función para instalar mariadb
function install_mariadb () {
  install_and_restart mariadb-server
  install_and_restart mariadb-client
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
    echo "Error: no se pudo instalar el paquete '$package'."
    return 1
  fi
  
   # Verificar si el paquete se instaló correctamente
   echo "Verificando si el paquete se instaló correctamente..."
  if [ $? -eq 0 ]; then
    echo "$package se ha instalado correctamente."
  else
    echo "Error al instalar '$package'."
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
# Función para verificar si el archivo de configuración de mariadb existe
function check_mariadb_config_file() {
echo "Verificando si el archivo de configuración de mariadb existe..."
  if [[ ! -f /etc/mariadb/mariadb.conf.d/mariadbd.cnf ]]; then
    echo "El archivo de configuración de mariadb no existe."
    exit 1
  fi
  echo "El archivo de configuración de mariadb existe."
}
# Función para realizar una copia de seguridad de mariadb.conf
function backup_mariadb_config_file() {
  echo "Realizando una copia de seguridad de mariadbd.cnf..."
  if ! sudo cp /etc/mariadb/mariadb.conf.d/mariadbd.cnf /etc/mariadb/mariadb.conf.d/mariadbd.cnf.bak; then
    echo "Error al realizar una copia de seguridad de mariadbd.cnf."
    exit 1
  fi
  echo "Copia de seguridad de mariadbd.cnf realizada."
}
# Función para modificar el archivo de configuración y permitir conexiones desde cualquier IP
function modify_mariadb_config_file() {
  echo "Modificando el archivo de configuración y permitir conexiones desde cualquier IP..."
  if ! sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mariadb/mariadb.conf.d/mariadbd.cnf; then
    echo "Error al modificar el archivo de configuración."
    exit 1
  fi
  echo "El archivo de configuración fue modificado."
}
# Función para verificar si el archivo de configuración existe
function validate_config_file() {
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "El archivo de configuración de mariadb no se puede encontrar."
    exit 1
  fi
  echo "El archivo de configuración de mariadb existe."
}
# Función para ejecutar el archivo de configuración
function mariadb_config() {
  echo "Ejecutando el configurador de mariadb..."
  # Intentar ejecutar el archivo de configuración de mariadb
  if sudo bash "$CONFIG_PATH"; then
    echo "El archivo de configuración '$CONFIG_FILE' se ha ejecutado correctamente."
  else
    echo "No se pudo ejecutar el archivo de configuración '$CONFIG_FILE'."
    exit 1
  fi
  echo "Configurador '$CONFIG_FILE' ejecutado."
}

# Función principal
function mariadb_install() {
    echo "*******MARIADB INSTALL******"
    install_mariadb
    check_mariadb_config_file
    backup_mariadb_config_file
    modify_mariadb_config_file
    validate_config_file
    mariadb_config
    echo "*********ALL DONE********"
}
# Llamar a la funcion princial
mariadb_install
