#! /bin/bash
# nginx_install.sh
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
# Función principal
function nginx_install() {
    echo "*******NGINX INSTALL******"
    install_nginx
    echo "*********ALL DONE********"
}
# Llamar a la funcion princial
nginx_install
