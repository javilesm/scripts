#!/bin/bash
# openldap_config.sh
# Variables
DOMAIN="avilesworks.com"
PASSWORD="Mexico2023-"
function configurar_openldap() {
  # Configuración inicial de OpenLDAP
  echo "Configuración inicial de OpenLDAP..."
  sudo dpkg-reconfigure slapd

  # Respuestas a las preguntas del asistente de configuración
  sudo debconf-set-selections <<EOF
slapd slapd/password1 password "$PASSWORD"
slapd slapd/password2 password "$PASSWORD"
slapd slapd/domain string "$DOMAIN"
EOF

  # Iniciar configuración inicial
  sudo dpkg-reconfigure -f noninteractive slapd
}

function verificar_estado() {
  # Verificar estado del servicio
  echo "Verificando el estado del servicio..."
  sudo systemctl status slapd
}

# Funcion principal
function openldap_config() {
  configurar_openldap
  verificar_estado
}
# Llamar a la funcion principal
openldap_config
