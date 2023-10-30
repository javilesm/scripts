#!/bin/bash
# add_cronjob.sh
CRONTAB_PATH="/etc/crontab"

# Definir vector de tareas
tareas=(
    "0 1 * * * /usr/bin/clamscan -r /home"
    "0 0 * * * s3snap"
    "0 0 * * * ec2snap"
    "0 0 * * * mysql_backup"
    "0 0 * * * postgresql_backup"
    "*/5 * * * * /bin/bash /home/ubuntu/scripts/NGINX/execute_process_workorders.sh"
)

# Función para verificar si el usuario tiene privilegios sudo
function check_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Este script requiere privilegios de superusuario. Ejecútalo con sudo."
        exit 1
    fi
}

# Función para verificar si el archivo crontab existe
function verify_crontab() {
    if [ ! -f "$CRONTAB_PATH" ]; then
        echo "ERROR: El archivo crontab no existe"
        exit 1
    fi
}

# Función para agregar tareas a crontab
function add_task() {
    for tarea in "${tareas[@]}"; do
        if grep -q "$tarea" "$CRONTAB_PATH"; then
            echo "La tarea ya existe en crontab: $tarea"
        else
            echo "Agregando tarea a crontab: $tarea"
            echo "$tarea" >> "$CRONTAB_PATH"
        fi
    done
}

# Función principal
function add_cronjob() {
    check_sudo
    verify_crontab
    add_task
}

# Llamar a la función principal
add_cronjob
