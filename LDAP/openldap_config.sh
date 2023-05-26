#!/bin/bash
# openldap_config.sh
# Variables
COMPANY="samava"
DOMAIN="avilesworks.com"
ADMIN_PASSWORD="1234"
SLAP_CONFIG="/etc/default/slapd"
ADMIN_FILE="/etc/ldap/slapd.d/admin.ldif"
export DEBIAN_FRONTEND=noninteractive
export SLAPD_NO_CONFIGURATION=true

function instalar_openldap() {
  # Instalar OpenLDAP
  echo "Instalando OpenLDAP..."
  echo "slapd slapd/no_configuration seen true" | sudo debconf-set-selections
  sudo apt-get update
  sudo apt-get install -y slapd ldap-utils

  # Establecer contraseña de administrador
  echo "Configurando contraseña de administrador..."
  echo "cn=admin,$COMPANY" > "$ADMIN_FILE"
  echo "dn: cn=admin,$COMPANY" >> "$ADMIN_FILE"
  echo "objectClass: simpleSecurityObject" >> "$ADMIN_FILE"
  echo "objectClass: organizationalRole" >> "$ADMIN_FILE"
  echo "userPassword: $(slappasswd -s $ADMIN_PASSWORD)" >> "$ADMIN_FILE"
  echo "cn: admin" >> "$ADMIN_FILE"
  sudo ldapadd -x -D cn=admin,cn=config -W -f "$ADMIN_FILE"
  sudo rm "$ADMIN_FILE"
  # Iniciar el servicio slapd
  iniciar_servicio_ldap
}
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
slapd slapd/password1 password $ADMIN_PASSWORD
slapd slapd/password2 password $ADMIN_PASSWORD
slapd shared/organization string $COMPANY
slapd slapd/domain string $DOMAIN
EOF
 
}
function iniciar_servicio_ldap() {
  # Iniciar el servicio slapd
  echo "Iniciando el servicio slapd..."
  sudo service slapd start
}

function configurar_interfaces_red() {
  # Configurar slapd para escuchar en todas las interfaces de red
  echo "Configurando slapd para escuchar en todas las interfaces de red..."
   #SLAPD_SERVICES
  if grep -q "#SLAPD_SERVICES" "$SLAP_CONFIG"; then
    sudo sed -i "s|^#SLAPD_SERVICES.*|SLAPD_SERVICES="ldap:///"|" "$SLAP_CONFIG" || { echo "ERROR: Hubo un problema al configurar el archivo '$SLAP_CONFIG': #SLAPD_SERVICES"; exit 1; }
  elif grep -q "SLAPD_SERVICES" "$SLAP_CONFIG"; then
    sudo sed -i "s|^SLAPD_SERVICES.*|SLAPD_SERVICES="ldap:///"|" "$SLAP_CONFIG" || { echo "ERROR: Hubo un problema al configurar el archivo '$SLAP_CONFIG': SLAPD_SERVICES"; exit 1; }
  else
    echo "SLAPD_SERVICES="ldap:///"" >> "$SLAP_CONFIG"
  fi
}

function restart_service() {
  # Reiniciar el servicio slapd
  echo "Reiniciando el servicio slapd..."
  sudo service slapd restart 
}

# Funcion principal
function openldap_config() {
  instalar_openldap
  #configurar_openldap
  #configurar_interfaces_red
  restart_service
}
# Llamar a la funcion principal
openldap_config
