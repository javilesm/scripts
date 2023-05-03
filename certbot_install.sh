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

# Función para instalar certbot
function instalar_certbot() {
  echo "Instalando Certbot..."
  if sudo apt-get install certbot -y; then
    echo "Certbot instalado correctamente."
  else
    echo "Error al instalar Certbot."
    exit 1
  fi
}

# Función principal
function main() {
  echo "**********INSTALACIÓN DE CERTBOT**********"
  if actualizar_sistema && instalar_certbot; then
    echo "**********INSTALACIÓN COMPLETADA**********"
  else
    echo "**********ERROR DURANTE LA INSTALACIÓN**********"
    exit 1
  fi
}

# Llamar a la función principal
main
