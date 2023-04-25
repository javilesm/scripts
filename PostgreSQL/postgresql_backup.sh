#!/bin/bash
# postgresql_backup.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DBS_FILE="postgresql_db.csv"
DBS_PATH="$SCRIPT_DIR/$DBS_FILE"
BACKUP_DIR="$SCRIPT_DIR/backups"
BACKUP_FILE="$(date +'%Y-%m-%d-%H-%M-%S').sql"
USER="postgres"
# Función para verificar si se ejecuta el script como root
function check_root() {
    echo "Verificando si se ejecuta el script como root"
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ser ejecutado como root"
        exit 1
    fi
}
# Función para verificar la existencia del archivo de bases de datos
function check_dbs_file() {
    echo "Verificando la existencia del archivo de bases de datos"
    if [ ! -f "$DBS_PATH" ]; then
        echo "No se ha encontrado el archivo $DBS_PATH."
        exit 1
    fi
}
# Función para verificar la existencia del directorio de copias de seguridad
function check_backup_dir() {
    echo "Verificando la existencia del directorio de copias de seguridad"
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "El directorio de copias de seguridad $BACKUP_DIR no existe. Se creará."
        mkdir -p "$BACKUP_DIR"
    fi
}
# Función para realizar la copia de seguridad de una base de datos
function backup_db() {
    echo "Realizando la copia de seguridad de una base de datos"
    local db=$1
    local backup_path="$BACKUP_DIR/$db/$BACKUP_FILE"
    echo "Creando copia de seguridad de la base de datos $db en $backup_path..."
    sudo -u postgres pg_dump --create --format=plain --file="$backup_path" "$db"
}
# Función principal
function postgresql_backup() {
    echo "**********POSTGRESQL BACKUP**********"
    check_root
    check_dbs_file
    check_backup_dir
    while IFS=',' read -r dbname owner encoding; do
        backup_db "$dbname"
    done < "$DBS_PATH"
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
postgresql_backup
