#! /bin/bash
# tree_install.sh
# Función para instalar Tree si no está instalado
function tree_install() {
  install_and_restart tree
}
# Función para instalar un paquete y reiniciar los servicios afectados
function install_and_restart() {
  local package="$1"

  # Verificar si el paquete ya está instalado
  if dpkg -s "$package" >/dev/null 2>&1; then
    echo "$package ya está instalado."
    return
  fi

  # Instalar el paquete
  echo "Instalando $package..."
  if sudo apt-get install "$package" -y >/dev/null 2>&1; then
    echo "Instalación de $package completa."
  else
    echo "Error: no se pudo instalar $package."
    return 1
  fi

  # Buscar los servicios que necesitan reiniciarse
  services=$(systemctl list-dependencies --reverse "$package" | grep -oP '^\w+(?=.service)')

  # Reiniciar los servicios que dependen del paquete instalado
  if [[ -n $services ]]; then
    echo "Reiniciando los siguientes servicios: $services"
    if sudo systemctl restart $services >/dev/null 2>&1; then
      echo "Reinicio de servicios completado."
    else
      echo "Error: no se pudieron reiniciar los siguientes servicios: $services."
      return 1
    fi
  else
    echo "No se encontraron servicios que necesiten reiniciarse."
  fi
}

# Llamar a la funcion princial
tree_install
