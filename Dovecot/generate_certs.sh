#!/bin/bash
# generate_certs.sh
# Variables
DOMAIN="avilesworks"
CERTS_PATH="/etc/dovecot/certs"
KEY_FILE="samava"
CSR_FILE="samava"
CRT_FILE="samava"
KEY_PATH="$CERTS_PATH/$KEY_FILE"
CSR_PATH="$CERTS_PATH/$CSR_FILE"
CRT_PATH="$CERTS_PATH/$CRT_FILE"

# Función para crear el directorio para almacenar los certificados
function create_cert_directory() {
    # Verificar si el directorio ya existe
    if [ -d "$CERTS_PATH" ]; then
        echo "El directorio '$CERTS_PATH' ya existe."
        return 0
    fi
    # Crear el directorio para almacenar los certificados
    echo "Creando el directorio para almacenar los certificados '$CERTS_PATH'..."
    if sudo mkdir -p "$CERTS_PATH"; then
        echo "El directorio '$CERTS_PATH' fue creado exitosamente."
    else
        echo "ERROR: Error al crear el directorio '$CERTS_PATH'. Verifica los permisos de superusuario."
        return 1
    fi
}
# Función para generar la llave privada y el requerimiento
function generate_key() {
    if [ -e "$KEY_PATH.key" ]; then
        echo "La llave '$KEY_PATH.key' ya existe."
        return 0
    fi
    # generar la llave privada y el requerimiento
    echo "Generando la llave privada y el requerimiento..."
    if sudo openssl req -config /usr/lib/ssl/openssl.cnf -new -nodes -keyout "$KEY_PATH.key" -out "$CSR_PATH.csr" -subj "/CN=${DOMAIN}"; then
        echo "Se ha creado la llave: $KEY_PATH.key para el dominio: ${DOMAIN}"
        echo "Se ha creado el requerimiento: $CSR_PATH.csr para el dominio: ${DOMAIN}"
    else
        echo "ERROR:Error al generar la llave y el requerimiento."
        return 1
    fi
}
# Función para generar el certificado
function generate_certificate() {
    if [ -e "$CRT_PATH.crt" ]; then
        echo "El certificado '$CRT_PATH.crt' ya existe."
        return 0
    fi
    # generar el certificado
    echo "Generando el certificado..."
    if sudo openssl x509 -signkey "$KEY_PATH.key" -in "$CSR_PATH.csr" -req -days 3650 -out "$CRT_PATH.crt"; then
        echo "Se ha creado el certificado: $CRT_PATH.crt para el dominio: ${DOMAIN}"
    else
        echo "ERROR:Error al generar el certificado."
        return 1
    fi
}
# Función principal
function generate_certs() {
    echo "******************GENERATE CERTS******************"
    create_cert_directory
    generate_key
    generate_certificate
    echo "******************ALL DONE******************"
}
# Llama a la función princial
generate_certs
