#!/bin/bash
# cerbot_config.sh
# Variables
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
MAIL_ADDRESS="creativeering@outlook.com"
DOMAINS_LIST="$PARENT_DIR/Postfix/domains.txt"
# Detener Nginx si está en ejecución
function stop_nginx() {
    echo "Deteniendo Nginx si está en ejecución..."
    if systemctl is-active --quiet nginx; then
        sudo systemctl stop nginx
        echo "Nginx detenido"
    else
        echo "Nginx no está en ejecución"
    fi
}
# Leear la lista de dominios
function read_domains_list() {
    echo "Leyendo la lista de dominios: '$DOMAINS_LIST'..."
    while IFS= read -r hostname; do
        echo "Hostname: $hostname"
        generate_ssl_certificate "$hostname"
        #dry_run "$hostname"
    done < <(grep -v '^$' "$DOMAINS_LIST")
    echo "Todos los dominios han sido procesados."
}
# Generar el certificado SSL con Certbot
function generate_ssl_certificate() {
    local domain="$1"
    echo "Generando el certificado SSL para el dominio '$domain' con Certbot..."
    sudo certbot --nginx --redirect -d "$domain" -m "$MAIL_ADDRESS" --agree-tos --non-interactive
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "Certificado SSL generado exitosamente para el dominio '$domain'"
    else
        echo "Error al generar el certificado SSL para el dominio '$domain' con Certbot (código de salida: $exit_code)"
        exit 1
    fi
}
function dry_run() {
    echo "Ejecutando prueba de renovación de certificado SSL para el dominio '$domain'..."
    sudo certbot renew --dry-run
    exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "Prueba de renovación exitosa para el dominio '$domain'"
    else
        echo "Error en la prueba de renovación del certificado SSL para el dominio '$domain' (código de salida: $exit_code)"
        exit 1
    fi
}
# Reiniciar Nginx
function start_nginx() {
    echo "Iniciando Nginx..."
    sudo killall nginx
    sudo service nginx start
    echo "Nginx iniciado"
}
# Función principal
function cerbot_config() {
    echo "**********CERBOT CONFIG**********"
    stop_nginx
    read_domains_list
    start_nginx
    echo "**********ALL DONE**********"
}
# Llamar a la función principal
cerbot_config
