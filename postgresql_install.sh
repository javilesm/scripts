#!/bin/bash
# postgresql_install.sh
# Variables
CONFIG_FILE="postgresql_config.sh"
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual

# Función para verificar si se ejecuta el script como root
function check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ser ejecutado como root"
        exit 1
    fi
}

# Función para verificar si PostgreSQL ya está instalado
function check_postgresql_installed() {
    if command -v psql &> /dev/null
    then
        echo "PostgreSQL ya está instalado en este sistema."
        exit 0
    fi
}

# Función para actualizar el sistema
function update_system() {
  echo "Actualizando el sistema..."
  if ! apt update; then
    echo "Error: No se pudo actualizar el sistema."
    exit 1
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
    if ! command -v psql &> /dev/null
    then
        echo "PostgreSQL no se ha instalado correctamente."
        exit 1
    fi
}

# Función para configurar PostgreSQL para permitir conexiones remotas
function configure_postgresql_remote() {
  echo "Configurando PostgreSQL para permitir conexiones remotas..."

  # Realizar una copia de seguridad de postgresql.conf
  sudo cp /etc/postgresql/$(ls /etc/postgresql)/main/postgresql.conf /etc/postgresql/$(ls /etc/postgresql)/main/postgresql.conf.backup

  # Configurar listen_addresses en postgresql.conf
  if ! sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/$(ls /etc/postgresql)/main/postgresql.conf; then
    echo "Error al configurar listen_addresses en postgresql.conf"
    exit 1
  fi

  # Agregar entrada en pg_hba.conf
  if ! echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/$(ls /etc/postgresql)/main/pg_hba.conf > /dev/null; then
    echo "Error al agregar entrada en pg_hba.conf"
    exit 1
  fi
}

# unción para reiniciar el servicio de PostgreSQL
function restart_postgresql_service() {
    echo "Reiniciando el servicio de PostgreSQL..."
    sudo service postgresql restart
}

# Función para ejecutar el configurador de PostgreSQL
function postgresql_config() {
    echo "Ejecutar el configurador de PostgreSQL"
    sudo bash "$CURRENT_PATH/$CONFIG_FILE"
}

# Función principal
function postgres_install() {
    check_root
    check_postgresql_installed
    update_system
    install_postgresql
    check_postgresql_installation
    configure_postgresql_remote
    restart_postgresql_service
    postgresql_config
}

# Llamar a la función principal
postgres_install
