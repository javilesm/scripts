#! /bin/bash

# Detener todos los procesos
echo "Script para detencion segura de procesos..."
sleep 5

# Obtener el ID de usuario actual
echo "Obteniendo el ID del usuario actual..."
USER_ID=$(id -u)
sleep 5

# Obtener una lista de todos los procesos iniciados por el usuario actual
echo "Obteniendo una lista de todos los procesos iniciados por: $USER_ID"
PROCESS_LIST=$(ps -u $USER_ID -o pid=)
echo $PROCESS_LIST 
sleep 5

# Iterar sobre los IDs de proceso y detenerlos de manera segura
echo "Iterarando sobre los IDs de proceso y deteniendo de manera segura..."
for PID in $PROCESS_LIST; do
    kill -TERM $PID
done
sleep 5

# Confirmar que los procesos se han detenido
echo "Todos los procesos iniciados por el usuario $USER se han detenido de manera segura."

sleep 15

# Enviar una señal de apagado al sistema
echo "Enviando la señal de apagado al sistema..."
shutdown -h now