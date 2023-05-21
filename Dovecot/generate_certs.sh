#!/bin/bash
# generate_certs.sh
# Variables
DOMAIN="avilesworks.com"
CERTS_PATH="/etc/dovecot/certs"
KEY_FILE="samava"
CSR_FILE="samava"
CRT_FILE="samava"
PEM_FILE="samava"
KEY_PATH="$CERTS_PATH/$KEY_FILE.key"
CSR_PATH="$CERTS_PATH/$CSR_FILE.csr"
CRT_PATH="$CERTS_PATH/$CRT_FILE.crt"
PEM_PATH="$CERTS_PATH/$PEM_FILE.pem"

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
    if [ -e "$KEY_PATH" ]; then
        echo "La llave '$KEY_PATH' ya existe."
        return 0
    fi
    # generar la llave privada y el requerimiento
    echo "Generando la llave privada y el requerimiento..."
    if sudo openssl req -config /usr/lib/ssl/openssl.cnf -new -nodes -keyout "$KEY_PATH" -out "$CSR_PATH" -subj "/CN=${DOMAIN}"; then
        echo "Se ha creado la llave: $KEY_PATH para el dominio: ${DOMAIN}"
        echo "Se ha creado el requerimiento: $CSR_PATH para el dominio: ${DOMAIN}"
    else
        echo "ERROR:Error al generar la llave '$KEY_PATH' y el requerimiento '$CSR_PATH'."
        return 1
    fi
}
# Función para generar el certificado
function generate_certificate() {
    if [ -e "$CRT_PATH" ]; then
        echo "El certificado '$CRT_PATH' ya existe."
        return 0
    fi
    # generar el certificado
    echo "Generando el certificado..."
    if sudo openssl x509 -signkey "$KEY_PATH" -in "$CSR_PATH" -req -days 3650 -out "$CRT_PATH"; then
        echo "Se ha creado el certificado: $CRT_PATH para el dominio: ${DOMAIN}"
    else
        echo "ERROR:Error al generar el certificado '$CRT_PATH'."
        return 1
    fi
}
# Función para convertir el certificado
function convert_certificate() {
    if [ -e "$PEM_PATH" ]; then
        echo "El certificado '$PEM_PATH' ya existe."
        return 0
    fi
    # convertir el certificado
    echo "Convirtiendo el certificado..."
    if sudo openssl x509 -in "$CRT_PATH" -out "$PEM_PATH" -outform PEM; then
        echo "Se ha convertido el certificado '$CRT_PATH' en: '$PEM_PATH'"
    else
        echo "ERROR:Error al convertir el certificado '$CRT_PATH'."
        return 1
    fi
}
# Función para cambiar permisos
function change_mod() {
    # cambiar permisos
    echo "Cambiando permisos del archivo '$KEY_PATH'..."
    sudo chmod 400 "$KEY_PATH"
    echo "Cambiando permisos del archivo '$CRT_PATH'..."
    sudo chmod 444 "$CRT_PATH"
    echo "Cambiando permisos del archivo '$PEM_PATH'..."
    sudo chmod 444 "$PEM_PATH"
    echo "Los permisos fueron cambiados."
}
# Función principal
function generate_certs() {
    echo "******************GENERATE CERTS******************"
    create_cert_directory
    generate_key
    generate_certificate
    convert_certificate
    change_mod
    echo "******************ALL DONE******************"
}
# Llama a la función princial
generate_certs
