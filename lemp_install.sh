#! /bin/bash
# lemp_install.sh
# Variables
REPO_FILE="repositories.txt"
REPO_PATH=$(dirname "$0")/$REPO_FILE
# Verificar que el usuario tiene permisos de administrador
if [[ $(id -u) -ne 0 ]]; then
    echo "Este script debe ser ejecutado con permisos de administrador."
    exit 1
fi
# Función para actualizar paquetes
function update_packages () {
  echo "Actualizando paquetes..."
  sudo apt update -qq
}
# Función para agregar repositorios
function add_repositories () {
    echo "Agregando repositorios..."
    while read -r repository; do
        if ! yes '' | sudo add-apt-repository "$repository" -qq; then
        echo "No se pudo agregar el repositorio: $repository"
        exit 1
        fi
    done < "$REPO_PATH"
}
# Función para instalar Tree si no está instalado
function install_tree () {
  if [ $(dpkg-query -W -f='${Status}' tree 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Instalando Tree..."
    if ! sudo apt install tree -yqq; then
      echo "No se pudo instalar Tree"
      exit 1
    fi
  else
    echo "Tree ya está instalado."
  fi
}
# Función para instalar ZIP
function install_zip () {
  if [ $(dpkg-query -W -f='${Status}' zip 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Instalando ZIP..."
    if ! sudo apt-get install zip -yqq; then
      echo "No se pudo instalar ZIP"
      exit 1
    fi
  else
    echo "ZIP ya está instalado."
  fi
}
# Función para instalar NGINX
function install_nginx () {
  if [ $(dpkg-query -W -f='${Status}' nginx 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Instalando NGINX..."
    if ! sudo apt install nginx -yqq; then
      echo "No se pudo instalar NGINX"
      exit 1
    fi
  else
    echo "NGINX ya está instalado."
  fi
}
# Función para instalar MySQL
function install_mysql () {
  if [ $(dpkg-query -W -f='${Status}' mysql-server 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Instalando MySQL..."
    if ! sudo apt install mysql-server -yqq; then
      echo "No se pudo instalar MySQL"
      exit 1
    fi
  else
    echo "MySQL ya está instalado."
  fi
}
# Función para instalar PHP si no está instalado
function install_php () {
  if [ $(dpkg-query -W -f='${Status}' php 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Instalando PHP..."
    if ! sudo apt install php-fpm php-cli php-common php-mysql php-mcrypt php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip php-pear php-imagick php-imap php-ldap php-tidy php-json php-bcmath php-apcu -yqq; then
      echo "No se pudo instalar PHP"
      exit 1
    fi
  else
    echo "PHP ya está instalado."
  fi
}
# Función principal
function lemp_install () {
    echo "*******LEMP******"
    update_packages
    add_repositories
    update_packages
    install_tree
    install_zip
    install_nginx
    install_mysql
    install_php
    echo "LEMP instalado correctamente."
}
# Llamar a la funcion princial
lemp_install
