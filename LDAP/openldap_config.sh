#!/bin/bash
# openldap_config.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
SLAPD_CONFIG_FILE="slapd.conf.ldif"
SLAPD_CONFIG_PATH="$CURRENT_DIR/$SLAPD_CONFIG_FILE"
SLAPD_USERS_FILE="add_content.ldif"
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
# Funciones
function install_slapd() {
  # Instalar OpenLDAP
  echo "Instalando OpenLDAP..."
  sudo apt-get update
  sudo apt-get install -y slapd

  # Verificar si la instalación fue exitosa
  if [ $? -ne 0 ]; then
    echo "Error: La instalación de OpenLDAP ha fallado."
    return 1
  fi

  echo "OpenLDAP se ha instalado correctamente."

  # Configurar OpenLDAP automáticamente
  sudo dpkg-reconfigure slapd

  # Establecer contraseña de administrador
  sudo ldappasswd -x -D "cn=admin,dc=$COMPANY,dc=$DOMAIN" -w "$ADMIN_PASSWORD" -s "$ADMIN_PASSWORD"

  # Reiniciar OpenLDAP
  sudo service slapd restart
}

function configurar_slapd() {
  # Configuración inicial de OpenLDAP
  echo "Configuración inicial de OpenLDAP..."
  # Iniciar configuración inicial
  sudo dpkg-reconfigure slapd

  # Establecer respuestas para evitar el mensaje de configuración inicial y la eliminación de la base de datos
  sudo debconf-set-selections <<EOF
slapd slapd/no_configuration boolean true
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
slapd slapd/password1 password $ADMIN_PASSWORD
slapd slapd/password2 password $ADMIN_PASSWORD
slapd shared/organization string $COMPANY
slapd slapd/domain string $DOMAIN
EOF
 
}
function update_ldap_conf() {
  # Actualizar parametro BASE
  echo "Actualizando parametro BASE..."
   #BASE
  if grep -q "#BASE" "$LDAP_CONFIG"; then
    sudo sed -i "s|^#BASE*|BASE dc=avilesworks,dc=com|" "$LDAP_CONFIG" || { echo "ERROR: Hubo un problema al configurar el archivo '$LDAP_CONFIG': #BASE"; exit 1; }
  elif grep -q "BASE" "$SLAP_CONFIG"; then
    sudo sed -i "s|^BASE.*|BASE dc=avilesworks,dc=com|" "$LDAP_CONFIG" || { echo "ERROR: Hubo un problema al configurar el archivo '$LDAP_CONFIG': BASE"; exit 1; }
  else
    echo "BASE dc=avilesworks,dc=com" >> "$LDAP_CONFIG"
  fi
    # Actualizar parametro URI
  echo "Actualizando parametro URI..."
   #URI
  if grep -q "#URI" "$LDAP_CONFIG"; then
    sudo sed -i "s|^#URI*|URI ldap://ldap.avilesworks.com|" "$LDAP_CONFIG" || { echo "ERROR: Hubo un problema al configurar el archivo '$LDAP_CONFIG': #URI"; exit 1; }
  elif grep -q "URI" "$SLAP_CONFIG"; then
    sudo sed -i "s|^URI.*|URI ldap://ldap.avilesworks.com|" "$LDAP_CONFIG" || { echo "ERROR: Hubo un problema al configurar el archivo '$LDAP_CONFIG': URI"; exit 1; }
  else
    echo "URI ldap://ldap.avilesworks.com" >> "$LDAP_CONFIG"
  fi
  # Actualizar parametro TLS_CACERT
  echo "Actualizando parametro TLS_CACERT..."
   #TLS_CACERT
  if grep -q "#TLS_CACERT" "$LDAP_CONFIG"; then
    sudo sed -i "s|^#TLS_CACERT*|TLS_CACERT /etc/ldap/tls/CA.pem|" "$LDAP_CONFIG" || { echo "ERROR: Hubo un problema al configurar el archivo '$LDAP_CONFIG': #TLS_CACERT"; exit 1; }
  elif grep -q "TLS_CACERT" "$SLAP_CONFIG"; then
    sudo sed -i "s|^TLS_CACERT.*|TLS_CACERT /etc/ldap/tls/CA.pem|" "$LDAP_CONFIG" || { echo "ERROR: Hubo un problema al configurar el archivo '$LDAP_CONFIG': TLS_CACERT"; exit 1; }
  else
    echo "TLS_CACERT  /etc/ldap/tls/CA.pem" >> "$LDAP_CONFIG"
  fi
}

function install_ldap-utils() {
  # Instalar LDAPutils
  echo "Instalando LDAPutils..."
  sudo apt-get install -y ldap-utils

  # Verificar si la instalación fue exitosa
  if [ $? -ne 0 ]; then
    echo "Error: La instalación de LDAPutils ha fallado."
    return 1
  fi

  echo "LDAPutils se ha instalado correctamente."
  return 0
    # Iniciar el servicio slapd
  iniciar_servicio_ldap

  # Verificar si el servicio se ha iniciado correctamente
  if [ $? -ne 0 ]; then
    echo "Error: No se pudo iniciar el servicio slapd."
    return 1
  fi
}

