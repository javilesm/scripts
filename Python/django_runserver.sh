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
# Función para activar el entorno virtual
function activate_virtual_environment() {
  # activar el entorno virtual
  echo "Activando el entorno virtual '$DJANGO_ENV'..."
  source "$WEB_DIR/$DJANGO_ENV/bin/activate"
}
# Función para instalar Django en el entorno virtual
function install_django() {
    pip install django django-environ djangorestframework django-cors-headers django-storages django-ckeditor pillow pyscopg2
}
# Función para ejecutar el servidor de desarrollo
function run_server() {
  # ejecutar el servidor de desarrollo
  echo "Procediendo a ejecutar el servidor de desarrollo..."
  cd "$WEB_DIR"
  python manage.py runserver $ADMIN_PORT
}
 function django_runserver() {
  echo "************DJANGO RUNSERVER************"
  activate_virtual_environment
  #install_django
  run_server
  echo "************ALL DONE************"
 }
django_runserver
