#!/bin/bash
# create_role.sh
# Variables
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)" # Obtener el directorio actual
POLICIES_DIR="$CURRENT_DIR/Policies"
POLICY_NAME="samava-s3bucket"
ROLE_POLICY_PATH="$POLICIES_DIR/$POLICY_NAME"
ROLE_NAME="samava_EC2_AmazonS3FullAccess"
INSTANCE_PROFILE_NAME=""
# Función para crear un rol en AWS
function create_role() {
  echo "Creando un rol en AWS..."
  if aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file://trust-policy.json; then
    echo "El rol '$ROLE_NAME' ha sido creado."
  else
    echo "Error al crear el rol."
    exit 1
  fi
}

# Función para adjuntar una política al rol creado
function put_role_policy() {
  echo "Adjuntando una política al rol creado..."
  if aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY_NAME" --policy-document file://"$ROLE_POLICY_PATH"; then
    echo "La política '$POLICY_NAME' ha sido adjuntada al rol '$ROLE_NAME'."
  else
    echo "Error al adjuntar la política al rol."
    exit 1
  fi
}
# Función para adjuntar el rol a un grupo de usuarios
function attach_role_to_users() {
  echo "Adjuntando el rol '$ROLE_NAME' al grupo de usuarios..."
  if aws iam add-role-to-instance-profile --role-name "$ROLE_NAME" --instance-profile-name "$INSTANCE_PROFILE_NAME"; then
    echo "El rol '$ROLE_NAME' ha sido adjuntado al grupo de usuarios."
  else
    echo "Error al adjuntar el rol al grupo de usuarios."
    exit 1
  fi
}

# Función principal
function create_role() {
  echo "**********AWS CREATE ROLE***********"
  create_role
  put_role_policy
  attach_role_to_users
  echo "**************ALL DONE***************"
}
# Llamar a la función principal
create_role
