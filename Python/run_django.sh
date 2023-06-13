#!/bin/bash
# run_django.sh
# Variables 
DJANGO_ENV="venv"
WEB_DIR="/var/www/django"
DJANGO_PROJECT="django_crud_api"
GID_NAME="www-data"
UID_NAME="www-data"
# Función para crear el directorio de la app
function make_app_dir() {
  # crear el directorio de la app
  echo "Creando el directorio de la app en '$WEB_DIR'..."
  sudo mkdir -p "$WEB_DIR"
  cd "$WEB_DIR"
  python -m venv "$DJANGO_ENV"
  activate_virtual_environment
  install_django
}
# Función para activar el entorno virtual
function activate_virtual_environment() {
  # activar el entorno virtual
  echo "Activando el entorno virtual '$DJANGO_ENV'..."
  source "$DJANGO_ENV/bin/activate"
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

# Función para cambiar los permisos del directorio del proyecto
function change_directory_permissions() {
    sudo chown -R $GID_NAME:$UID_NAME "$WEB_DIR"
    # Reemplaza "yourusername" con tu nombre de usuario real
}
# Función para ejecutar el servidor de desarrollo
function run_server() {
    python manage.py runserver 0.0.0.0:8000
}
 function run_django() {
   echo "************RUN DJANGO************"
   make_app_dir
   create_django_project
   run_server
   echo "************ALL DONE************"
 }
 run_django
