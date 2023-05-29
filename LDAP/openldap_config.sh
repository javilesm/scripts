#!/bin/bash
# openldap_config.sh
# Variables
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
SLAPD_CONFIG_FILE="slapd.conf.ldif"
SLAPD_CONFIG_PATH="$CURRENT_DIR/$SLAPD_CONFIG_FILE"
CONTENT_FILE="add_content.ldif"
CONTENT_PATH="$CURRENT_DIR/$CONTENT_FILE"
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

export DEBIAN_FRONTEND=noninteractive
export SLAPD_NO_CONFIGURATION=true
# Funciones
function install_slapd() {
  # Verificar si el usuario actual es root
  if [ "$EUID" -ne 0 ]; then
    echo "Este script debe ejecutarse como usuario root."
    return 1
  fi

  # Instalar OpenLDAP
  echo "Instalando OpenLDAP..."
  apt-get update
  apt-get install -y slapd

  # Verificar si la instalación fue exitosa
  if [ $? -ne 0 ]; then
    echo "Error: La instalación de OpenLDAP ha fallado."
    return 1
  fi

  echo "OpenLDAP se ha instalado correctamente."

  # Instalar el paquete ldap-utils
  echo "Instalando ldap-utils..."
  apt-get install -y ldap-utils
  # Iniciar el servicio slapd
  iniciar_servicio_ldap

  # Configurar OpenLDAP automáticamente
  echo -e "slapd slapd/internal/adminpw password $ADMIN_PASSWORD\n\
  slapd slapd/password1 password $ADMIN_PASSWORD
  slapd slapd/password2 password $ADMIN_PASSWORD
  slapd shared/organization string $COMPANY
  slapd slapd/domain string $DOMAIN
  slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION\n\
  slapd slapd/upgrade_slapcat_failure error\n\
  slapd slapd/no_configuration boolean false\n\
  slapd slapd/purge_database boolean false\n\
  slapd slapd/move_old_database boolean true" | debconf-set-selections

  # Utilizar redirección para simular la pulsación de Enter
  echo -e "\n" | dpkg-reconfigure slapd

  # Establecer contraseña de administrador
  ldappasswd -x -D "cn=admin,dc=$COMPANY,dc=$DOMAIN" -w "$ADMIN_PASSWORD" -s "$ADMIN_PASSWORD"

  # Reiniciar OpenLDAP
  service slapd restart
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

function add_templates() {
  modif_setup
  add_content

  echo "Modificando '$CONFIG_LOGLEVEL_PATH'..."
  sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$CONFIG_LOGLEVEL_PATH" || { echo "Error: No se pudo modificar el archivo '$CONFIG_LOGLEVEL_PATH'."; }

  echo "Modificando '$CONFIG_SUFFIX_PATH'..."
  sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$CONFIG_SUFFIX_PATH" || { echo "Error: No se pudo modificar el archivo '$CONFIG_SUFFIX_PATH'."; }
  
  #sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$SETUP_ROOT_PATH"
  
  echo "Modificando '$CONFIG_TLS_PATH'..."
  sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$CONFIG_TLS_PATH" || { echo "Error: No se pudo modificar el archivo '$CONFIG_TLS_PATH'."; }

  echo "Las plantillas y configuraciones se han agregado correctamente."
  return 0
}

function modif_setup() {
  echo "Modificando '$SETUP_BASIC_PATH'..."
sudo expect << EOF
spawn sudo ldapmodify -x -W -D cn=admin,dc=avilesworks,dc=com -H ldapi:/// -f "$SETUP_BASIC_PATH"
expect "Enter LDAP Password:"
send "$ADMIN_PASSWORD\r"
expect eof
EOF

if [ $? -ne 0 ]; then
  echo "Error: No se pudo modificar el archivo '$SETUP_BASIC_PATH'."
  return 1
fi
}

function add_content() {
  echo "Agregando contenido desde '$CONTENT_PATH'..."
  sudo expect << EOF
spawn sudo ldapadd -x -D cn=admin,dc=avilesworks,dc=com -W -f "$CONTENT_PATH" 
expect "Enter LDAP Password:"
send "$ADMIN_PASSWORD\r"
expect eof
EOF

if [ $? -ne 0 ]; then
  echo "Error: No se pudo modificar el archivo '$SETUP_BASIC_PATH'."
  return 1
fi
echo "Todo el contenido desde '$CONTENT_PATH' fue agreago exitosamente."
ldapsearch -x -LLL -b dc=avilesworks,dc=com
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
  update_ldap_conf
  add_templates
  #stop_processes_using_hosts
  #add_host_config
  configurar_interfaces_red
  restart_service
  install_phpldapadmin
}
# Llamar a la funcion principal
openldap_config
