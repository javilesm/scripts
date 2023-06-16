#!/bin/bash
# nodejs_install.sh
# Variables 
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
REACT_APP="react-app"
WEB_DIR="/var/www/samava-cloud/django_project"
DJANGO_PROJECT="django_crud_api"
REACT_APP_PATH="$WEB_DIR/$REACT_APP"
HTML_PATH="/var/www/samava-cloud/html"
INDEX_FILE="index.html"
INDEX_PATH="$CURRENT_DIR/$INDEX_FILE"
SETTINGS_FILE="$WEB_DIR/$DJANGO_PROJECT/settings.py" # Ruta al archivo de configuración settings.py
URLS_FILE="$WEB_DIR/$DJANGO_PROJECT/urls.py" # Ruta al archivo de configuración urls.py
# Vector con los directorios
DIRS=("localhost" 
  "127.0.0.1"
  "[::1]"
  "3.220.58.75"
  ) 
set -e
function get_latest_node_version() {
  echo "Obteniendo la última versión de Node.js..."
  version=$(curl -sL https://nodejs.org/dist/index.json | jq -r '.[0].version')
  if [[ -z $version ]]; then
    echo "Error: no se pudo obtener la última versión de Node.js"
    exit 1
  fi
  echo "La última versión de Node.js es: $version"
  export version
}
# Función para descargar la última versión de Node.js para Linux
function download_latest_node_version() {
  version=$1
  echo "Descargando Node.js $version para Linux..."
  url="https://nodejs.org/dist/$version/node-$version-linux-x64.tar.xz"
  echo "Origen: $url"
  if ! curl -sL -o node.tar.xz $url; then
    echo "Error: no se pudo descargar Node.js desde $url"
    exit 1
  fi
}
function verify_node_integrity() {
  echo "Verificando integridad del archivo descargado..."
  if ! xz -t node.tar.xz; then
    echo "Error: el archivo descargado está dañado o incompleto."
    exit 1
  fi
  echo "Arhivo descargado sin pedos."
}
# Función para extraer el archivo comprimido de Node.js
function extract_node_archive() {
  echo "Extrayendo archivos..."
  if ! tar -xf node.tar.xz -C /usr/local >/dev/null 2>&1; then
    echo "Ocurrió un error al extraer el archivo de Node.js."
    exit 1
  fi
  # Cambiar el nombre del directorio extraído a "node"
   if [[ ! -d "/usr/local/" ]]; then
    sudo mkdir -p /usr/local/
  fi
  
  sudo mkdir -p /usr/local/node
  if ! sudo mv node-$version-linux-x64/* /usr/local/node; then
    echo "Ocurrió un error al mover los archivos de Node.js a /usr/local/node."
    exit 1
  fi

  sudo rm -rf /usr/local/node-$version-linux-x64
  echo "Archivo extraído y directorio renombrado a 'node'."
}

# Crea enlaces simbólicos para los binarios node, npm y npx
function create_symlinks() {
  echo "Creando enlaces simbólicos para los binarios node, npm y npx"
  if [[ -L /usr/local/bin/node ]]; then
    echo "El enlace simbólico para node ya existe"
  else
    if ! ln -s /usr/local/node/bin/node /usr/local/bin/node; then
      echo "Error: no se pudo crear el enlace simbólico para node"
      exit 1
    fi
    echo "Fue creado el enlace simbólico para node"
  fi
  
  if [[ -L /usr/local/bin/npm ]]; then
    echo "El enlace simbólico para npm ya existe"
  else
    if ! ln -s /usr/local/node/bin/npm /usr/local/bin/npm; then
      echo "Error: no se pudo crear el enlace simbólico para npm"
      exit 1
    fi
    echo "Fue creado el enlace simbólico para npm"
  fi
  
  if [[ -L /usr/local/bin/npx ]]; then
    echo "El enlace simbólico para npx ya existe"
  else
    if ! ln -s /usr/local/node/bin/npx /usr/local/bin/npx; then
      echo "Error: no se pudo crear el enlace simbólico para npx"
      exit 1
    fi
    echo "Fue creado el enlace simbólico para npx"
  fi
}
# Función para buscar el archivo .bashrc en el sistema
function find_bashrc() {
  echo "Buscando el archivo .bashrc en el sistema"
  BASHRC_PATH=$(find /home/ -name ".bashrc" 2>/dev/null)
  if [ -z "$BASHRC_PATH" ]; then
    echo "No se encontró el archivo .bashrc en la carpeta home."
    BASHRC_PATH=$(find / -name ".bashrc" 2>/dev/null)
    if [ -z "$BASHRC_PATH" ]; then
      echo "No se pudo encontrar el archivo .bashrc en el sistema."
      exit 1
    fi
  fi
  echo "La ruta de ubicación del archivo .bashrc es: $BASHRC_PATH"
  export BASHRC_PATH
}
# Función para actualizar el archivo .bashrc
function add_to_bashrc() {
  CURRENT_PATH=$(dirname "$(readlink -f "$0")") # Obtener la ruta actual del script
  echo "Actualizando el archivo .bashrc..."
  echo 'export PATH=$PATH:/usr/local/node/bin' >> "$BASHRC_PATH"
  if ! source "$BASHRC_PATH"; then
        echo "No se pudo actualizar el archivo $BASHRC_PATH."
        exit 1
  fi
  echo "$BASHRC_PATH ha sido actualizado exitosamente."
}
# Función para crear estructura de directorios
function make_dirs() {
  # Crear directorio principal
  sudo mkdir -p "$WEB_DIR"
  # Crear directorio HTML
  sudo mkdir -p "$HTML_PATH"
  sudo cp "$INDEX_PATH" "$HTML_PATH"
  # Crear directorio para la app de React
  sudo mkdir -p "$REACT_APP_PATH"
}

# Función para actualizar el archivo .bashrc
function create_react_app() {
  # Comprobar si Node.js y npm están instalados
  if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo "Error: Node.js y npm no están instalados."
    echo "Por favor, instale Node.js y npm antes de ejecutar este script."
    exit 1
  fi

  # Comprobar si create-react-app está instalado
  if ! command -v create-react-app &> /dev/null; then
    echo "Need to install the following packages:"
    echo "  create-react-app@5.0.1"
    echo "Automáticamente confirmando la instalación..."
    echo ""
    sleep 2
    echo "Instalando create-react-app..."
    sudo npm install -g create-react-app@5.0.1
  fi
 
  # Crear una aplicación React
  echo "Creando una aplicación React en el directorio '$REACT_APP_PATH'..."
  cd "$REACT_APP_PATH"
  sudo npx create-react-app . && npm run build

  # Notificar que la aplicación React se ha creado correctamente
  echo "La aplicación React se ha creado correctamente en: $REACT_APP_PATH"
}
function add_dirs() {
  # Verificar si el archivo de configuración existe
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$SETTINGS_FILE" ]; then
    echo "ERROR: El archivo de configuración '$SETTINGS_FILE' no se puede encontrar."
    exit 1
  fi
  echo "El archivo de configuración '$SETTINGS_FILE' existe."

  # Agregar importación de os al inicio del archivo
  echo "Agregando importación 'import os' al archivo de configuración..."
  sudo sed -i '1s/^/import os\n/' "$SETTINGS_FILE"
  echo "Importación agregada correctamente."

  # Modificar el archivo de configuración
  echo "Agregando directorio al archivo de configuración..."
  sudo sed -i "s|'DIRS': \[\]|'DIRS': [os.path.join(BASE_DIR,'$REACT_APP/build')]|g" "$SETTINGS_FILE"
  echo "Directorio agregado correctamente."

  echo "¡Configuración completada!"
}

function edit_urls() {
  # Verificar si el archivo de configuración existe
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$URLS_FILE" ]; then
    echo "ERROR: El archivo de configuración '$URLS_FILE' no se puede encontrar."
    exit 1
  fi
  echo "El archivo de configuración '$URLS_FILE' existe."

  # Agregar importación de os al inicio del archivo
  echo "Agregando importación 'from django.views.generic import TemplateView' al archivo de configuración..."
  sudo sed -i '1s/^/from django.views.generic import TemplateView\n/' "$URLS_FILE"
  echo "Importación agregada correctamente."

  # Escribir la nueva ruta en urlpatterns
  echo "Agregando ruta al archivo de configuración..."
  sudo sed -i "/urlpatterns = \[/a \    path('', TemplateView.as_view(template_name='index.html'))," "$URLS_FILE"
  echo "Ruta agregada correctamente."

  echo "¡Configuración completada!"
}
function add_staticfiles_dirs() {
  # Verificar si el archivo de configuración existe
  echo "Verificando si el archivo de configuración existe..."
  if [ ! -f "$SETTINGS_FILE" ]; then
    echo "ERROR: El archivo de configuración '$SETTINGS_FILE' no se puede encontrar en la ruta '$CONFIG_PATH'."
    exit 1
  fi
  echo "El archivo de configuración '$SETTINGS_FILE' existe."

  # Agregar el vector STATICFILES_DIRS al final del archivo de configuración
  echo "Agregando vector 'STATICFILES_DIRS' al archivo de configuración..."
  echo "STATICFILES_DIRS=[os.path.join(BASE_DIR, '$REACT_APP/build/static')]" >> "$SETTINGS_FILE"
  echo "Vector agregado correctamente."

  echo "¡Configuración completada!"
}



# función principal
function install_node() {
  echo "*******NODE.JS INSTALL******"
  get_latest_node_version
  download_latest_node_version $version
  verify_node_integrity
  extract_node_archive
  move_node_files
  create_symlinks
  find_bashrc
  add_to_bashrc
  make_dirs
  create_react_app
  add_dirs
  edit_urls
  add_staticfiles_dirs
  echo "******ALL DONE******"
}
# Llamada a la función principal
install_node
