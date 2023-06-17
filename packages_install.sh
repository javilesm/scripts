#!/bin/bash
# packages_install.sh
# Variables
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)" # Obtener el directorio actual
STATE_FILE="$CURRENT_DIR/packages_state.txt" # Archivo de estado
PACKAGES_FILE="$CURRENT_DIR/packages1.txt" # Lista de paquetes

# Función para solicitar un reinicio y continuar automáticamente después del reinicio
function reboot_and_continue() {
  echo "Se requiere un reinicio del sistema. El script se reanudará automáticamente después del reinicio."
  echo "Reiniciando el sistema..."
  sudo shutdown -r now
}

# Función para guardar el estado actual en el archivo de estado
function save_state() {
  echo "Guardando estado actual en el archivo de estado: $STATE_FILE"
  echo "current_script_index=$current_script_index" >"$STATE_FILE"
  echo "Estado actual '$current_script_index' guardado en: $STATE_FILE"
}

# Función para cargar el estado anterior desde el archivo de estado
function load_state() {
  echo "Cargando estado anterior desde el archivo de estado: $STATE_FILE"
  if [[ -f "$STATE_FILE" ]]; then
    source "$STATE_FILE"
  else
    echo "No se encontró un archivo de estado anterior. Iniciando desde el principio."
    current_script_index=0
  fi
}

# Exportar la variable DEBIAN_FRONTEND para evitar problemas con debconf
export DEBIAN_FRONTEND=noninteractive

function wait_for_automatic_updates() {
  echo "Esperando a que finalicen las actualizaciones automáticas..."
  sudo systemctl stop unattended-upgrades
  sleep 10
}

# Función para leer la lista de paquetes e intentar instalar el paquete
function read_packages_file() {
  # Leer la lista de paquetes
  echo "Leyendo la lista de paquetes: '$PACKAGES_FILE'..."
  
  # Verificar si el archivo de estado existe
  if [[ -f "$STATE_FILE" ]]; then
    load_state
  else
    echo "No se encontró un archivo de estado anterior. Iniciando desde el principio."
    current_script_index=0
  fi

  # Leer la lista de paquetes
  mapfile -t package_items < "$PACKAGES_FILE"

  # Verificar si se han instalado todos los paquetes
  if ((current_script_index >= ${#package_items[@]})); then
    echo "Se han instalado todos los paquetes de la lista '$PACKAGES_FILE'. No se ejecutará el siguiente script."
    exit 0
  fi

  # Recorrer la lista de paquetes
  for ((i=current_script_index; i<${#package_items[@]}; i++)); do
    package_item="${package_items[$i]}"

    # Imprimir el mensaje correspondiente al paquete
    echo "Intentando instalar el paquete '$package_item' de la lista '$PACKAGES_FILE'."

    # Intentar instalar el paquete y reiniciar
    install_and_restart "$package_item"

    # Esperar a que finalicen las actualizaciones automáticas
    wait_for_automatic_updates

    # Actualizar el índice actual en el archivo de estado
    current_script_index=$((i + 1))
    save_state

    # Solicitar reinicio y continuar después de cada paquete
    reboot_and_continue

  done

  # Todos los paquetes de la lista han sido leídos
  echo "Todos los paquetes de la lista '$PACKAGES_FILE' han sido leídos."

  # Eliminar el archivo de estado al finalizar todos los paquetes
  # sudo rm "$STATE_FILE"
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
}

# Función principal
read_packages_file
