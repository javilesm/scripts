#!/bin/bash
# mysql_config.sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
USERS_FILE="mysql_users.csv"
USERS_PATH="$SCRIPT_DIR/$USERS_FILE"
DBS_FILE="mysql_db.csv"
DBS_PATH="$SCRIPT_DIR/$DBS_FILE"
ROLES_FILE="mysql_roles.csv"
ROLES_PATH="$SCRIPT_DIR/$ROLES_FILE"
MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"
MYSQL_SOCKET="/var/run/mysqld/mysqld.sock"
password="root"
# Función para verificar si se ejecuta el script como root
function check_root() {
    echo "Verificando si se ejecuta el script como root..."
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ser ejecutado como root"
        exit 1
    fi
}
# Función para verificar la existencia del archivo de usuarios
function check_user_file() {
    echo "Verificando la existencia del archivo de usuarios"
    if [ ! -f "$USERS_PATH" ]; then
        echo "El archivo de usuarios '$USERS_FILE' no existe en el directorio $SCRIPT_DIR/"
        exit 1
    fi
    echo "El archivo de usuarios '$USERS_FILE' existe."
}
# Función para validar la existencia del archivo de bases de datos
function check_dbs_file() {
    echo "Validando la existencia del archivo de bases de datos..."
    if [ ! -f "$DBS_PATH" ]; then
        echo "El archivo de bases de datos '$DBS_FILE' no existe en el directorio $SCRIPT_DIR/"
        exit 1
    fi
    echo "El archivo de bases de datos '$DBS_FILE' existe."
}

# Función para establecer la propiedad de lectura y escritura del archivo mysqld.cnf
function set_mysql_file_permissions() {
  echo "Estableciendo la propiedad de lectura y escritura del archivo $MYSQL_CONF..."
  sudo chmod 644 "$MYSQL_CONF" && \
  sudo chown mysql:mysql "$MYSQL_CONF" && \
  echo "La propiedad de lectura y escritura del archivo $MYSQL_CONF se ha establecido correctamente."
}

# Función para establecer la ubicación del socket de MySQL
function set_mysql_socket() {
  echo "Estableciendo la ubicación del socket de MySQL en $MYSQL_CONF..."

  # Verificar si el archivo de configuración existe
  if [ ! -f "$MYSQL_CONF" ]; then
    echo "No se puede encontrar el archivo de configuración de MySQL."
    exit 1
  fi

  # Verificar si el socket ya está configurado correctamente
  if grep -q "^socket\s*=\s*$MYSQL_SOCKET" "$MYSQL_CONF"; then
    echo "La ubicación del socket de MySQL ya está configurada correctamente."
  else
    # Agregar la línea del socket al archivo de configuración
    if sudo sed -i "/\[mysqld\]/a socket = $MYSQL_SOCKET" "$MYSQL_CONF"; then
      echo "La ubicación del socket de MySQL se ha configurado correctamente."
    else
      echo "No se pudo configurar la ubicación del socket de MySQL."
      exit 1
    fi
  fi
}
# Función para iniciar el servicio MySQL
function start_mysql() {
  sudo usermod -d /var/lib/mysql/ mysql
  sudo service mysql status
  echo "Iniciando servicio MySQL..."
  sudo service mysql start

}
# Función para crear una base de datos en MySQL
function create_db() {
    echo "Creando bases de datos en MySQL desde '$DBS_FILE' ..."
    # Leer la lista de bases de datos desde el archivo mysql_databases.csv
    while IFS=, read -r dbname; do
        # Crear base de datos
        sudo mysql -e "CREATE DATABASE IF NOT EXISTS $dbname;"
    done < "$DBS_PATH"
    echo "Todas las bases de datos en '$DBS_FILE' fueron creadas."
}
# Función para crear un usuario en MySQL
function create_user() {
    echo "Creando usuarios en MySQL desde '$USERS_FILE' ..."
    # Leer la lista de usuarios y contraseñas desde el archivo mysql_users.csv
    while IFS=, read -r username password host; do
        # Verificar si el usuario ya existe
        if sudo mysql -e "SELECT 1 FROM mysql.user WHERE user='$username'" | grep -q 1; then
            echo "El usuario '$username' ya existe."
            continue
        fi

        # Crear usuario
        sudo mysql -e "CREATE USER '$username'@'$host' IDENTIFIED BY '$password';"

        # Verificar que el usuario se ha creado correctamente
        if ! sudo mysql -e "SELECT 1 FROM mysql.user WHERE user='$username'" | grep -q 1
        then
            echo "No se ha podido crear el usuario '$username' en el host '$host'."
            exit 1
        fi
    done < "$USERS_PATH"
    echo "Todos los usuarios en '$USERS_FILE' fueron creados."
}

