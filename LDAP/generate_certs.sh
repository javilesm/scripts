#!/bin/bash
# generate_certs.sh
# Variables
DOMAIN="avilesworks.com"
NAME="samava_ldap"
CERTS_PATH="/etc/ldap/tls"
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
# Función para generar la llave CA
function generate_ca_key() {
  # generar la llave privada
  echo "Generando la llave privada..."
  sudo openssl genrsa -out "$CERTS_PATH/CA.key" 8192 && sudo chmod 400 "$CERTS_PATH/CA.key"
  echo "La llave privada '$CERTS_PATH/CA.key' hasido generada."
  #  Genera una solicitud de certificado 
  echo "Generando una solicitud de certificado..."
  sudo openssl req -new -x509 -nodes -key "$CERTS_PATH/CA.key" -days 3650 -out "$CERTS_PATH/CA.pem"
  echo "El certificado '$CERTS_PATH/CA.pem' ha sido generado."
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
    if sudo openssl x509 -req -in "$CSR_PATH" -CA "$CERTS_PATH/CA.pem" -CAkey "$CERTS_PATH/CA.key"  -CAcreateserial -out "$CRT_PATH" -days 365; then
        echo "Se ha creado el certificado: $CRT_PATH para el dominio: ${DOMAIN}"
    else
        echo "ERROR:Error al generar el certificado '$CRT_PATH'."
        return 1
    fi
}

# Función para cambiar permisos
function change_mod() {
    # cambiar permisos
    sudo chown -R openldap:openldap "$CERTS_PATH"
    sudo chmod 101 "$CERTS_PATH"
    sudo chmod 400 "$CERTS_PATH/*"
    echo "Cambiando permisos del archivo '$CRT_PATH'..."
    sudo chmod 404 "$CERTS_PATH/CA.pem"
    echo "Los permisos fueron cambiados."
}
# Función principal
function generate_certs() {
    echo "******************GENERATE CERTS******************"
    create_cert_directory
    generate_ca_key
    generate_key
    generate_certificate
    change_mod
    echo "******************ALL DONE******************"
}
# Llama a la función princial
generate_certs
