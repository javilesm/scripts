#!/bin/bash
# openldap_config.sh
# Variables
COMPANY="samava"
DOMAIN="avilesworks.com"
ADMIN_PASSWORD="1234"
SLAP_CONFIG="/etc/default/slapd"
export DEBIAN_FRONTEND=noninteractive
export SLAPD_NO_CONFIGURATION=true

function instalar_openldap() {
  # Instalar OpenLDAP
  echo "Instalando OpenLDAP..."
  sudo apt-get install -y slapd ldap-utils

  # Establecer contraseña de administrador
  echo "Configurando contraseña de administrador..."
  echo "cn=admin,$COMPANY" > admin.ldif
  echo "dn: cn=admin,$COMPANY" >> admin.ldif
  echo "objectClass: simpleSecurityObject" >> admin.ldif
  echo "objectClass: organizationalRole" >> admin.ldif
  echo "userPassword: $(slappasswd -s $ADMIN_PASSWORD)" >> admin.ldif
  echo "cn: admin" >> admin.ldif
  sudo ldapadd -x -D cn=admin,cn=config -W -f admin.ldif
  rm admin.ldif

  # Configurar dominio y organización
  echo "Configurando dominio y organización..."
  sudo ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=$DOMAIN
-
replace: olcRootDN
olcRootDN: cn=admin,dc=$DOMAIN
-
add: olcRootPW
olcRootPW: $(slappasswd -s $ADMIN_PASSWORD)
-
replace: olcAccess
olcAccess: {0}to * by * read
EOF

  # Reiniciar el servicio slapd
  restart_service
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
  configurar_openldap
  configurar_interfaces_red
  restart_service
}
# Llamar a la funcion principal
openldap_config
