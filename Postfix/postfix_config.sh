#!/bin/bash
# postfix_config.sh
# Variables 
VIRTUAL_DOMAINS="/etc/postfix/virtual_domains.cf"
VIRTUAL_MAILBOX="/etc/postfix/virtual_mailbox.cf"
VIRTUAL_ALIAS="/etc/postfix/virtual_alias.cf"
CERTIFICADO="/etc/ssl/certs/ssl-cert-snakeoil.pem" # default self-signed certificate that comes with Ubuntu
CLAVE_PRIVADA="/etc/ssl/private/ssl-cert-snakeoil.key"
# Función para creación del grupo para el servidor virtual
function create_virtual_group() {
   # Verificar si el grupo ya existe
   if grep -q vmail /etc/group; then
       echo "El grupo vmail ya existe."
       return 0
   fi
   # Creación del grupo para el servidor virtual
   echo "Creando el grupo para el servidor virtual..."
   if sudo groupadd -g 5000 vmail; then
       echo "El grupo vmail se ha creado exitosamente."
       return 0
   else
       echo "ERROR: No se pudo crear el grupo vmail."
       return 1
   fi
}
# Función para creación del usuario para el servidor virtual
function create_virtual_user() {
   # Verificar si el usuario ya existe
   if id vmail >/dev/null 2>&1; then
       echo "El usuario vmail ya existe."
       return 0
   fi
   # Creación del usuario para el servidor virtual
   echo "Creando el usuario para el servidor virtual..."
   if sudo useradd -g vmail -u 5000 vmail -d /var/vmail -m; then
       echo "El usuario vmail se ha creado exitosamente."
       return 0
   else
       echo "ERROR: No se pudo crear el usuario vmail."
       return 1
   fi
}

# Función para configuración de Postfix para usar SQLite como motor de base de datos
function configure_postfix() {
   # Configuración de Postfix para usar SQLite como motor de base de datos
   echo "Configurando de Postfix para usar SQLite como motor de base de datos..."
   sudo postconf -e 'virtual_mailbox_domains = sqlite:$VIRTUAL_DOMAINS'
   sudo postconf -e 'virtual_mailbox_maps = sqlite:$VIRTUAL_MAILBOX'
   sudo postconf -e 'virtual_alias_maps = sqlite:$VIRTUAL_ALIAS'
   sudo postconf -e 'virtual_transport = lmtp:unix:private/dovecot-lmtp'
   sudo postconf -e 'smtpd_tls_security_level = may'
   sudo postconf -e 'smtpd_tls_cert_file = $CERTIFICADO'
   sudo postconf -e 'smtpd_tls_key_file = $CLAVE_PRIVADA'
   sudo postconf -e 'smtpd_use_tls=yes'
   sudo postconf -e 'smtpd_sasl_auth_enable = yes'
   sudo postconf -e 'smtpd_sasl_type = dovecot'
   sudo postconf -e 'smtpd_sasl_path = private/auth'
   sudo postconf -e 'smtpd_sasl_local_domain ='
   sudo postconf -e 'smtpd_sasl_security_options = noanonymous'
   sudo postconf -e 'broken_sasl_auth_clients = yes'
}
# Función para crear archivos de configuración de la base de datos virtual
function create_postfix_conf_files() {
   # Verificar si los archivos de configuración ya existen
   echo "Verificando si los archivos de configuración ya existen..."
   if [[ -f $VIRTUAL_DOMAINS && -f $VIRTUAL_MAILBOX && -f $VIRTUAL_ALIAS ]]; then
       echo "Los archivos de configuración de la base de datos virtual ya existen."
       return 0
   fi
   # Crear archivos de configuración de la base de datos virtual
   echo "Creando archivos de configuración de la base de datos virtual..."
   echo "Creando '$VIRTUAL_DOMAINS'... "
   if sudo touch $VIRTUAL_DOMAINS; then
       echo "Se ha creado el archivo $VIRTUAL_DOMAINS."
   else
       echo "ERROR: No se pudo crear el archivo $VIRTUAL_DOMAINS."
       return 1
   fi
   echo "Creando '$VIRTUAL_MAILBOX'... "
   if sudo touch $VIRTUAL_MAILBOX; then
       echo "Se ha creado el archivo $VIRTUAL_MAILBOX."
   else
       echo "ERROR: No se pudo crear el archivo $VIRTUAL_MAILBOX."
       return 1
   fi
   echo "Creando '$VIRTUAL_ALIAS'... "
   if sudo touch $VIRTUAL_ALIAS; then
       echo "Se ha creado el archivo $VIRTUAL_ALIAS."
   else
       echo "ERROR: No se pudo crear el archivo $VIRTUAL_ALIAS."
       return 1
   fi
   echo "Los archivos de configuración de la base de datos virtual se han creado exitosamente."
   return 0
}

