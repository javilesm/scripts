#!/bin/bash
# postgresql_config.sh
# Función para verificar si se ejecuta el script como root
function check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ser ejecutado como root"
        exit 1
    fi
}

# Función para reiniciar el servicio de PostgreSQL
function restart_postgresql_service() {
    echo "Reiniciando el servicio de PostgreSQL..."
    sudo service postgresql restart
}
# Función principal
function postgresql_config() {
    echo "**********POSTGRESQL CONFIG**********"
    check_root
    
    restart_postgresql_service
    echo "**************ALL DONE**************"
}

# Llamar a la función principal
postgresql_config