function setup_slapd() {
  # Establecer contraseña de administrador
  echo "Configurando contraseña de administrador..."
  echo "cn=admin,$COMPANY" > "$ADMIN_FILE"
  echo "dn: cn=admin,$COMPANY" >> "$ADMIN_FILE"
  echo "objectClass: simpleSecurityObject" >> "$ADMIN_FILE"
  echo "objectClass: organizationalRole" >> "$ADMIN_FILE"
  echo "userPassword: $(slappasswd -s $ADMIN_PASSWORD)" >> "$ADMIN_FILE"
  echo "cn: admin" >> "$ADMIN_FILE"

  # Agregar la entrada del administrador
  echo "Agregando plantilla desde '$ADMIN_FILE'..."
  sudo ldapadd -x -D cn=admin,cn=config -W -f "$ADMIN_FILE"

  # Verificar si la adición de la entrada del administrador fue exitosa
  if [ $? -ne 0 ]; then
    echo "Error: No se pudo agregar la entrada del administrador."
    sudo rm "$ADMIN_FILE"
    return 1
  fi

  # Eliminar el archivo temporal del administrador
  sudo rm "$ADMIN_FILE"

  echo "OpenLDAP se ha configurado correctamente."
  return 0
}



function add_templates() {
  echo "Agregando plantilla desde '$SLAPD_CONFIG_PATH'..."
  sudo ldapadd -Y EXTERNAL -H ldapi:/// -f "$SLAPD_CONFIG_PATH" || { echo "Error: No se pudo agregar la plantilla desde '$SLAPD_CONFIG_PATH'."; return 1; }

  echo "Modificando '$CONFIG_LOGLEVEL_PATH'..."
  sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$CONFIG_LOGLEVEL_PATH" || { echo "Error: No se pudo modificar el archivo '$CONFIG_LOGLEVEL_PATH'."; return 1; }

  echo "Modificando '$CONFIG_SUFFIX_PATH'..."
  sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$CONFIG_SUFFIX_PATH" || { echo "Error: No se pudo modificar el archivo '$CONFIG_SUFFIX_PATH'."; return 1; }

  echo "Modificando '$SETUP_BASIC_PATH'..."
  sudo ldapmodify -x -W -D cn=admin,dc=avilesworks,dc=com -H ldapi:/// -f "$SETUP_BASIC_PATH" || { echo "Error: No se pudo modificar el archivo '$SETUP_BASIC_PATH'."; return 1; }

  echo "Agregando plantilla desde '$SLAPD_USERS_PATH'..."
  sudo ldapadd -x -D cn=admin,dc=avilesworks,dc=com -W -f "$SLAPD_USERS_PATH" || { echo "Error: No se pudo agregar la plantilla desde '$SLAPD_USERS_PATH'."; return 1; }

  #sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$SETUP_ROOT_PATH"
  
  echo "Modificando '$CONFIG_TLS_PATH'..."
  sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$CONFIG_TLS_PATH" || { echo "Error: No se pudo modificar el archivo '$CONFIG_TLS_PATH'."; return 1; }

  echo "Las plantillas y configuraciones se han agregado correctamente."
  return 0
}

function iniciar_servicio_ldap() {
  # Iniciar el servicio slapd
  echo "Iniciando el servicio slapd..."
  sudo service slapd start

  # Verificar si el inicio del servicio fue exitoso
  if [ $? -ne 0 ]; then
    echo "Error: No se pudo iniciar el servicio slapd."
    return 1
  fi

  echo "El servicio slapd se ha iniciado correctamente."
  return 0
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
    sudo sed -i.bak "$ a\127.0.0.1 ldap.$DOMAIN" /etc/hosts || { echo "ERROR: Hubo un problema al configurar el archivo '/etc/hosts': 127.0.0.1 ldap.$DOMAIN"; return 1; }
    
    # Verificar si la modificación del archivo /etc/hosts fue exitosa
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo agregar el dominio del servidor al archivo '/etc/hosts'."
        return 1
    fi
    
    echo "El dominio del servidor se ha agregado correctamente al archivo '/etc/hosts'."
    return 0
}

function restart_service() {
  # Reiniciar el servicio slapd
  echo "Reiniciando el servicio slapd..."
  sudo service slapd restart

  # Verificar si el reinicio del servicio fue exitoso
  if [ $? -ne 0 ]; then
    echo "Error: No se pudo reiniciar el servicio slapd."
    return 1
  fi

  echo "El servicio slapd se ha reiniciado correctamente."
  return 0
}

function install_phpldapadmin() {
  # Instalar phpldapadmin
  echo "Instalando phpldapadmin..."
  sudo apt-get install -y phpldapadmin

  # Verificar si la instalación fue exitosa
  if [ $? -ne 0 ]; then
    echo "Error: La instalación de phpldapadmin ha fallado."
    return 1
  fi

  echo "phpldapadmin se ha instalado correctamente."
  return 0
}

# Funcion principal
function openldap_config() {
  install_slapd
  #configurar_slapd
  update_ldap_conf
  install_ldap-utils
  setup_slapd
  add_templates
  #stop_processes_using_hosts
  add_host_config
  configurar_interfaces_red
  restart_service
  #install_phpldapadmin
}
# Llamar a la funcion principal
openldap_config
