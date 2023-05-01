#!/bin/bash
# postgresql_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_FILE="postgresql_config.sh"
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"
# Función para instalar PostgreSQL
function install_postgresql() {
  install_and_restart postgresql postgresql-contrib
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
# Función para realizar una copia de seguridad de postgresql.conf
function backup_postgresql_conf() {
  echo "Realizando una copia de seguridad de postgresql.conf..."
  if ! sudo cp /etc/postgresql/$(ls /etc/postgresql)/main/postgresql.conf /etc/postgresql/$(ls /etc/postgresql)/main/postgresql.conf.backup; then
    echo "Error al realizar una copia de seguridad de postgresql.conf"
    exit 1
  fi
  echo "Copia de seguridad de postgresql.conf realizada."
}
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
  sudo bash "$CONFIG_PATH"
  echo "Configurador de PostgreSQL ejecutado."
}
# Función principal
function postgresql_install() {
  echo "*******POSTGRESQL INSTALL*******"
  install_postgresql
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
