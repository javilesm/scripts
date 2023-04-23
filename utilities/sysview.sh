#!/bin/bash
# sysview.sh
# Obtener información de uso de CPU
cpu_info=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
cpu_usage="${cpu_info}%"

# Obtener información de uso de memoria
mem_info=$(free -m | grep "Mem" | awk '{print $3 "/" $2 " MB"}')
mem_usage="${mem_info}"

# Obtener información de uso de espacio en disco
disk_info=$(df -h / | grep -Eo '[0-9]+%')
disk_usage="${disk_info}"

# Imprimir información de monitoreo
echo "Uso de CPU: ${cpu_usage}"
echo "Uso de memoria: ${mem_usage}"
echo "Uso de espacio en disco: ${disk_usage}"
