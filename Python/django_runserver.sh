#!/bin/bash
# django_runserver.sh
# Variables 
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
NODE_SCRIPT="$PARENT_DIR/NodeJS/nodejs_install.sh"
DJANGO_ENV="venv"
WEB_DIR="/var/www/samava-cloud/django_project"
DJANGO_PROJECT="django_crud_api"
ADMIN_PORT="8000"
REACT_APP="react-app"
WEB_DIR="/var/www/samava-cloud/django_project"
REACT_APP_PATH="$WEB_DIR/$REACT_APP"
# Función para activar el entorno virtual
function activate_virtual_environment() {
  # activar el entorno virtual
  echo "Activando el entorno virtual '$DJANGO_ENV'..."
  source "$WEB_DIR/$DJANGO_ENV/bin/activate"
}
# Función para ejecutar el servidor de desarrollo
function run_server() {
  # ejecutar el servidor de desarrollo
  echo "Procediendo a ejecutar el servidor de desarrollo..."
  cd "$WEB_DIR"
  python manage.py runserver $ADMIN_PORT
}
# Función para inicializar la aplicacion React
function npm_start() {
  # Inicializar aplicacion React
  echo "Inicializando la aplicacion React..."
  cd "$REACT_APP_PATH"
  npm start
}
function django_runserver() {
  echo "************DJANGO RUNSERVER************"
  activate_virtual_environment
  run_server &
  npm_start &
  wait
  echo "************ALL DONE************"
}
django_runserver
