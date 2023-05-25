#! /bin/bash
# packages_install.sh
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual

# Definimos las listas
lista_paquetes=(
  "packages1.txt" 
  "packages2.txt" 
  "packages3.txt"
)

# Exportar la variable DEBIAN_FRONTEND para evitar problemas con debconf
export DEBIAN_FRONTEND=noninteractive

function packages_install() {
  # Iteramos sobre la lista de paquetes
  for ((i = 0; i < ${#lista_paquetes[@]}; i++))
  do
    # Obtenemos el paquet y la acción correspondiente
    paquet="${lista_paquetes[$i]}"
    PACKAGES_PATH="$CURRENT_DIR/$paquet"
    read_packages_file
  done
}
# Función para leer la lista de paquetes e intentar instalar el paquete
function read_packages_file() {
    # leer la lista de dominios
    echo "Leyendo la lista de dominios: '$PACKAGES_PATH'..."
    while read -r package_item; do
      # Imprimimos el mensaje correspondiente al paquet
      echo "Intentando instalar el paquete '$package_item' de la lista '$PACKAGES_PATH'."
      # Intentar instalar el paquete
      install_and_restart $package_item
    done < <(grep -v '^$' "$PACKAGES_PATH")
    echo "Todos los paquetes de la lista '$PACKAGES_PATH' han sido leidos."
}
# Función para instalar un paquete y reiniciar los servicios afectados
function install_and_restart() {
  local package="$1"
  # Verificar si el paquete ya está instalado
  echo "Verificando si el paquete '$package' ya está instalado..."
  if dpkg -s "$package" >/dev/null 2>&1; then
    echo "El paquete '$package' ya está instalado."
    return 0
  fi

  # Instalar el paquete
  echo "Instalando $package..."
  if ! sudo apt-get install "$package" -y; then
    echo "Error: no se pudo instalar el paquete '$package'."
    return 1
  fi
  
   # Verificar si el paquete se instaló correctamente
   echo "Verificando si el paquete se instaló correctamente..."
  if [ $? -eq 0 ]; then
    echo "$package se ha instalado correctamente."
  else
    echo "Error al instalar $package."
    return 1
  fi
  
  # Buscar los servicios que necesitan reiniciarse
    echo "Buscando los servicios que necesitan reiniciarse..."
    services=$(systemctl list-dependencies --reverse --quiet "$package" | grep -oP '^\w+(?=.service)')

    # Reiniciar los servicios que dependen del paquete instalado
    echo "Reiniciando los servicios que dependen del paquete instalado..."
    if [[ -n $services ]]; then
      echo "Reiniciando los siguientes servicios: $services"
      if ! sudo systemctl restart $services; then
        echo "Error: no se pudieron reiniciar los servicios después de instalar el paquete '$package'."
        return 1
      fi
    else
      echo "No se encontraron servicios que necesiten reiniciarse después de instalar el paquete '$package'."
    fi
  echo "El paquete '$package' se instaló correctamente."
  return 0
  sleep 5
}
# Función principal
packages_install
