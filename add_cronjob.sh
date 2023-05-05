#!/bin/bash
# add_cronjob.sh
# Función para agregar una tarea de cronjob al archivo temporal
function add_cronjob {
  if [[ $# -ne 2 ]]; then
    echo "Error: add_cronjob requiere dos argumentos"
    exit 1
  fi
  echo "$1 $2" >> /tmp/cronjob
}

# Configurar el cronjob para que ejecute clamscan todos los días a la 1 a.m. y escanee el directorio /home
add_cronjob "0 1 * * *" "/usr/bin/clamscan -r /home"

# Configurar el cronjob para que ejecute un comando cada hora
add_cronjob "0 * * * *" "comando1"

# Configurar el cronjob para que ejecute un comando cada 30 minutos
add_cronjob "*/30 * * * *" "comando2"

# Agregar el archivo de cronjob a la configuración de crontab
if crontab /tmp/cronjob; then
  echo "¡La configuración de crontab ha finalizado!"
else
  echo "Error: no se pudo agregar la configuración de cronjob"
  exit 1
fi

# Eliminar el archivo temporal de cronjob
if rm /tmp/cronjob; then
  echo "¡El archivo temporal de cronjob ha sido eliminado!"
else
  echo "Error: no se pudo eliminar el archivo temporal de cronjob"
  exit 1
fi
