#! /bin/bash
# packages_install.sh
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PACKAGES_FILE="packages.txt"
PACKAGES_PATH="$CURRENT_DIR/$PACKAGES_FILE"
SUCCESS_PACKAGES=()
FAILED_PACKAGES=()
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
  echo "Leyendo la lista de paquetes: '$PACKAGES_PATH'..."
  while read -r package_item; do
    attempt=1
    success=false
    
    while [ $attempt -le 3 ]; do
      echo "Intentando instalar el paquete '$package_item' (Intento $attempt)..."
      if install_and_restart "$package_item"; then
        success=true
        SUCCESS_PACKAGES+=("$package_item")
        break
      fi
      
      attempt=$((attempt + 1))
      sleep 5
    done
    
    if ! $success; then
      FAILED_PACKAGES+=("$package_item")
    fi
  done < <(grep -v '^$' "$PACKAGES_PATH")
  
  echo "Todos los paquetes han sido leídos."
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

  # Verificar si hay problemas pendientes de configuración de dpkg
  echo "Verificando si hay problemas pendientes de configuración de dpkg..."
  if sudo dpkg-preconfigure --apt --frontend=teletype >/dev/null 2>&1; then
    echo "Se encontraron problemas pendientes de configuración de dpkg. Ejecutando 'sudo dpkg --configure -a'..."
    sudo dpkg --configure -a
    echo "Se ha corregido el problema pendiente de configuración de dpkg."
  fi

  # Intentar instalar el paquete hasta tres veces
  for ((attempt=1; attempt<=3; attempt++)); do
    echo "Instalando $package (Intento $attempt)..."
    if sudo apt-get install "$package" -y; then
      echo "El paquete '$package' se ha instalado correctamente en el intento $attempt."
      break
    else
      echo "Error al instalar el paquete '$package' en el intento $attempt."
      if [ $attempt -eq 3 ]; then
        echo "Se han realizado 3 intentos de instalación del paquete '$package'."
        return 1
      fi
      sleep 5
    fi
  done
  
  # Verificar si el paquete se instaló correctamente
  echo "Verificando si el paquete se instaló correctamente..."
  if dpkg -s "$package" >/dev/null 2>&1; then
    echo "El paquete '$package' se ha instalado correctamente."
  else
    echo "Error al instalar el paquete '$package' después de 3 intentos."
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
  sleep 30
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
