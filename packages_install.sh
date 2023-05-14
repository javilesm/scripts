#! /bin/bash
# packages_install.sh
# Función para instalar paquetes si no están instalados
function package_install() {
  install_and_restart lsb-release
  install_and_restart ca-certificates
  install_and_restart apt-transport-https
  install_and_restart software-properties-common
  install_and_restart clamav
  install_and_restart clamav-daemon
  install_and_restart tree
  install_and_restart telnet
  install_and_restart dnsutils
  install_and_restart libmailutils-dev
  install_and_restart python3-certbot-nginx
  install_and_restart zip
  install_and_restart snapd
  install_and_restart jq
  install_and_restart sqlite3
  install_and_restart libsqlite3-dev
  install_and_restart mysql-server
  install_and_restart postgresql
  install_and_restart postgresql-contrib
  install_and_restart transmission-gtk 
  install_and_restart transmission-cli 
  install_and_restart transmission-common 
  install_and_restart transmission-daemon
  install_and_restart dovecot-core
  install_and_restart dovecot-lmtp
  install_and_restart dovecot-dev
  install_and_restart dovecot-ldap
  install_and_restart dovecot-imapd
  install_and_restart dovecot-pop3d
  install_and_restart dovecot-mysql
  install_and_restart dovecot-sqlite
  install_and_restart dovecot-sieve
  install_and_restart dovecot-solr
  install_and_restart dovecot-submissiond
  install_and_restart dovecot-antispam
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
}
# Función para instalar Certbot
function install_certbot() {
  curl -o- https://raw.githubusercontent.com/vinyll/certbot-install/master/install.sh | bash
}
# Llamar a la funcion princial
package_install
install_certbot
