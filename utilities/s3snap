#!/bin/bash
# s3snap.sh
# Llamada a reconfigurar_aws_cli.sh
echo "Ejecutando aws_setup desde s3backup..."
SCRIPT_PATH="/home/ubuntu/scripts/aws_setup"
bash $SCRIPT_PATH

# Directorio local a respaldar
SOURCE_DIR="/home/ubuntu/scripts/"

# Bucket de Amazon S3 para el respaldo
DESTINATION_DIR="s3://ec2-safety-vault/vol-07fa8e9b466bbe2eb"

# Directorio de respaldo comprimido
BACKUP_DIR="/home/ubuntu/backups/"

# Nombre del archivo de respaldo
BACKUP_FILE="respaldo_$SOURCE_DIR_$(date +%Y%m%d_%H%M%S).tar.gz"

# Comando para limpiar respaldos viejos
echo "Limpiando..."
rm -R /home/ubuntu/backups/*
sleep 5

# Comando para comprimir el directorio local en un archivo tar.gz
echo "Comprimiendo..."
tar czf "$BACKUP_DIR/$BACKUP_FILE" -C "$SOURCE_DIR" .

# Comando para esperar hasta que se actulice 
sleep 5

# Comando para copiar el archivo de respaldo a S3 utilizando awscli
echo "Sincronizando con S3..."
aws s3 sync $BACKUP_DIR $DESTINATION_DIR
echo "Copia de seguridad realizada con exito..."

# Agregar tarea de cron para la copia de seguridad diaria
CRON_LINE="0 0 * * * /home/ubuntu/scripts/s3snap"
(crontab -l ; echo "$CRON_LINE") | sort - | uniq - | crontab -
echo "Crontab actualizado con exito..."
