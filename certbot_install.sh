#!/bin/bash
# certbot_install.sh

# Función para actualizar el sistema
function actualizar_sistema() {
  echo "Actualizando sistema..."
  if sudo apt-get update -y; then
    echo "Sistema actualizado."
  else
    echo "Error al actualizar el sistema."
    exit 1
  fi
}
# Función para agregar repositorio
function add_repository() {
  echo "Agregando repositorio..."
  if sudo apt-add-repository -r ppa:certbot/certbot; then
    echo "Repositorio agregado."
  else
    echo "Error al agregar el repositorio."
    exit 1
  fi
}
# Función para instalar certbot
function instalar_certbot() {
  echo "Instalando Certbot..."
  if sudo apt-get install python3-certbot-nginx -y; then
    echo "Certbot instalado correctamente."
  else
    echo "Error al instalar Certbot."
    exit 1
  fi
}
# Función principal
function main() {
  echo "**********CERTBOT INSTALL**********"
  actualizar_sistema
  add_repository
  instalar_certbot
  echo "**********ALL DONE**********"
}
# Llamar a la función principal
main
