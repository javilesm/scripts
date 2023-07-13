#!/bin/bash
# create_user_groups.sh

# Variables
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)" # Obtener el directorio actual
GROUPS_FILE="$CURRENT_DIR/my-user-group.txt"

# Función para crear un grupo de usuarios
function create_user_group() {
  local group_name="$1"
  echo "Creando el grupo de usuarios '$group_name'..."
  if aws iam create-group --group-name "$group_name"; then
    echo "El grupo de usuarios '$group_name' ha sido creado."
  else
    echo "Error al crear el grupo de usuarios '$group_name'."
    exit 1
  fi
}

# Función principal
function create_user_groups() {
  echo "**********AWS CREATE USER GROUP***********"
  while IFS= read -r group; do
    create_user_group "$group"
  done < "$GROUPS_FILE"
  echo "**************ALL DONE***************"
}

# Llamar a la función principal
create_user_groups
