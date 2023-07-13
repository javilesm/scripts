#!/bin/bash
# create_s3_buckets.sh

# Variables
BUCKETS_FILE="s3-buckets.txt"
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)" # Obtener el directorio actual
# Función para crear un bucket S3
function create_s3_bucket() {
  local bucket_name="$1"
  local region="$2"
  echo "Creando el bucket S3 '$bucket_name' en la región '$region'..."
  if aws s3api create-bucket --bucket "$bucket_name" --region "$region" --create-bucket-configuration LocationConstraint="$region"; then
    echo "El bucket S3 '$bucket_name' ha sido creado en la región '$region'."
  else
    echo "Error al crear el bucket S3 '$bucket_name'."
    exit 1
  fi
}

# Función principal
function main() {
  echo "**********AWS CREATE S3 BUCKETS***********"
  while IFS= read -r line; do
    read -r bucket_name region <<< "$line"
    create_s3_bucket "$bucket_name" "$region"
  done < "$BUCKETS_FILE"
  echo "**************ALL DONE***************"
}

# Llamar a la función principal
main
