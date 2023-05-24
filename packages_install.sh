#! /bin/bash
# packages_install.sh
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PACKAGES_FILE="packages.txt"
PACKAGES_PATH="$CURRENT_DIR/$PACKAGES_FILE"

# Exportar la variable DEBIAN_FRONTEND para evitar problemas con debconf
export DEBIAN_FRONTEND=noninteractive

# Función para verificar si el archivo de dominios existe
function validate_packages_file() {
    # verificar si el archivo de dominios existe
  echo "Verificando si el archivo de dominios existe..."
  if [ ! -f "$PACKAGES_PATH" ]; then
    echo "ERROR: El archivo de dominios '$PACKAGES_PATH' no se puede encontrar en la ruta '$PACKAGES_PATH'."
    exit 1
  fi
  echo "El archivo de dominios '$PACKAGES_FILE' existe."
}
# Función para leer la lista de paquetes e intentar instalar el paquete
function read_packages_file() {
    # leer la lista de dominios
    echo "Leyendo la lista de dominios: '$PACKAGES_PATH'..."
    while read -r package_item; do
      # intentar instalar el paquete
      echo "Intentando instalar el paquete: '$package_item'..."
      install_and_restart $package_item
    done < <(grep -v '^$' "$PACKAGES_PATH")
    echo "Todos los paquetes han sido leidos."
}
# Función para instalar un paquete y reiniciar los servicios afectados
function install_and_restart() {
  local package="$1"
  # Verificar si el paquete ya está instalado
  echo "Verificando si el paquete '$package' ya está instalado..."
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
    services=$(systemctl list-dependencies --reverse --quiet "$package" | grep -oP '^\w+(?=.service)')

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
  sleep 5
 
}
# Función para instalar Certbot
function install_certbot() {
  curl -o- https://raw.githubusercontent.com/vinyll/certbot-install/master/install.sh | bash
}
# Función principal
function packages_install() {
  validate_packages_file
  read_packages_file
  install_certbot
}
# Llamar a la funcion princial
packages_install
