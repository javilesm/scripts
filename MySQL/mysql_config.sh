#!/bin/bash
# mysql_config.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"
MYSQL_SOCKET="/var/run/mysqld/mysqld.sock"
SECURE_FILE_PRIV=""
# Vector de sub-scripts a ejecutar recursivamente
scripts=(
    "mysql_create_db.sh"
    "mysql_create_user.sh"
)
# Función para verificar si se ejecuta el script como root
function check_root() {
    echo "Verificando si se ejecuta el script como root..."
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ser ejecutado como root"
        exit 1
    fi
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
# Función para verificar si el archivo de configuración de MySQL existe
function check_mysql_config_file() {
echo "Verificando si el archivo de configuración de MySQL existe..."
  if [[ ! -f "$MYSQL_CONF" ]]; then
    echo "El archivo de configuración de MySQL no existe."
    exit 1
  fi
  echo "El archivo de configuración de MySQL existe."
}
# Función para realizar una copia de seguridad de mysql.conf
function backup_mysql_config_file() {
  echo "Realizando una copia de seguridad de mysqld.cnf..."
  if ! sudo cp "$MYSQL_CONF" "$MYSQL_CONF".bak; then
    echo "Error al realizar una copia de seguridad de mysqld.cnf."
    exit 1
  fi
  echo "Copia de seguridad de mysqld.cnf realizada."
}
# Función para modificar el archivo de configuración y permitir conexiones desde cualquier IP
function modify_mysql_config_file() {
  echo "Modificando el archivo de configuración y permitir conexiones desde cualquier IP..."
  if ! sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' "$MYSQL_CONF"; then
    echo "Error al modificar el archivo de configuración."
    exit 1
  fi
  echo "El archivo de configuración fue modificado."
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

   # Configurar secure_file_priv en el archivo de configuración
  if grep -q "^secure_file_priv\s*=\s*$SECURE_FILE_PRIV" "$MYSQL_CONF"; then
    echo "secure_file_priv ya está configurado correctamente en el archivo de configuración de MySQL."
  else
    if sudo sed -i "s/^\(secure_file_priv\s*=\s*\).*\$/\1$SECURE_FILE_PRIV/" "$MYSQL_CONF"; then
      echo "La configuración de secure_file_priv se ha actualizado correctamente en el archivo de configuración de MySQL."
    else
      echo "No se pudo actualizar la configuración de secure_file_priv en el archivo de configuración de MySQL."
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
# Función para validar si cada script en el vector "scripts" existe y tiene permiso de ejecución
function validate_mysql_scripts() {
  echo "Validando la existencia de cada script en la lista de sub-scripts..."
  for script in "${scripts[@]}"; do
    echo "Compobando '$script' en: $SCRIPT_DIR/..."
    if [ ! -f "$SCRIPT_DIR/$script" ] || [ ! -x "$SCRIPT_DIR/$script" ]; then
      echo "Error: $script no existe o no tiene permiso de ejecución"
      exit 1
    fi
    echo "El script '$script' existe en: $SCRIPT_DIR/"
  done
  echo "Todos los sub-scripts en '$SCRIPT_DIR' existen y tienen permiso de ejecución."
  return 0
}
# Función para ejecutar los sub-scripts contenidos en el vector "scripts"
function execute_mysql_scripts() {
  echo "Ejecutando cada script en la lista de sub-scripts..."
  for script in "${scripts[@]}"; do
   echo "Comprobando '$script' en: '$SCRIPT_DIR/$script'..."
    if [ -f "$SCRIPT_DIR/$script" ] && [ -x "$SCRIPT_DIR/$script" ]; then
      echo "Ejecutando script: $script"
      sudo bash "$SCRIPT_DIR/$script"
    else
      echo "Error: $script no existe o no tiene permiso de ejecución"
    fi
    echo "El script: '$script' fue ejecutado."
  done
  echo "Todos los subscripts en '$SCRIPT_DIR' se han ejecutado correctamente."
  return 0
}
# Función para reiniciar el servicio de MySQL
function restart_mysql_service() {
    echo "Reiniciando el servicio de MySQL..."
    sudo service mysql restart
    sudo service mysql status
}
# Función principal
function mysql_config() {
    echo "**********MYSQL CONFIG**********"
    check_root
    set_mysql_file_permissions
    check_mysql_config_file
    backup_mysql_config_file
    modify_mysql_config_file
    set_mysql_socket
    start_mysql
    validate_mysql_scripts
    execute_mysql_scripts
    restart_mysql_service
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
mysql_config
