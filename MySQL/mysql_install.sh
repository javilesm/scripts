#! /bin/bash
# mysql_install.sh
# Variables
CONFIG_FILE="mysql_config.sh"
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
# Función para verificar si se ejecuta el script como root
function check_root() {
  echo "Verificando si se ejecuta el script como root"
  if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ser ejecutado como root"
    exit 1
  fi
}
# Función para verificar si MySQL ya está instalado
function check_mysql_installed() {
  echo "Verificando si MySQL ya está instalado"
  if command -v mysql &> /dev/null
  then
    echo "MySQL ya está instalado en este sistema."
    exit 0
  fi
}
# Función para instalar MySQL
function install_mysql () {
  if [ $(dpkg-query -W -f='${Status}' mysql-server 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Instalando MySQL..."
    if ! sudo apt install mysql-server -yqq; then
      echo "No se pudo instalar MySQL"
      exit 1
    fi
  else
    echo "MySQL ya está instalado."
  fi
}
# Función para comprobar si MySQL se ha instalado correctamente
function check_mysql_installation() {
  echo "Comprobando si MySQL se ha instalado correctamente"
  if ! command -v mysql &> /dev/null
  then
    echo "MySQL no se ha instalado correctamente."
    exit 1
  fi
}
# Función para verificar si el archivo de configuración de MySQL existe
function check_mysql_config_file() {
echo "Verificando si el archivo de configuración de MySQL existe..."
  if [[ ! -f /etc/mysql/mysql.conf.d/mysqld.cnf ]]; then
    echo "El archivo de configuración de MySQL no existe."
    exit 1
  fi
}
# Función para realizar una copia de seguridad de mysql.conf
function backup_mysql_config_file() {
  echo "Realizando una copia de seguridad de mysqld.cnf..."
  if ! sudo cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.bak; then
    echo "Error al realizar una copia de seguridad de mysqld.cnf."
    exit 1
  fi
}
# Función para modificar el archivo de configuración y permitir conexiones desde cualquier IP
function modify_mysql_config_file() {
  echo "Modificando el archivo de configuración y permitir conexiones desde cualquier IP..."
  if ! sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf; then
    echo "Error al modificar el archivo de configuración."
    exit 1
  fi
}
# Función para ejecutar el configurador de MySQL
function mysql_config() {
  echo "Ejecutar el configurador de MySQL..."
  sudo bash "$CURRENT_PATH/$CONFIG_FILE"
}
# Función principal
function mysql_install() {
    echo "*******MYSQL INSTALL******"
    check_root
    check_mysql_installed
    install_mysql
    check_mysql_config_file
    backup_mysql_config_file
    modify_mysql_config_file
    mysql_config
    echo "*********ALL DONE********"
}
# Llamar a la funcion princial
mysql_install
