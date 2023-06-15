#!/bin/bash
# nextcloud_config.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled/"
PARENT_DIR="$( dirname "$CURRENT_PATH" )" # Get the parent directory of the current directory
host="samava-cloud"
nextcloud_dir="nextcloud"
react_dir="react-app"
django_dir="django"
server_ip="3.220.58.75"
HTML_PATH="/var/www/$host"
config_path="/etc/nginx/sites-available/$host"
nextcloud_root="$HTML_PATH/$nextcloud_dir"
react_root="$HTML_PATH/$react_dir"
django_root="$HTML_PATH/$django_dir"
GID_NAME="www-data"
UID_NAME="www-data"
CERTS_FILE="generate_certs.sh"
CERTS_PATH="$PARENT_DIR/Dovecot/$CERTS_FILE"

# Función para leer la variable KEY_PATH desde el script '$CERTS_PATH'
function read_KEY_PATH() {
    # Verificar si el archivo existe
    if [ -f "$CERTS_PATH" ]; then
        # Cargar el contenido del archivo 'generate_certs.sh' en una variable
        file_contents=$(<"$CERTS_PATH")

        # Evaluar la cadena para expandir las variables
        eval "$file_contents"

        # Imprimir el valor actual de la variable KEY_PATH
        echo "El valor del KEY_PATH definido es: $KEY_PATH"
        echo "El valor del PEM_PATH definido es: $PEM_PATH"
    else
        echo "El archivo '$CERTS_PATH' no existe."
    fi
}

function uninstall_apache2() {
  echo "Desintalando apache2 del sistema...."
  sudo systemctl stop apache2
  sudo apt-get remove apache2 -y
  sudo apt-get purge apache2 -y
  echo "Apache2 ha sido desintalado del sistema."
}

function restart_nginx() {
  echo "Reiniciando servicio Nginx..."
  sudo service nginx restart
}

function get_php_fpm_version() {
    # Obtener la versión de PHP-FPM
    version_output=$(php -v 2>&1)
    regex="PHP ([0-9]+\.[0-9]+)"

    if [[ $version_output =~ $regex ]]; then
        version_number="${BASH_REMATCH[1]}"
        echo "Versión de PHP-FPM instalada: $version_number"
    else
        echo "No se pudo obtener la versión de PHP-FPM."
    fi
}

function create_nginx_configs() {
  # Crear el archivo de configuración
  echo "Creando archivos de configuración para el dominio: $host..."
  if ! sudo touch "$config_path"; then
    echo "Error: No se pudo crear el archivo de configuración de NGINX."
    return 1
  fi
  echo "Archivo de configuración creado: $config_path"
  echo "Editando el archivo de configuración..."
  # Editar el archivo de configuración
  
  echo "server {
    listen 80;
    server_name $server_ip;
    return 301 https://\$host\$request_uri;       
}

server {
    listen 443 ssl;
    server_name $server_ip;
    
    # Configura los certificados SSL
    ssl_certificate  $PEM_PATH;
    ssl_certificate_key  $KEY_PATH;

    root $HTML_PATH/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location /nextcloud {
        alias $nextcloud_root;
        index index.php;
    
        location ~ \.php\$ {
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$request_filename;
            fastcgi_pass unix:/var/run/php/php$version_number-fpm.sock;
        }
      
        location ~* \.(?:css|js|svg|gif|png|html|ttf|woff|ico|jpg|jpeg)$ {
            try_files \$uri \$uri/ /nextcloud/index.php\$request_uri;
            expires 30d;
            access_log off;
        }
    }
    
    location /app {
        alias $react_root;
        index index.js;

        location ~* \.(?:js|css)$ {
            try_files \$uri \$uri/ /app/index.js;
            expires 30d;
            access_log off;
        }
    }
    
    # Configuración para el panel de administración de Django
    location /admin {
        alias /var/www/samava-cloud/django_project/admin;
        
        # Configura la ubicación del archivo de configuración de Django
        location /admin/manage.py {
            include uwsgi_params;
            uwsgi_pass unix:/var/run/uwsgi/app/django_app/socket;
        }
    }
    
    # Configura la ubicación de los archivos de caché
    location ~ ^/(?:\.htaccess|data|config|db_structure\.xml|README) {
        deny all;
    }

    # Configura las reglas de reescritura de URL
    location ~ ^/.well-known/carddav {
        rewrite ^(.*) /remote.php/dav/ redirect;
    }

    location ~ ^/.well-known/caldav {
        rewrite ^(.*) /remote.php/dav/ redirect;
    }

    location ~ ^(/core/doc/[^\/]+/)$ {
        rewrite ^(.*) \$1/index.html;
    }

    # Configura las reglas de reescritura de URL para PHP
    location ~ ^\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+)\.php(?:\$|\/) {
        fastcgi_split_path_info ^(.+\.php)(\/.+)\$;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_pass unix:/var/run/php/php$version_number-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTPS on;
    }

    # Configura las reglas de reescritura de URL para otros archivos PHP
    location ~ ^\/(?:updater|oc[ms]-provider)(?:\$|\/) {
        try_files \$uri/ =404;
        index index.php;
    }

    # Configura la ubicación de los archivos de caché
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Configuración adicional según tus necesidades...
}" | sudo tee "$config_path" > /dev/null

  echo "Archivo de configuración creado: $config_path"
}

function test_config() {
  # Comprobar la configuración de Nginx
  echo "Comprobando la configuración de Nginx..."
  if sudo nginx -t; then
    echo "Nginx se ha configurado correctamente."
    sudo service nginx reload
    sudo service php"$version_number"-fpm stop
    sudo service php"$version_number"-fpm start
   
  else
    echo "ERROR: Hubo un problema con la configuración de Nginx."
    exit 1
  fi
}
function webset() {
  # cambiar permisos del subdirectorio
  echo "Cambiando los permisos del subdirectorio '$HTML_PATH'..."
  sudo chmod -R 755 "$HTML_PATH"
  # cambiar la propiedad del directorio
  echo "Cambiando la propiedad del directorio '$HTML_PATH'..."
  sudo chown -R ${UID_NAME//\"/}:${GID_NAME//\"/} "$HTML_PATH"
  # create a symbolic link of the site configuration file in the sites-enabled directory.
  echo "Creando un vínculo simbólico del archivo '$config_path' y el archivo '$NGINX_SITES_ENABLED'..."
  if ! sudo ln -s "$config_path" "$NGINX_SITES_ENABLED"; then
    echo "Error: No se pudo crear el enlace simbólico para el archivo de configuración de NGINX."
    return 1
  fi
}
# Función para configurar Nextcloud
function configure_nextcloud() {
  echo "Configurando Nextcloud..."
  if ! sudo nextcloud.occ maintenance:install --database "mysql" --database-name "nextcloud" --database-user "nextcloud" --database-pass "65jyykjhvbk46156" --admin-user "root" --admin-pass; then
    echo "Error al configurar Nextcloud."
    return 1
  fi
  echo "Nextcloud se ha configurado correctamente."
  return 0
}

# Función principal
function nextcloud_config() {
  echo "**********NEXTCLOUD CONFIGURATOR***********"
  read_KEY_PATH
  uninstall_apache2
  restart_nginx
  get_php_fpm_version
  create_nginx_configs
  test_config
  webset
  configure_nextcloud
  echo "**********ALL DONE***********"
}
# Llamar a la función principal
nextcloud_config
