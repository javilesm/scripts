#! /bin/bash
# mariadb_config.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"

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

# Función principal
function mariadb_install() {
    echo "*******MARIADB INSTALL******"
    check_mariadb_config_file
    backup_mariadb_config_file
    modify_mariadb_config_file
    echo "*********ALL DONE********"
}
# Llamar a la funcion princial
mariadb_install
