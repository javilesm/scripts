#!/bin/bash
# nodejs_install.sh
# Función para instalar Node.js
# Comprueba si Node.js ya está instalado
function node_is_installed() {
  if command -v node > /dev/null; then
    return 0
  else
    return 1
  fi
}
# Descarga la última versión de Node.js y devuelve el nombre del archivo
function download_node() {
  local node_version=$(curl -sL https://nodejs.org/dist/latest/SHASUMS256.txt | grep linux-x64.tar.gz | awk '{ print $2 }')

  if [[ -z "$node_version" ]]; then
    echo "Error: no se pudo obtener la última versión de Node.js"
    exit 1
  fi

  curl -sLO "https://nodejs.org/dist/latest/${node_version/linux-x64.tar.gz/node-${node_version:1}}"

  if [[ ! -f "node-${node_version:1}" ]]; then
    echo "Error: no se pudo descargar el archivo de instalación de Node.js"
    exit 1
  fi

  echo "node-${node_version:1}"
}
# Verifica la suma de comprobación de un archivo
function verify_checksum() {
  local file="$1"

  if ! sha256sum --check --ignore-missing "${file}.sha256"; then
    echo "Error: la suma de comprobación de ${file} no coincide, abortando la instalación"
    exit 1
  fi
}
# Extrae un archivo en /usr/local y lo mueve a /usr/local/node
function extract_node() {
  local file="$1"

  if ! tar xzf "$file"; then
    echo "Error: no se pudo extraer el archivo de instalación de Node.js"
    exit 1
  fi

  if ! rm "$file"; then
    echo "Error: no se pudo eliminar el archivo de instalación de Node.js"
    exit 1
  fi

  if ! mv "${file/node-/}" /usr/local/node; then
    echo "Error: no se pudo mover el archivo de instalación de Node.js a /usr/local/node"
    exit 1
  fi
}
# Crea enlaces simbólicos para los binarios node, npm y npx
function create_symlinks() {
  if ! ln -s /usr/local/node/bin/node /usr/local/bin/node; then
    echo "Error: no se pudo crear el enlace simbólico para node"
    exit 1
  fi

  if ! ln -s /usr/local/node/bin/npm /usr/local/bin/npm; then
    echo "Error: no se pudo crear el enlace simbólico para npm"
    exit 1
  fi

  if ! ln -s /usr/local/node/bin/npx /usr/local/bin/npx; then
    echo "Error: no se pudo crear el enlace simbólico para npx"
    exit 1
  fi
}
# función principal
function install_node() {
  echo "*******NODE.JS INSTALL******"
  node_is_installed
  download_node
  verify_checksum
  extract_node
  create_symlinks
  echo "******ALL DONE******"
}
# Llamada a la función principal
install_node
