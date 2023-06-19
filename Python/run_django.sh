#!/bin/bash
# run_django.sh
# Variables 
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
NODE_SCRIPT="$PARENT_DIR/NodeJS/nodejs_install.sh"
DJANGO_ENV="venv"
WEB_DIR="/var/www/samava-cloud/django_project"
DJANGO_PROJECT="django_crud_api"
GID_NAME="www-data"
UID_NAME="www-data"
SETTINGS_FILE="$WEB_DIR/$DJANGO_PROJECT/settings.py" # Ruta al archivo de configuración settings.py
# Vector con las direcciones IP o nombres de host que deseas permitir
HOSTS=("localhost" 
  "127.0.0.1"
  "[::1]"
  "3.220.58.75"
  ) 

# Función para crear el directorio de la app
function make_app_dir() {
  # crear el directorio de la app
  echo "Creando el directorio de la app en '$WEB_DIR'..."
  sudo mkdir -p "$WEB_DIR"
  cd "$WEB_DIR"
  python -m venv "$DJANGO_ENV"
}
# Función para activar el entorno virtual
function activate_virtual_environment() {
  # activar el entorno virtual
  echo "Activando el entorno virtual '$DJANGO_ENV'..."
  source "$WEB_DIR/$DJANGO_ENV/bin/activate"
}
# Función para instalar Django en el entorno virtual
function install_django() {
    pip install django
}
# Función para crear un nuevo proyecto Django
function create_django_project() {
  # crear un nuevo proyecto Django
  echo "Creando un nuevo proyecto Django '$DJANGO_PROJECT'..."
  django-admin startproject "$DJANGO_PROJECT" .
  move_project_directory
  change_directory_permissions
}

# Función para mover el proyecto al directorio /var/www/django
function move_project_directory() {
    sudo mv "$DJANGO_PROJECT" "$WEB_DIR"
}
# Función para verificar si el archivo de configuración existe
function validate_script_file() {
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$NODE_SCRIPT" ]; then
    echo "ERROR: El archivo de configuración '$NODE_SCRIPT no se puede encontrar en la ruta '$CONFIG_PATH'."
    exit 1
  fi
  echo "El archivo de configuración '$NODE_SCRIPT existe."
}
# Función para ejecutar el configurador de Postfix
function run_script() {
  echo "Ejecutar el configurador '$NODE_SCRIPT'..."
    # Intentar ejecutar el archivo de configuración de Postfix
  if sudo bash "$NODE_SCRIPT"; then
    echo "El archivo de configuración '$NODE_SCRIPT' se ha ejecutado correctamente."
  else
    echo "ERROR: No se pudo ejecutar el archivo de configuración '$NODE_SCRIPT'."
    exit 1
  fi
  echo "Configurador '$NODE_SCRIPT' ejecutado."
}

# Función para cambiar los permisos del directorio del proyecto
function change_directory_permissions() {
    sudo chown -R $GID_NAME:$UID_NAME "$WEB_DIR"
    # Reemplaza "yourusername" con tu nombre de usuario real
}
function add_host() {
  # Verificar si el archivo de configuración existe
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$SETTINGS_FILE" ]; then
    echo "ERROR: El archivo de configuración '$SETTINGS_FILE' no se puede encontrar en la ruta '$CONFIG_PATH'."
    exit 1
  fi
  echo "El archivo de configuración '$SETTINGS_FILE' existe."

  # Verificar si HOSTS ya están en ALLOWED_HOSTS
  echo "Verificando si HOSTS ya están en ALLOWED_HOSTS..."
  for HOST in "${HOSTS[@]}"; do
    if grep -Fxq "'$HOST'," "$SETTINGS_FILE"; then
      echo "El host '$HOST' ya está en ALLOWED_HOSTS."
    else
      # Agregar HOST a ALLOWED_HOSTS
      sed -i "s/\(ALLOWED_HOSTS\s*=\s*\[\)/\1\n    '$HOST',/" "$SETTINGS_FILE"
      echo "Se agregó '$HOST' a ALLOWED_HOSTS en $SETTINGS_FILE."
    fi
  done
  echo "Se agregó '$HOST' a ALLOWED_HOSTS en $SETTINGS_FILE."

}
# Función para ejecutar el servidor de desarrollo
function run_server() {
  cd "$WEB_DIR" && python manage.py runserver
}
 function run_django() {
  echo "************RUN DJANGO************"
  make_app_dir
  activate_virtual_environment
  install_django
  create_django_project
  add_host
  validate_script_file
  run_script
  run_server
  echo "************ALL DONE************"
 }
 run_django
