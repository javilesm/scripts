#!/bin/bash
# generate_kms_key.sh

# Variables
KEY_ALIAS="alias/samava"
ROLE_NAME="samava_EC2_AmazonS3FullAccess"

# Función para generar una clave simétrica en KMS
function generate_kms_key() {
  echo "Generando una clave simétrica en KMS con el alias '$KEY_ALIAS'..."
  local key_id=$(aws kms create-key --description "Clave simétrica para encriptación y decriptación" --origin AWS_KMS --multi-region | jq -r '.KeyMetadata.KeyId')
  
  if aws kms create-alias --alias-name "$KEY_ALIAS" --target-key-id "$key_id" > /dev/null; then
    echo "La clave simétrica con el alias '$KEY_ALIAS' ha sido generada en KMS."
    echo "ID de la clave: $key_id"
    echo "Asignando la clave al rol '$ROLE_NAME'..."
    aws kms create-grant --key-id "$key_id" --grantee-principal "$ROLE_NAME" --operations Encrypt Decrypt
    echo "La clave ha sido asignada al rol '$ROLE_NAME'."
  else
    echo "Error al generar la clave simétrica en KMS."
    exit 1
  fi
}

# Función principal
function generate_kms_key() {
  echo "**********AWS GENERATE KMS KEY***********"
  generate_kms_key
  echo "**************ALL DONE***************"
}

# Llamar a la función principal
generate_kms_key
