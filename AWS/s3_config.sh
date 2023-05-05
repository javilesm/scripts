#!/bin/bash
# s3_config.sh
# Variables
S3_CREDENTIALS_FILE=".keysS3"
S3_PASSWD_FILE=$(find $HOME -type f -name "${S3_CREDENTIALS_FILE}")
# Vectores
MOUNTING_POINTS=(
    "s3-cloudpress"
    "ec2-safety-vault"
)
S3_BUCKETS=(
    "s3-cloudpress"
    "ec2-safety-vault"
)
# Función para comprobar la existencia del archivo .s3
function check_s3_passwd_file() {
    local s3_passwd_file=$(find $HOME -type f -name ".s3")
    if [[ -z "$s3_passwd_file" ]]; then
        echo "ERROR: No se encontró el archivo .s3"
        exit 1
    fi
    S3_PASSWD_FILE="$s3_passwd_file"
}
# Función que crea los directorios para los puntos de montaje y les da permisos
function create_mounting_points() {
    # crear los directorios para los puntos de montaje y les da permisos
    echo "Creando los directorios para los puntos de montaje..."
    for ((i=0; i<${#MOUNTING_POINTS[@]}; i++)); do
        if [ -d "/var/${MOUNTING_POINTS[$i]}" ]; then
            # si el directorio ya existe, cambiar permisos
            if sudo chmod 777 /var/${MOUNTING_POINTS[$i]}; then
                echo "Punto de montaje '${MOUNTING_POINTS[$i]}' ya existe, se han cambiado los permisos con éxito"
            else
                echo "ERROR: Hubo un error al cambiar los permisos del punto de montaje '${MOUNTING_POINTS[$i]}'"
                exit 1
            fi
        else
            # si el directorio no existe, crearlo y cambiar permisos
            if sudo mkdir -p /var/${MOUNTING_POINTS[$i]} && sudo chmod 777 /var/${MOUNTING_POINTS[$i]}; then
                echo "Punto de montaje '${MOUNTING_POINTS[$i]}' creado con éxito"
            else
                echo "ERROR: Hubo un error al crear el punto de montaje '${MOUNTING_POINTS[$i]}'"
                exit 1
            fi
        fi
    done
}
# Función que monta los buckets de S3 en los puntos de montaje
function mount_s3_buckets() {
    # montar los buckets de S3 en los puntos de montaje
    echo "Montando los buckets de S3 en los puntos de montaje con las credenciales '$S3_PASSWD_FILE'..."
    for ((i=0; i<${#MOUNTING_POINTS[@]}; i++)); do
        if mountpoint -q "/var/${MOUNTING_POINTS[$i]}"; then
            echo "ERROR: El punto de montaje '/var/${MOUNTING_POINTS[$i]}' ya está siendo utilizado"
            exit 1
        fi
        if sudo s3fs ${S3_BUCKETS[$i]} /var/${MOUNTING_POINTS[$i]} -o passwd_file=$S3_PASSWD_FILE; then
            echo "Bucket '${S3_BUCKETS[$i]}' montado en '${MOUNTING_POINTS[$i]}' con éxito"
        else
            echo "ERROR: Hubo un error al montar el bucket '${S3_BUCKETS[$i]}' en '${MOUNTING_POINTS[$i]}'"
            exit 1
        fi
    done
}
# Función que configura el montaje automático del bucket de S3 al reiniciar el servidor
function configure_automatic_mount() {
    for ((i=0; i<${#MOUNTING_POINTS[@]}; i++)); do
        if ! grep -q "${MOUNTING_POINTS[$i]}" /etc/fstab; then
            echo "s3fs#${S3_BUCKETS[$i]} /var/${MOUNTING_POINTS[$i]}    fuse    _netdev,nonempty,allow_other,use_cache=/tmp,uid=1000,gid=1000    0    2" | sudo tee -a /etc/fstab > /dev/null
            echo "Configurado montaje automático de '${S3_BUCKETS[$i]}' en '${MOUNTING_POINTS[$i]}'"
        else
            echo "Montaje automático de '${S3_BUCKETS[$i]}' en '${MOUNTING_POINTS[$i]}' ya configurado"
        fi
    done
}
# Función que monta automáticamente la partición sin reiniciar
function mount_automatically() {
    if sudo mount -a; then
        echo "Particiones montadas automáticamente con éxito"
    else
        echo "ERROR: Hubo un error al montar las particiones automáticamente"
        exit 1
    fi
}
# Función que verifica que los buckets de S3 se hayan montado correctamente
function verify_mount() {
    local mounted_points=0
    for point in "${MOUNTING_POINT[@]}"; do
        if df -h | grep -q "/var/$point"; then
            ((mounted_points++))
        fi
    done
    if [[ $mounted_points -eq ${#MOUNTING_POINT[@]} && $(df -h | grep -c '/var/ec2-safety-vault') -eq 1 ]]; then
        echo "Los buckets de S3 se han montado correctamente"
        df -h
    else
        echo "ERROR: Hubo un error al verificar el montaje de los buckets de S3"
        exit 1
    fi
}
# Función principal
function s3_config() {
    check_s3_passwd_file
    create_mounting_points
    mount_s3_buckets
    configure_automatic_mount
    mount_automatically
    verify_mount
}
# Llamar a la función principal
s3_config
