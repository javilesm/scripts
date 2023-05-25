#!/bin/bash
# openldap_config.sh
# Variables
COMPANY="samava"
DOMAIN="avilesworks.com"
ADMIN_PASSWORD="Mexico2023-"
SLAP_CONFIG="/etc/ldap/slapd.conf"
function configurar_openldap() {
  # Configuración inicial de OpenLDAP
  echo "Configuración inicial de OpenLDAP..."
  sudo dpkg-reconfigure slapd

  # Respuestas a las preguntas del asistente de configuración
  sudo debconf-set-selections <<EOF
slapd slapd/password1 password "$ADMIN_PASSWORD"
slapd slapd/password2 password "$ADMIN_PASSWORD"
slapd shared/organization string "$COMPANY"
slapd slapd/domain string "$DOMAIN"
EOF

  # Iniciar configuración inicial
  sudo dpkg-reconfigure -f noninteractive slapd
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
  sudo systemctl restart slapd
}
function verificar_estado() {
  # Verificar estado del servicio
  echo "Verificando el estado del servicio..."
  sudo systemctl status slapd
}

# Funcion principal
function openldap_config() {
  configurar_openldap
  configurar_interfaces_red
  restart_service
  verificar_estado
}
# Llamar a la funcion principal
openldap_config
