#!/bin/bash
# openldap_config.sh
# Variables
COMPANY="samava"
DOMAIN="avilesworks.com"
ADMIN_PASSWORD="Mexico2023-"
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
  restart_service
  verificar_estado
}
# Llamar a la funcion principal
openldap_config
