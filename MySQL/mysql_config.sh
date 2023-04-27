#!/bin/bash
# mysql_config.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
USERS_FILE="mysql_users.csv"
USERS_PATH="$SCRIPT_DIR/$USERS_FILE"
DBS_FILE="mysql_db.csv"
DBS_PATH="$SCRIPT_DIR/$DBS_FILE"
ROLES_FILE="mysql_roles.csv"
ROLES_PATH="$SCRIPT_DIR/$ROLES_FILE"
MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"
MYSQL_SOCKET="/var/run/mysqld/mysqld.sock"
password="root"
# Función para verificar si se ejecuta el script como root
function check_root() {
    echo "Verificando si se ejecuta el script como root..."
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ser ejecutado como root"
        exit 1
    fi
}
# Función para verificar la existencia del archivo de usuarios
function check_user_file() {
    echo "Verificando la existencia del archivo de usuarios"
    if [ ! -f "$USERS_PATH" ]; then
        echo "El archivo de usuarios '$USERS_FILE' no existe en el directorio $SCRIPT_DIR/"
        exit 1
    fi
    echo "El archivo de usuarios '$USERS_FILE' existe."
}
# Función para validar la existencia del archivo de bases de datos
function check_dbs_file() {
    echo "Validando la existencia del archivo de bases de datos..."
    if [ ! -f "$DBS_PATH" ]; then
        echo "El archivo de bases de datos '$DBS_FILE' no existe en el directorio $SCRIPT_DIR/"
        exit 1
    fi
    echo "El archivo de bases de datos '$DBS_FILE' existe."
}
# Función para establecer la propiedad de lectura y escritura del archivo mysqld.cnf
function set_mysql_file_permissions() {
  echo "Estableciendo la propiedad de lectura y escritura del archivo $MYSQL_CONF..."
  sudo chmod 644 "$MYSQL_CONF"
  if [ $? -ne 0 ]; then
    echo "Error al establecer los permisos de lectura y escritura del archivo $MYSQL_CONF"
    exit 1
  fi

  sudo chown mysql:mysql "$MYSQL_CONF"
  if [ $? -ne 0 ]; then
    echo "Error al establecer la propiedad del archivo $MYSQL_CONF"
    exit 1
  fi

  echo "La propiedad de lectura y escritura del archivo $MYSQL_CONF se ha establecido correctamente."
}
# Función para establecer la ubicación del socket de MySQL
function set_mysql_socket() {
  echo "Estableciendo la ubicación del socket de MySQL en $MYSQL_CONF..."
  # Verificar si el archivo de configuración existe
  if [ ! -f "$MYSQL_CONF" ]; then
    echo "No se puede encontrar el archivo de configuración de MySQL."
    exit 1
  fi

  # Verificar si el socket ya está configurado correctamente
  if grep -q "^socket\s*=\s*$MYSQL_SOCKET" "$MYSQL_CONF"; then
    echo "La ubicación del socket de MySQL ya está configurada correctamente."
  else
    # Agregar la línea del socket al archivo de configuración
    if sudo sed -i "/\[mysqld\]/a socket = $MYSQL_SOCKET" "$MYSQL_CONF"; then
      echo "La ubicación del socket de MySQL se ha configurado correctamente."
    else
      echo "No se pudo configurar la ubicación del socket de MySQL."
      exit 1
    fi
  fi
}
# Función para iniciar el servicio MySQL
function start_mysql() {
  sudo usermod -d /var/lib/mysql/ mysql
  if sudo service mysql status | grep -q "Active: active (running)"; then
    echo "El servicio MySQL ya se encuentra en ejecución."
    return 0
  fi
  echo "Iniciando servicio MySQL..."
  sudo service mysql start
  sudo service mysql status 
}
# Función para ejecutar los subscripts en el directorio scripts/MySQL/
function execute_mysql_scripts() {
  echo "Ejecutando subscripts en '$SCRIPT_DIR' ..."
  
  # Verificar que el directorio SCRIPT_DIR existe y es accesible
  if [ ! -d "$SCRIPT_DIR" ]; then
    echo "ERROR: El directorio '$SCRIPT_DIR' no existe o no se puede acceder."
    return 1
  fi
  
  # Ejecutar mysql_create_db.sh
  echo "Ejecutando mysql_create_db.sh ..."
  . "$SCRIPT_DIR/mysql_create_db.sh"
  EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    echo "ERROR: mysql_create_db.sh falló con el código de salida $EXIT_CODE."
    return $EXIT_CODE
  fi
  
  # Ejecutar mysql_create_user.sh
  echo "Ejecutando mysql_create_user.sh ..."
  . "$SCRIPT_DIR/mysql_create_user.sh"
  EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    echo "ERROR: mysql_create_user.sh falló con el código de salida $EXIT_CODE."
    return $EXIT_CODE
  fi
  
  # Ejecutar mysql_grant_privileges.sh
  echo "Ejecutando mysql_grant_privileges.sh ..."
  . "$SCRIPT_DIR/mysql_grant_privileges.sh"
  EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    echo "ERROR: mysql_grant_privileges.sh falló con el código de salida $EXIT_CODE."
    return $EXIT_CODE
  fi
  
  echo "Todos los subscripts en '$SCRIPT_DIR' se han ejecutado correctamente."
  return 0
}
# Función para reiniciar el servicio de MySQL
function restart_mysql_service() {
    echo "Reiniciando el servicio de MySQL..."
    sudo service mysql restart
}
# Función principal
function mysql_config() {
    echo "**********MYSQL CONFIG**********"
    check_root
    set_mysql_file_permissions
    set_mysql_socket
    start_mysql
    execute_mysql_scripts
    restart_mysql_service
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
mysql_config
