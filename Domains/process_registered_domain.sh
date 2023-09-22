#!/bin/bash
# process_registered_domain.sh

# Obtener el valor de REGISTERED_DOMAIN como argumento
DOMAIN="$1"
NGINX_DIR="/var/www"
WEB_DIR="html"
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory

# Realizar acciones con el valor DOMAIN
echo "El valor de DOMAIN es: $DOMAIN"

# Resto del código del otro script...

# Función para eliminar el directorio /var/html
function rm_html_dir() {
  # eliminar el directorio '$NGINX_DIR/$WEB_DIR'
  echo "Eliminando el directorio '$NGINX_DIR/$WEB_DIR'..."
  sudo rm -rf "$NGINX_DIR/$WEB_DIR"
}
