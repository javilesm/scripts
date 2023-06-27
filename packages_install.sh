#!/bin/bash
# packages_install.sh
# Variables
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
STATE_FILE="$CURRENT_DIR/packages_state.txt" # Archivo de estado
PACKAGES_FILE="$CURRENT_DIR/packages1.txt" # Lista de paquetes
DATE=$(date +"%Y%m%d_%H%M%S") # Obtener la fecha y hora actual para el nombre del archivo de registro
LOG_FILE="packages_install_$DATE.log" # Nombre del archivo de registro
LOG_PATH="$CURRENT_DIR/$LOG_FILE" # Ruta al archivo de registro
RUN_SCRIPT_FILE="run_scripts.sh"
RUN_SCRIPT_PATH="$PARENT_DIR/$RUN_SCRIPT_FILE"
# Función para crear un archivo de registro
function create_log() {
    # Verificar si el archivo de registro ya existe
    if [ -f "$LOG_PATH" ]; then
        echo "El archivo de registro '$LOG_FILE' ya existe."
        return 1
    fi
    
    # Intentar crear el archivo de registro
    echo "Creando archivo de registro '$LOG_FILE'... "
    sudo touch "$LOG_PATH"
    if [ $? -ne 0 ]; then
        echo "Error al crear el archivo de registro '$LOG_FILE'."
        return 1
    fi
    echo "Archivo de registro '$LOG_FILE' creado exitosamente. "
    # Redirección de la salida estándar y de error al archivo de registro
    exec &> >(tee -a "$LOG_PATH")
    if [ $? -ne 0 ]; then
        echo "Error al redirigir la salida estándar y de error al archivo de registro."
        return 1
    fi
    # Mostrar un mensaje de inicio
    echo "Registro de eventos iniciado a las $(date '+%Y-%m-%d %H:%M:%S')."
    # Agregar una función de finalización para detener el logging
    trap "stop_logging" EXIT
}
# Funcion para actualizar sistema
function actualizar_sistema() {
  # actualizar sistema
  echo "Actualizando sistema..."
  if sudo apt-get update -y; then
    echo "Sistema actualizado."
  else
    echo "Error al actualizar el sistema."
    exit 1
  fi
}

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
  #sudo apt --fix-broken install
  sleep 10
}
# Función para reparar la configuración interrumpida de los paquetes
function fix_dpkg_interrupted() {
  echo "Reparando la configuración interrumpida de los paquetes..."
  sudo dpkg --configure -a
  if [ $? -eq 0 ]; then
    echo "La configuración de los paquetes se ha reparado correctamente."
  else
    echo "Error al reparar la configuración de los paquetes."
    exit 1
  fi
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
    echo "Se han instalado todos los paquetes de la lista '$PACKAGES_FILE'."
    exit 0
  fi
  
   # Verificar si la configuración de los paquetes se interrumpió
  if sudo dpkg --configure -a >/dev/null 2>&1; then
    echo "La configuración de los paquetes se encontraba interrumpida. Reparando..."
    fix_dpkg_interrupted
  fi
  
  # Recorrer la lista de paquetes
  for ((i=current_script_index; i<${#package_items[@]}; i++)); do
    package_item="${package_items[$i]}"
    
    # Actualizar el sistema
    actualizar_sistema
    
    # Imprimir el mensaje correspondiente al paquete
    echo "Intentando instalar el paquete '$package_item' de la lista '$PACKAGES_FILE'."

    # Intentar instalar el paquete y reiniciar
    install_and_restart "$package_item"
    
    # Verificar si la configuración de los paquetes se interrumpió
    if sudo dpkg --configure -a >/dev/null 2>&1; then
      echo "La configuración de los paquetes se encontraba interrumpida. Reparando..."
      fix_dpkg_interrupted
    fi

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

  # Llamar a la función para generar el resumen de los paquetes instalados
  generate_package_summary
  comment_cron_entry
  echo "Ahora se ejecutará el siguiente script: '$RUN_SCRIPT_PATH'"
  run_script
  
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
function run_script() {
  echo "Ejecutar el configurador '$RUN_SCRIPT_FILE'..."
    # Intentar ejecutar el archivo de configuración de Postfix
  if sudo bash "$RUN_SCRIPT_PATH"; then
    echo "El archivo '$RUN_SCRIPT_FILE' se ha ejecutado correctamente."
  else
    echo "ERROR: No se pudo ejecutar el archivo '$RUN_SCRIPT_FILE'."
    exit 1
  fi
  echo "Configurador '$RUN_SCRIPT_FILE' ejecutado."
}
# Función para detener el logging y mostrar un mensaje de finalización
function stop_logging() {
    # Restaurar la redirección de la salida estándar y de error a la terminal
    exec &> /dev/tty
    if [ $? -ne 0 ]; then
        echo "Error al restaurar la redirección de la salida estándar y de error a la terminal."
    fi
    # Mostrar un mensaje de finalización
    echo "Registro de eventos finalizado a las $(date '+%Y-%m-%d %H:%M:%S')."
    echo "Ruta al registro de eventos: '$LOG_PATH'"
}
# Función para generar un resumen de los paquetes instalados
function generate_package_summary() {
  echo "Generando resumen de paquetes instalados..."
  installed_packages=$(dpkg --get-selections | grep -v deinstall | cut -f1)

  if [ -z "$installed_packages" ]; then
    echo "No se encontraron paquetes instalados en el sistema."
  else
    echo "Paquetes instalados:"
    echo "$installed_packages"
  fi
}
# Función para comentar la entrada al crontab para automatizar la ejecución del script tras cada reinicio
function comment_cron_entry() {
  local cron_entry="@reboot bash $CURRENT_PATH/scripts/packages_install.sh"
  local new_cron_entry="#@reboot bash $CURRENT_PATH/scripts/packages_install.sh"
  # comentar la entrada al crontab para automatizar la ejecución del script tras cada reinicio
  echo "Comentando la entrada al crontab para automatizar la ejecución del script tras cada reinicio..."
  
  # Verificar si la entrada ya existe en el crontab
  if sudo crontab -l | grep -q "$cron_entry"; then
    # Comentar la entrada al crontab utilizando echo y redirección de entrada
    sudo sed -i "s|$cron_entry|$new_cron_entry|g" /etc/crontab
    echo "Entrada del crontab actualizada."
  else
    echo "La entrada no existe."
  fi
}
# Función principal
function packages_install() {
  echo "**********PACKAGES INSTALLER***********"
  create_log
  read_packages_file
  stop_logging
  echo "**************ALL DONE***************"
}
# Llamar a la función principal
packages_install
