#!/bin/bash
# nodejs_install.sh
set -e
# Comprueba si Node.js ya está instalado
function node_is_installed() {
  echo "Comprobabdo si Node.js ya esta instalado..."
  if command -v node > /dev/null; then
    return 0
  else
    return 1
  fi
}
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
extract_node_archive() {
  echo "Extrayendo archivos..."
  if ! tar -xvf node.tar.xz; then
    echo "Ocurrió un error al extraer el archivo de Node.js."
    exit 1
  fi
  echo "Archivo extraido."
}
# Función para mover los archivos de Node.js a /usr/local
function move_node_files() {
  echo "Moviendo archivos a /usr/local..."
  if [[ ! -d "/usr/local/" ]]; then
    sudo mkdir -p /usr/local/
  fi
  
  sudo mkdir -p /usr/local/node
  if ! sudo mv node-$version-linux-x64/* /usr/local/node; then
    echo "Ocurrió un error al mover los archivos de Node.js a /usr/local/node."
    exit 1
  fi
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
# función principal
function install_node() {
  echo "*******NODE.JS INSTALL******"
  node_is_installed
  get_latest_node_version
  download_latest_node_version $version
  verify_node_integrity
  extract_node_archive
  move_node_files
  create_symlinks
  find_bashrc
  add_to_bashrc
  echo "******ALL DONE******"
}
# Llamada a la función principal
install_node
