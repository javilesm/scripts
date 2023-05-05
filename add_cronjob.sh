#!/bin/bash
# add_cronjob.sh
# Definir vector de tareas
tareas=(
    "0 1 * * * /usr/bin/clamscan -r /home"
    "0 0 * * * s3snap"
    "0 0 * * * ec2snap"
    "0 0 * * * mysql_backup"
    "0 0 * * * postgresql_backup"
)
# Función para verificar si el archivo crontab existe
function verify_crontab() {
  # Verificar si el archivo crontab existe
  if [ ! -f "/etc/crontab" ]; then
      echo "ERROR: El archivo crontab no existe"
      exit 1
  fi
}
# Función para agregar tareas a crontab
function add_task() {
    # Verificar si las tareas ya existen en crontab
    for tarea in "${tareas[@]}"; do
        if grep -q "$tarea" "/etc/crontab"; then
            echo "La tarea ya existe en crontab: $tarea"
        else
            echo "Agregando tarea a crontab: $tarea"
            echo "$tarea" >> /etc/crontab
        fi
    done
}
# Funcion principal
function add_cronjob() {
  verify_crontab
  add_task
}
# Llamar a la funcion principal
add_cronjob
