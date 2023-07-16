#!/bin/bash
# create_domains.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
DOMAINS_FILE="domains.csv"
DOMAINS_PATH="$CURRENT_DIR/$DOMAINS_FILE"
function read_domains() {
    echo "Leyendo la lista de dominios: '$DOMAINS_PATH'..."
    while IFS="," read -r domain owner city state phone; do
      echo "Dominio: $domain"
      echo "Propietario: $owner"
      echo "Ciudad: $city"
      echo "Estado: $state"
      echo "Tel: $phone"
      echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    done < <(grep -v '^$' "$DOMAINS_PATH")
    echo "Todos los dominios han sido leidos."
}
# Función principal
function create_domains() {
  echo "***************CREATE DOMAINS***************"
  read_domains
  echo "***************ALL DONE***************"
}
# Llamar a la función principal
create_domains
