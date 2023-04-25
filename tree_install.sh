#! /bin/bash
# tree_install.sh
# Función para instalar Tree si no está instalado
function tree_install() {
  if [ $(dpkg-query -W -f='${Status}' tree 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Instalando Tree..."
    if ! sudo apt install tree -yqq; then
      echo "No se pudo instalar Tree"
      exit 1
    fi
  else
    echo "Tree ya está instalado."
  fi
}
# Llamar a la funcion princial
tree_install
