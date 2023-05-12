#!/bin/bash
# postgresql_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_FILE="postgresql_config.sh"
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"

# Función para configurar listen_addresses en postgresql.conf
function configure_listen_addresses() {
  echo "Configurando listen_addresses en postgresql.conf..."
  if ! sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/$(ls /etc/postgresql)/main/postgresql.conf; then
    echo "Error al configurar listen_addresses en postgresql.conf"
    exit 1
  fi
  echo "Archivo listen_addresses en postgresql.conf configurado."
}
# Función para agregar una entrada en pg_hba.conf
function add_entry_to_pg_hba() {
  echo "Agregando entrada en pg_hba.conf..."
  if ! echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/$(ls /etc/postgresql)/main/pg_hba.conf > /dev/null; then
    echo "Error al agregar entrada en pg_hba.conf"
    exit 1
  fi
  echo "Entrada en pg_hba.conf agregada."
}
function start_service() {
  echo "Iniciando el servicio PostgreSQL..."
  sudo pg_ctlcluster 12 main start
  sudo service postgresql status
  echo "Servicio PostgreSQL iniciado."
}
# Función para validar la existencia de postgresql_config.sh
function validate_config_file() {
  echo "Validando la existencia de $CONFIG_FILE..."
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "Error: no se encontró el archivo de configuración $CONFIG_FILE en $CURRENT_PATH."
    exit 1
  fi
  echo "$CONFIG_FILE existe."
}
# Función para ejecutar el configurador de PostgreSQL
function postgresql_config() {
  echo "Ejecutar el configurador de PostgreSQL..."
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
function postgresql_install() {
  echo "*******POSTGRESQL INSTALL*******"
  backup_postgresql_conf
  configure_listen_addresses
  add_entry_to_pg_hba
  start_service
  validate_config_file
  postgresql_config
  echo "**********ALL DONE**********"
}
# Llamar a la función principal
postgresql_install
