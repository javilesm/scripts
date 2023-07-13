#!/bin/bash
# create_s3_buckets.sh
# En este script, se utiliza un archivo llamado "s3-buckets.txt" para especificar los nombres de los buckets S3 y las regiones en las que se crearán, separados por un espacio en cada línea.
# La función create_s3_bucket toma dos parámetros: bucket_name y region, que representan el nombre del bucket S3 y la región en la que se creará. Dentro de la función, se utiliza el comando create-bucket de AWS CLI para crear el bucket S3, especificando el nombre del bucket, la región y la configuración de creación del bucket.
# En la función principal main, se lee el archivo s3-buckets.txt línea por línea utilizando un bucle while. Luego, se extraen el nombre del bucket y la región de cada línea y se llama a la función create_s3_bucket con esos valores.
# Asegúrate de tener el archivo s3-buckets.txt en el mismo directorio que el script y de que cada línea contenga el nombre del bucket y la región separados por un espacio.
# Variables
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)" # Obtener el directorio actual
BUCKETS_FILE="$CURRENT_DIR/s3-buckets.txt"
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
