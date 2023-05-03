#! /bin/bash
# nginx_config.sh
# Variables
HTML_PATH="/var/www/html/"
# Función para crear el directorio principal de Nginx
function mkdir() {
  # Verificar si el directorio ya existe
  if [ -d "$HTML_PATH" ]; then
    echo "El directorio principal de Nginx ya existe en la ruta especificada. Ruta: '$HTML_PATH'"
  else
    # crear el directorio principal de Nginx
    echo "Creando el directorio principal de Nginx..."
    if sudo mkdir -p "$HTML_PATH"; then
      echo "El directorio principal de NGINX se ha creado correctamente."
    else
      echo "Error: No se pudo crear el directorio principal de Nginx en la ruta especificada. Ruta: '$HTML_PATH'"
      exit 1
    fi
  fi
}
# Función principal
function nginx_config() {
  echo "**********NGINX CONFIG***********"
  mkdir
  echo "*************ALL DONE**************"
}
# Llamar a la funcion princial
nginx_config
