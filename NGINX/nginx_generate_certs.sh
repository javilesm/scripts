#!/bin/bash
# nginx_generate_certs.sh
# Variables
DOMAIN="avilesworks.com"
NAME="server-cert"
CERTS_PATH="/etc/nginx/ssl"
CA_KEY="ca-key.pem"
CA_KEY_PATH="$CERTS_PATH/$CA_KEY"
CA_CERT="ca.pem"
CA_CERT_PATH="$CERTS_PATH/$CA_CERT"
KEY_FILE="$NAME.key"
CSR_FILE="$NAME.csr"
CRT_FILE="$NAME.crt"
PEM_FILE="$NAME.pem"
KEY_PATH="$CERTS_PATH/$KEY_FILE"
CSR_PATH="$CERTS_PATH/$CSR_FILE"
CRT_PATH="$CERTS_PATH/$CRT_FILE"
PEM_PATH="$CERTS_PATH/$PEM_FILE"
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
    cd "$CERTS_PATH"
}
# Generate RSA
function generate_ca_rsa() {
    if [ -e "$CA_KEY_PATH" ]; then
        echo "La llave '$CA_KEY_PATH' ya existe."
        return 0
    fi

    # Generar la llave privada y certificado autofirmado
    echo "Generando la llave privada..."
    if sudo openssl genrsa -aes256 -out "$CA_KEY_PATH" 4096; then
        echo "Se ha creado la llave: $CA_KEY_PATH."
    else
        echo "ERROR: Error al generar la llave '$CA_KEY_PATH'."
        return 1
    fi
}
function generate_ca_pem() {
    if [ -e "$CA_CERT_PATH" ]; then
        echo "La llave '$CA_CERT_PATH' ya existe."
        return 0
    fi

    # Generar la llave privada y certificado autofirmado
    echo "Generando la llave privada..."
    if sudo openssl req -new -x509 -sha256 -days 3650 -key "$CA_KEY_PATH" -out "$CA_CERT_PATH" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"; then
        echo "Se ha creado la llave: $CA_CERT_PATH."
    else
        echo "ERROR: Error al generar la llave '$CA_CERT_PATH'."
        return 1
    fi
}
# Generate RSA key
function generate_pem_file() {
    if [ -e "$PEM_PATH" ]; then
        echo "La llave '$PEM_PATH' ya existe."
        return 0
    fi

    # Generar la llave privada y certificado autofirmado
    echo "Generando la llave privada..."
    if sudo openssl genrsa -out "$PEM_PATH" 4096; then
        echo "Se ha creado la llave: $PEM_PATH."
    else
        echo "ERROR: Error al generar la llave '$PEM_PATH'."
        return 1
    fi
}
# Función para generar el requerimiento 
function generate_csr_file() {
    if [ -e "$CSR_PATH" ]; then
        echo "El requerimiento '$CSR_PATH' ya existe."
        return 0
    fi
    # Generar el requerimiento  
    echo "Generando el requerimiento  ..."
    if sudo openssl req -new -sha256 -key "$PEM_PATH" -out "$CSR_PATH" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"; then
        echo "Se ha creado el requerimiento: $CSR_PATH."
    else
        echo "ERROR: Error al generar el requerimiento '$CSR_PATH'."
        return 1
    fi
}
function create_extfile() {
    echo "subjectAltName=DNS:*.$DOMAIN,IP:3.220.58.75" >> extfile.cnf
}
# Función para generar la llave privada 
function generate_key() {
    if [ -e "$KEY_PATH" ]; then
        echo "La llave '$KEY_PATH' ya existe."
        return 0
    fi

    # Generar la llave privada y certificado autofirmado
    echo "Generando la llave privada..."
    if sudo openssl x509 -req -sha256 -days 365 -in "$CSR_PATH" -CA "$CA_CERT_PATH" -CAkey "$CA_KEY_PATH" -out cert.pem -extfile extfile.cnf -CAcreateserial; then
        echo "Se ha creado la llave: $KEY_PATH."
    else
        echo "ERROR: Error al generar la llave '$KEY_PATH'."
        return 1
    fi
}
function merge_certs() {
    sudo cat cert.pem > fullchain.pem
    sudo cat "$CA_CERT_PATH" >> .\fullchain.pem
}
# Función principal
function nginx_generate_certs() {
    echo "******************NGINX GENERATE CERTS******************"
    create_cert_directory
    generate_ca_rsa
    generate_ca_pem
    generate_pem_file
    generate_csr_file
    create_extfile
    generate_key
    merge_certs
    echo "******************ALL DONE******************"
}
# Llama a la función princial
nginx_generate_certs
