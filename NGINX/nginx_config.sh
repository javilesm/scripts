#! /bin/bash
# nginx_config.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
HMTL_PATH="/var/www/html/"
# Función para crear el directorio principal de Nginx
function mkdir() {
  # Verificar si el directorio ya existe
  if [ -d "$HMTL_PATH" ]; then
    echo "El directorio principal de Nginx ya existe en la ruta especificada."
  else
    # crear el directorio principal de Nginx
    echo "Creando el directorio principal de Nginx..."
    if sudo mkdir -p "$HMTL_PATH"; then
      echo "El directorio principal de NGINX se ha creado correctamente."
    else
      echo "Error: No se pudo crear el directorio principal de Nginx en la ruta especificada."
      exit 1
    fi
  fi
}
mkdir