# Función para editar los archivos de configuración de la base de datos virtual
function edit_postfix_conf_files() {
   # Configuración de los archivos de configuración de la base de datos virtual
   echo "Configurando los archivos de configuración de la base de datos virtual..."
   sudo postconf -e "virtual_mailbox_domains = sqlite:$VIRTUAL_DOMAINS"
   sudo postconf -e "virtual_mailbox_maps = sqlite:$VIRTUAL_MAILBOX"
   sudo postconf -e "virtual_alias_maps = sqlite:$VIRTUAL_ALIAS"
   # Configuración del archivo /etc/postfix/virtual_domains.cf
   echo "Configurando el archivo '$VIRTUAL_DOMAINS'..."
   if ! sudo echo "DBNAME=/etc/postfix/virtual_mailbox.db" > $VIRTUAL_DOMAINS; then
       echo "ERROR: Error al escribir 'DBNAME=/etc/postfix/virtual_mailbox.db' en el archivo '$VIRTUAL_DOMAINS'."
       exit 1
   fi
   if ! sudo echo "QUERY=SELECT domain FROM domain WHERE domain='%s' AND active = '1'" >> $VIRTUAL_DOMAINS; then
       echo "ERROR: Error al escribir 'QUERY=SELECT domain FROM domain WHERE domain='%s' AND active = '1'' en el archivo '$VIRTUAL_DOMAINS'."
       exit 1
   fi
   # Configuración del archivo /etc/postfix/virtual_mailbox.cf
   echo "Configurando el archivo '$VIRTUAL_MAILBOX'..."
   if ! sudo echo "DBNAME=/etc/postfix/virtual_mailbox.db" > $VIRTUAL_MAILBOX; then
       echo "ERROR: Error al escribir 'DBNAME=/etc/postfix/virtual_mailbox.db' en el archivo '$VIRTUAL_MAILBOX'."
       exit 1
   fi
   if ! sudo echo "QUERY=SELECT email FROM mailbox WHERE username='%u' AND active = '1'" >> $VIRTUAL_MAILBOX; then
       echo "ERROR: Error al escribir 'QUERY=SELECT email FROM mailbox WHERE username='%u' AND active = '1'' en el archivo '$VIRTUAL_MAILBOX'."
       exit 1
   fi
   # Configuración del archivo /etc/postfix/virtual_alias.cf
   echo "Configurando el archivo '$VIRTUAL_ALIAS'..."
   if ! sudo echo "DBNAME=/etc/postfix/virtual_mailbox.db" > $VIRTUAL_ALIAS; then
       echo "ERROR: Error al escribir 'DBNAME=/etc/postfix/virtual_mailbox.db' en el archivo '$VIRTUAL_ALIAS'."
       exit 1
   fi
   if ! sudo echo "QUERY=SELECT email FROM alias WHERE source='%s' AND active = '1'" >> $VIRTUAL_ALIAS; then
       echo "ERROR: Error al escribir 'QUERY=SELECT email FROM alias WHERE source='%s' AND active = '1'' en el archivo '$VIRTUAL_ALIAS'."
       exit 1
   fi
}

# Función principal
function postfix_config() {
   create_virtual_group
   create_virtual_user
   configure_postfix
   create_postfix_conf_files
   edit_postfix_conf_files
}
# Llamar a la función principal
postfix_config
