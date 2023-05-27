#!/bin/bash
# openldap_config.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
SLAPD_CONFIG_FILE="slapd.conf.ldif"
SLAPD_CONFIG_PATH="$CURRENT_DIR/$SLAPD_CONFIG_FILE"
SLAPD_USERS_FILE="users.ldif"
SLAPD_USERS_PATH="$CURRENT_DIR/$SLAPD_USERS_FILE"
CONFIG_LOGLEVEL_FILE="slapd_config_loglevel.ldif"
CONFIG_LOGLEVEL_PATH="$CURRENT_DIR/$CONFIG_LOGLEVEL_FILE"
CONFIG_SUFFIX_FILE="slapd_config_suffix.ldif"
CONFIG_SUFFIX_PATH="$CURRENT_DIR/$CONFIG_SUFFIX_FILE"
SETUP_BASIC_FILE="slapd_setup_basic.ldif"
SETUP_BASIC_PATH="$CURRENT_DIR/$SETUP_BASIC_FILE"
CONFIG_TLS_FILE="slapd_config_TLS_enable.ldif"
CONFIG_TLS_PATH="$CURRENT_DIR/$CONFIG_TLS_FILE"
SETUP_ROOT_FILE="slapd_setup_config_rootPW.ldif"
SETUP_ROOT_PATH="$CURRENT_DIR/$SETUP_ROOT_FILE"
COMPANY="samava"
DOMAIN="avilesworks.com"
ADMIN_PASSWORD="1234"
SLAP_CONFIG="/etc/default/slapd"
LDAP_CONFIG="/etc/ldap/ldap.conf"
ADMIN_FILE="/etc/ldap/slapd.d/admin.ldif"
export DEBIAN_FRONTEND=noninteractive
export SLAPD_NO_CONFIGURATION=true

function instalar_openldap() {
  # Instalar OpenLDAP
  echo "Instalando OpenLDAP..."
  echo "slapd slapd/no_configuration seen true" | sudo debconf-set-selections
  sudo apt-get update
  sudo apt-get install -y slapd ldap-utils phpldapadmin

  # Establecer contraseña de administrador
  echo "Configurando contraseña de administrador..."
  echo "cn=admin,$COMPANY" > "$ADMIN_FILE"
  echo "dn: cn=admin,$COMPANY" >> "$ADMIN_FILE"
  echo "objectClass: simpleSecurityObject" >> "$ADMIN_FILE"
  echo "objectClass: organizationalRole" >> "$ADMIN_FILE"
  echo "userPassword: $(slappasswd -s $ADMIN_PASSWORD)" >> "$ADMIN_FILE"
  echo "cn: admin" >> "$ADMIN_FILE"
  sudo ldapadd -x -D cn=admin,cn=config -W -f "$ADMIN_FILE"
  sudo rm "$ADMIN_FILE"
  # Iniciar el servicio slapd
  iniciar_servicio_ldap
}
function add_templates() {
    sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/cosine.ldif
    sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/nis.ldif
    sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/inetorgperson.ldif
    sudo ldapadd -Y EXTERNAL -H ldapi:/// -f "$SLAPD_CONFIG_PATH"
    sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$CONFIG_LOGLEVEL_PATH"
    sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$CONFIG_SUFFIX_PATH"
    sudo ldapmodify -x -W -D cn=admin,dc=ldap,dc=avilesworks,dc=com -H ldapi:/// -f "$SETUP_BASIC_PATH"
    sudo ldapadd -C -X -D cn=admin,dc=ldap,dc=avilesworks,dc=com -W -f "$SLAPD_USERS_PATH"
    #sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$SETUP_ROOT_PATH"
    sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$CONFIG_TLS_PATH"
   
    
}

function enable_tls() {
  # Habilitar la autenticacion TLS
  echo "Habilitando la autenticacion TLS..."
   #TLS_CACERT
  if grep -q "#TLS_CACERT" "$LDAP_CONFIG"; then
    sudo sed -i "s|^#TLS_CACERT*|TLS_CACERT /etc/ldap/tls/CA.pem|" "$LDAP_CONFIG" || { echo "ERROR: Hubo un problema al configurar el archivo '$LDAP_CONFIG': #TLS_CACERT"; exit 1; }
  elif grep -q "TLS_CACERT" "$SLAP_CONFIG"; then
    sudo sed -i "s|^TLS_CACERT.*|TLS_CACERT /etc/ldap/tls/CA.pem|" "$LDAP_CONFIG" || { echo "ERROR: Hubo un problema al configurar el archivo '$LDAP_CONFIG': TLS_CACERT"; exit 1; }
  else
    echo "TLS_CACERT /etc/ldap/tls/CA.pem" >> "$LDAP_CONFIG"
  fi
}

function configurar_openldap() {
  # Configuración inicial de OpenLDAP
  echo "Configuración inicial de OpenLDAP..."
  # Iniciar configuración inicial
  sudo dpkg-reconfigure slapd

  # Establecer respuestas para evitar el mensaje de configuración inicial y la eliminación de la base de datos
  sudo debconf-set-selections <<EOF
slapd slapd/no_configuration boolean true
slapd slapd/purge_database boolean false
slapd slapd/move_old_database boolean true
slapd slapd/password1 password $ADMIN_PASSWORD
slapd slapd/password2 password $ADMIN_PASSWORD
slapd shared/organization string $COMPANY
slapd slapd/domain string $DOMAIN
EOF
 
}
function iniciar_servicio_ldap() {
  # Iniciar el servicio slapd
  echo "Iniciando el servicio slapd..."
  sudo service slapd start
}

function configurar_interfaces_red() {
  # Configurar slapd para escuchar en todas las interfaces de red
  echo "Configurando slapd para escuchar en todas las interfaces de red..."
   #SLAPD_SERVICES
  if grep -q "#SLAPD_SERVICES" "$SLAP_CONFIG"; then
    sudo sed -i "s|^#SLAPD_SERVICES.*|SLAPD_SERVICES="ldap:///"|" "$SLAP_CONFIG" || { echo "ERROR: Hubo un problema al configurar el archivo '$SLAP_CONFIG': #SLAPD_SERVICES"; exit 1; }
  elif grep -q "SLAPD_SERVICES" "$SLAP_CONFIG"; then
    sudo sed -i "s|^SLAPD_SERVICES.*|SLAPD_SERVICES="ldap:///"|" "$SLAP_CONFIG" || { echo "ERROR: Hubo un problema al configurar el archivo '$SLAP_CONFIG': SLAPD_SERVICES"; exit 1; }
  else
    echo "SLAPD_SERVICES="ldap:///"" >> "$SLAP_CONFIG"
  fi
}
function add_host_config() {
    # Agregar al archivo /etc/hosts el dominio del servidor
    echo "Agregando al archivo '/etc/hosts' el dominio del servidor..."
    sudo sed -i "$ a\127.0.0.1 ldap.$DOMAIN" /etc/hosts || { echo "ERROR: Hubo un problema al configurar el archivo '/etc/hosts': 127.0.0.1 ldap.$DOMAIN"; exit 1; }
}
function restart_service() {
  # Reiniciar el servicio slapd
  echo "Reiniciando el servicio slapd..."
  sudo service slapd restart 
}

# Funcion principal
function openldap_config() {
  instalar_openldap
  add_templates
  enable_tls
  add_host_config
  #configurar_openldap
  #configurar_interfaces_red
  restart_service
}
# Llamar a la funcion principal
openldap_config
