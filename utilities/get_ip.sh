#!/bin/bash
# get_ip.sh
# variables
# Función para obtener la dirección IP de la interfaz en uso
function get_ip_address() {
    ip_address=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1)
    if [ -z "$ip_address" ]; then
        echo "ERROR: No se pudo obtener la dirección IP" >&2
        exit 1
    fi
    echo "La dirección IP de la máquina es: $ip_address"
    # exportar la dirección IP
    echo "Exportando la dirección IP..."
    export ip_address
    echo "Dirección IP exportada exitosamente." 
}
# Función para comprobar que la dirección IP haya sido exportada exitosamente.
function check() {
    # comprobar que la dirección IP haya sido exportada exitosamente.
    echo "Comprobando que la dirección IP haya sido exportada exitosamente..."
    if [ -z "$ip_address" ]; then
        echo "ERROR: La dirección IP no ha sido exportada exitosamente." >&2
        exit 1
    else
        echo "La dirección IP ha sido exportada exitosamente: $ip_address"
    fi
}
# Función principal
function get_ip() {
    get_ip_address
    check
}
get_ip
