#!/bin/bash
# openldap_config.sh
# Variables
COMPANY="samava"
DOMAIN="avilesworks.com"
ADMIN_PASSWORD="1234"
SLAP_CONFIG="/etc/ldap/ldap.conf"
export DEBIAN_FRONTEND=noninteractive
export SLAPD_NO_CONFIGURATION=true

function configurar_openldap() {
  # Configuración inicial de OpenLDAP
  echo "Configuración inicial de OpenLDAP..."
  # Iniciar configuración inicial
  sudo dpkg-reconfigure slapd 

  # Establecer respuestas para evitar el mensaje de configuración inicial y la eliminación de la base de datos
  sudo debconf-set-selections <<EOF
slapd slapd/no_configuration boolean true
slapd slapd/purge_database boolean false
slapd slapd/move_old_database boolean true
slapd slapd/password1 password "$ADMIN_PASSWORD"
slapd slapd/password2 password "$ADMIN_PASSWORD"
slapd shared/organization string "$COMPANY"
slapd slapd/domain string "$DOMAIN"
EOF

  
}
function configurar_interfaces_red() {
  # Configurar slapd para escuchar en todas las interfaces de red
  echo "Configurando slapd para escuchar en todas las interfaces de red..."

  # Abrir el archivo de configuración slapd.conf
  sudo sed -i "s|^SLAPD_SERVICES.*|SLAPD_SERVICES="ldap:///"|" "$SLAP_CONFIG"  || { echo "ERROR: Hubo un problema al configurar el archivo '$SLAP_CONFIG': SLAPD_SERVICES"; exit 1; }
}
function restart_service() {
  # Reiniciar el servicio slapd
  echo "Reiniciando el servicio slapd..."
  sudo service slapd restart 
}

# Funcion principal
function openldap_config() {
  configurar_openldap
  configurar_interfaces_red
  restart_service
}
# Llamar a la funcion principal
openldap_config
