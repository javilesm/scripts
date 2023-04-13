#!/bin/bash
# ALGORITMO PARA REALIZAR INSTANTANEAS LOCALES
# Variables
SOURCE_DIR="/*" # Directorio local a respaldar
BACKUP_DIR="/vault/xvda1" # Directorio temporal para archivo comprimido
BACKUP_FILE="snapshot_$(date +%Y%m%d_%H%M%S).tar.gz" # Nombre del archivo de respaldo

# Inicio del programa
inicio=$(date +%s)  # Tomar la hora de inicio del respaldo

# Algoritmo para comprimir el directorio local en un archivo tar.gz
echo "Comprimiendo el directorio local en un archivo tar.gz..."
sudo tar czf "$BACKUP_DIR/$BACKUP_FILE" --one-file-system --exclude='proc' --exclude='tmp' --exclude='var/tmp' --exclude='var/cache' --exclude='var/log' --exclude='data' --exclude='run' --exclude='lost+found' --exclude='mnt' --exclude='vault' -P $SOURCE_DIR

# Calcular el tamaño total del archivo creado con rsync
tamano_total=$(du -sh $BACKUP_DIR/$BACKUP_FILE | awk '{print $1}')  # Obtener el tamaño total en formato legible por humanos
sleep 5 # Esperar 5 segundos

# Calcular el tiempo transcurrido
fin=$(date +%s)  # Tomar la hora de fin del respaldo
tiempo_transcurrido=$((fin - inicio))  # Calcular el tiempo transcurrido en segundos

# Fin
echo "Tiempo transcurrido: $tiempo_transcurrido segundos."
echo "Tamaño total del archivo: $tamano_total."
echo "Copia de seguridad realizada con exito..."
ls $BACKUP_DIR