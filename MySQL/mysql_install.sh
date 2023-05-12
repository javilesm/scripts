#! /bin/bash
# mysql_install.sh
# Variables
CONFIG_FILE="mysql_config.sh"
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"

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
    check_mysql_config_file
    backup_mysql_config_file
    modify_mysql_config_file
    validate_config_file
    mysql_config
    echo "*********ALL DONE********"
}
# Llamar a la funcion princial
mysql_install