# Función para otorgar privilegios a un usuario en una o varias bases de datos de MySQL
function grant_privileges() {
    echo "Otorgando privilegios a un usuario en una o varias bases de datos de MySQL..."
    
    # Leer la información de los usuarios desde el archivo mysql_users.csv
    while IFS=';' read -r username password host databases privileges; do
        echo "Otorgando privilegios al usuario '$username' en las bases de datos '$databases'..."
        # Verificar si el usuario ya tiene privilegios en cada base de datos
        IFS=',' read -ra dbs <<< "$databases"
        for db in "${dbs[@]}"; do
            if mysql -u root -p"$password" -e "SELECT User, Host, Db FROM mysql.db WHERE User='$username' AND Db='$db';" | grep -q "$username"; then
                # Actualizar privilegios del usuario si es necesario
                mysql -u root -p"$password" -e "GRANT $privileges ON $db.* TO '$username'@'$host';"
                echo "Los privilegios del usuario '$username' en la base de datos '$db' en el host '$host' se han actualizado correctamente."
            else
                # Otorgar privilegios al usuario si no los tiene
                mysql -u root -p"$password" -e "GRANT $privileges ON $db.* TO '$username'@'$host';"
                echo "Los privilegios del usuario '$username' en la base de datos '$db' en el host '$host' se han otorgado correctamente."
            fi
        done
    done < "$USERS_PATH"
    # Actualizar los privilegios en el servidor MySQL
    echo "Actualizando los privilegios en el servidor MySQL..."
    sudo mysql -e "FLUSH PRIVILEGES;"
    echo "Los privilegios en el servidor MySQL se han actualizado correctamente."
}
# Función para actualizar el host de un usuario en MySQL
function update_host() {
    echo "Actualizando el host de los usuarios en MySQL..."
    
    # Leer la información de los usuarios desde el archivo mysql_users.csv
    while IFS=';' read -r username password host databases privileges; do
        # Verificar si el usuario ya existe en la base de datos
        if mysql -u root -p"$password" -e "SELECT User FROM mysql.user WHERE User='$username' AND Host='$host';" | grep -q "$username"; then
            # Actualizar el host del usuario
            mysql -u root -p"$password" -e "ALTER USER '$username'@'$host' IDENTIFIED BY '$password';"
            echo "El host del usuario '$username' se ha actualizado correctamente."
        else
            echo "El usuario '$username' no existe en la base de datos con el host '$host'."
        fi
    done < "$USERS_PATH"
    
    # Actualizar los privilegios en el servidor MySQL
    echo "Actualizando los privilegios en el servidor MySQL..."
    sudo mysql -e "FLUSH PRIVILEGES;"
    echo "Los privilegios en el servidor MySQL se han actualizado correctamente."
}

# mostrar todos los usuarios en MySQL
function show_users() {
    echo "Mostrando todos los usuarios en MySQL..."
    sudo mysql -e "SELECT User, Host FROM mysql.user;"
}
# mostrar todas las bases de datos en MySQL
function show_databases() {
    echo "Mostrando todas las bases de datos en MySQL..."
    sudo mysql -e "SHOW DATABASES;"
}
# mostrar todos los privilegios en MySQL
function show_privileges() {
  echo "Mostrando todos los privilegios en MySQL..."
  sudo mysql -e "SELECT * FROM mysql.user\G;"
}
# Función para reiniciar el servicio de MySQL
function restart_mysql_service() {
    echo "Reiniciando el servicio de MySQL..."
    sudo service mysql restart
}
# Función principal
function mysql_config() {
    echo "**********MYSQL CONFIG**********"
    check_root
    check_user_file
    check_dbs_file
    set_mysql_file_permissions
    set_mysql_socket
    start_mysql
    create_db
    create_user
    grant_privileges
    update_user_host
    show_users
    show_databases
    show_privileges
    restart_mysql_service
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
mysql_config
