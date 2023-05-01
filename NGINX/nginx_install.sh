#! /bin/bash
# nginx_install.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_FILE="nginx_config.sh"
CONFIG_PATH="$CURRENT_PATH/$CONFIG_FILE"
# Función para instalar NGINX
function install_nginx () {
  install_and_restart nginx
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
# Función para validar la existencia de nginx_config.sh
function validate_config_file() {
  echo "Validando la existencia de $CONFIG_FILE..."
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "Error: no se encontró el archivo de configuración $CONFIG_FILE en $CURRENT_PATH."
    exit 1
  fi
  echo "$CONFIG_FILE existe."
}
# Función para ejecutar el configurador de Nginx
function nginx_config() {
  echo "Ejecutar el configurador de PostgreSQL..."
    # Intentar ejecutar el archivo de configuración de Nginx
  if sudo bash "$CONFIG_PATH"; then
    echo "El archivo de configuración '$CONFIG_FILE' se ha ejecutado correctamente."
  else
    echo "No se pudo ejecutar el archivo de configuración '$CONFIG_FILE'."
    exit 1
  fi
  echo "Configurador '$CONFIG_FILE' ejecutado."
}
# Función principal
function nginx_install() {
    echo "*******NGINX INSTALL******"
    install_nginx
    validate_config_file
    nginx_config
    echo "*********ALL DONE********"
}
# Llamar a la funcion princial
nginx_install
