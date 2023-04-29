#! /bin/bash
# mysql_install.sh
# Variables
CONFIG_FILE="mysql_config.sh"
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual

# Función para instalar MySQL
function install_mysql () {
  install_and_restart mysql-server
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
    echo "Error al instalar $package."
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
# Función para verificar si el archivo de configuración de MySQL existe
function check_mysql_config_file() {
echo "Verificando si el archivo de configuración de MySQL existe..."
  if [[ ! -f /etc/mysql/mysql.conf.d/mysqld.cnf ]]; then
    echo "El archivo de configuración de MySQL no existe."
    exit 1
  fi
  echo "El archivo de configuración de MySQL existe."
}
# Función para realizar una copia de seguridad de mysql.conf
function backup_mysql_config_file() {
  echo "Realizando una copia de seguridad de mysqld.cnf..."
  if ! sudo cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.bak; then
    echo "Error al realizar una copia de seguridad de mysqld.cnf."
    exit 1
  fi
  echo "Copia de seguridad de mysqld.cnf realizada."
}
# Función para modificar el archivo de configuración y permitir conexiones desde cualquier IP
function modify_mysql_config_file() {
  echo "Modificando el archivo de configuración y permitir conexiones desde cualquier IP..."
  if ! sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf; then
    echo "Error al modificar el archivo de configuración."
    exit 1
  fi
  echo "El archivo de configuración fue modificado."
}
# Función para verificar si el archivo de configuración existe
function check_config_file() {
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$CURRENT_PATH/$CONFIG_FILE" ]; then
    echo "El archivo de configuración de MySQL no se puede encontrar."
    exit 1
  fi
  echo "El archivo de configuración de MySQL existe."
}
# Función para ejecutar el archivo de configuración
function execute_config_file() {
  echo "Ejecutando el configurador de MySQL..."
  # Intentar ejecutar el archivo de configuración de MySQL
  if sudo bash "$CURRENT_PATH/$CONFIG_FILE"; then
    echo "El archivo de configuración de MySQL se ha ejecutado correctamente."
  else
    echo "No se pudo ejecutar el archivo de configuración de MySQL."
    exit 1
  fi
}

# Función principal
function mysql_install() {
    echo "*******MYSQL INSTALL******"
    install_mysql
    check_mysql_config_file
    backup_mysql_config_file
    modify_mysql_config_file
    check_config_file
    execute_config_file
    echo "*********ALL DONE********"
}
# Llamar a la funcion princial
mysql_install
