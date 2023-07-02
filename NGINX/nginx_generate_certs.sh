#!/bin/bash
# nginx_generate_certs.sh
# Variables
DOMAIN="avilesworks.com"
NAME="server-cert"
CERTS_PATH="/etc/nginx/ssl"
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
}
# Función para generar la llave privada 
function generate_key() {
    if [ -e "$KEY_PATH" ]; then
        echo "La llave '$KEY_PATH' ya existe."
        return 0
    fi

    # Generar la llave privada y certificado autofirmado
    echo "Generando la llave privada..."
    if sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$KEY_PATH" -out "$CRT_PATH" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"; then
        echo "Se ha creado la llave: $KEY_PATH."
    else
        echo "ERROR: Error al generar la llave '$KEY_PATH'."
        return 1
    fi
}
# Función para generar el requerimiento 
function generate_csr() {
    if [ -e "$CSR_PATH" ]; then
        echo "El requerimiento '$CSR_PATH' ya existe."
        return 0
    fi
    # Generar el requerimiento  
    echo "Generando el requerimiento  ..."
    if sudo openssl req -new -key "$KEY_PATH" -out "$CSR_PATH" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"; then
        echo "Se ha creado el requerimiento: $CSR_PATH."
    else
        echo "ERROR: Error al generar el requerimiento '$CSR_PATH'."
        return 1
    fi
}
# Función para remover el passphrase de la llave 
function remove_passphrase() {
    echo "Removing passphrase from key (for nginx)..."
    sudo cp "$KEY_PATH" "$KEY_PATH.org"
    sudo openssl rsa -in "$KEY_PATH.org" -out "$KEY_PATH"
    sudo rm "$KEY_PATH.org"
}
# Función para generar el certificado
function generate_crt() {
    if [ -e "$CRT_PATH" ]; then
        echo "El certificado '$CRT_PATH' ya existe."
        return 0
    fi
    # generar el certificado
    echo "Generando el certificado..."
    if openssl x509 -req -days 365 -in "$CSR_PATH" -signkey "$KEY_PATH" -out "$CRT_PATH"; then
        echo "Se ha creado el certificado: '$CRT_PATH'."
    else
        echo "ERROR:Error al generar el certificado '$CRT_PATH'."
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
    echo "Los permisos fueron cambiados."
}
# Función principal
function nginx_generate_certs() {
    echo "******************NGINX GENERATE CERTS******************"
    create_cert_directory
    generate_key
    generate_csr
    remove_passphrase
    generate_crt
    change_mod
    echo "******************ALL DONE******************"
}
# Llama a la función princial
nginx_generate_certs
