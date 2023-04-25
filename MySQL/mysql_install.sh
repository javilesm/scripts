#! /bin/bash
# mysql_install.sh
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
# Función principal
function mysql_install() {
    echo "*******MYSQL INSTALL******"
    install_mysql
    echo "*********ALL DONE********"
}
# Llamar a la funcion princial
mysql_install
