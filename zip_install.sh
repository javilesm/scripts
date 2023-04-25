#! /bin/bash
# zip_install.sh
# Función para instalar ZIP si no está instalado
function zip_install() {
  if [ $(dpkg-query -W -f='${Status}' zip 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Instalando ZIP..."
    if ! sudo apt-get install zip -yqq; then
      echo "No se pudo instalar ZIP"
      exit 1
    fi
  else
    echo "ZIP ya está instalado."
  fi
}
# Llamar a la funcion princial
zip_install
