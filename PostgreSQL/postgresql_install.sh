#!/bin/bash
# postgresql_install.sh
# Variables
CONFIG_FILE="postgresql_config.sh"
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
# Función para verificar si se ejecuta el script como root
function check_root() {
  echo "Verificando si se ejecuta el script como root"
  if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ser ejecutado como root"
    exit 1
  fi
}
# Función para verificar si PostgreSQL ya está instalado
function check_postgresql_installed() {
  echo "Verificando si PostgreSQL ya está instalado"
  if command -v psql &> /dev/null
  then
    echo "PostgreSQL ya está instalado en este sistema."
    exit 0
  fi
}
# Función para instalar PostgreSQL
function install_postgresql() {
  echo "Instalando PostgreSQL..."
  if ! sudo apt-get install postgresql postgresql-contrib -y; then
    echo "Error: No se pudo instalar PostgreSQL."
    exit 1
  fi
}
# Función para comprobar si PostgreSQL se ha instalado correctamente
function check_postgresql_installation() {
  echo "Comprobando si PostgreSQL se ha instalado correctamente"
  if ! command -v psql &> /dev/null
  then
    echo "PostgreSQL no se ha instalado correctamente."
    exit 1
  fi
}
# Función para realizar una copia de seguridad de postgresql.conf
function backup_postgresql_conf() {
  echo "Realizando una copia de seguridad de postgresql.conf..."
  if ! sudo cp /etc/postgresql/$(ls /etc/postgresql)/main/postgresql.conf /etc/postgresql/$(ls /etc/postgresql)/main/postgresql.conf.backup; then
    echo "Error al realizar una copia de seguridad de postgresql.conf"
    exit 1
  fi
}
# Función para configurar listen_addresses en postgresql.conf
function configure_listen_addresses() {
  echo "Configurando listen_addresses en postgresql.conf..."
  if ! sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/$(ls /etc/postgresql)/main/postgresql.conf; then
    echo "Error al configurar listen_addresses en postgresql.conf"
    exit 1
  fi
}
# Función para agregar una entrada en pg_hba.conf
function add_entry_to_pg_hba() {
  echo "Agregando entrada en pg_hba.conf..."
  if ! echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/$(ls /etc/postgresql)/main/pg_hba.conf > /dev/null; then
    echo "Error al agregar entrada en pg_hba.conf"
    exit 1
  fi
}
# Función para ejecutar el configurador de PostgreSQL
function postgresql_config() {
  echo "Ejecutar el configurador de PostgreSQL..."
  sudo bash "$CURRENT_PATH/$CONFIG_FILE"
}
# Función principal
function postgresql_install() {
  echo "*******POSTGRESQL INSTALL*******"
  check_root
  check_postgresql_installed
  install_postgresql
  check_postgresql_installation
  backup_postgresql_conf
  configure_listen_addresses
  add_entry_to_pg_hba
  postgresql_config
  echo "**********ALL DONE**********"
}
# Llamar a la función principal
postgresql_install
