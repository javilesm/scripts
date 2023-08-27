#!/bin/bash
# nextcloud_config.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_PATH" )" # Get the parent directory of the current directory
host="samava-cloud"
nextcloud_dir="nextcloud"
react_dir="react-app"
django_dir="django_project"
orion_dir="Orion_project"
antares_dir="Antares_project"
WEB_DIR="/var/www"
HTML_PATH="$WEB_DIR/$host"
NGINX_DIR="/etc/nginx"
PMA_PASS_FILE="$NGINX_DIR/pma_pass"
NGINX_SITES_ENABLED="$NGINX_DIR/sites-enabled/"
config_path="$NGINX_DIR/sites-available/$host"
nextcloud_root="$HTML_PATH/$nextcloud_dir"
react_root="$HTML_PATH/$react_dir"
django_root="$HTML_PATH/$django_dir"
orion_root="$HTML_PATH/$orion_dir"
antares_root="$HTML_PATH/$antares_dir/html"
GID_NAME="www-data"
UID_NAME="www-data"
CERTS_FILE="nginx_generate_certs.sh"
CERTS_PATH="$PARENT_DIR/NGINX/$CERTS_FILE"
# Funcion para obtener la dirección IP pública de la instancia EC2
function get_ip() {
    # Obtener la dirección IP pública de la instancia EC2
    echo "Obteniendo la dirección IP pública de la instancia EC2..."
    ip_address=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

    # Imprimir la dirección IP en la consola
    echo "La dirección IP pública de la instancia EC2 es: $ip_address"
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
function create_pma_pass() {
  echo "Creando archivo '$PMA_PASS_FILE'..."
  sudo touch "$PMA_PASS_FILE"

  # Solicitar al usuario ingresar una contraseña
  read -s -p "Ingrese la contraseña de acceso para el usuario 'jorge': " access_password
  echo

  # Generar contraseña segura con OpenSSL
  secure_password=$(openssl passwd -6 "$access_password")

  # Crear archivo pma_pass con la contraseña segura
  echo "jorge:$secure_password" > $PMA_PASS_FILE

  echo "Contraseña segura generada y guardada en el archivo '$PMA_PASS_FILE'."
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
    server_name $ip_address;
    root $HTML_PATH/html;
    index index.html;
    
    location /static/admin {
        alias $django_root/venv/lib/python3.10/site-packages/django/contrib/admin/static/admin;
    }

     location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        
    }

    location /home {
        alias $HTML_PATH/html;
        index index.html;
    }

    location /app {
        rewrite ^/app(/.*)\$ \$1 break;
        proxy_pass http://localhost:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
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

    location /antares {
        alias $antares_root;
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
    
    # Configuración para el panel de administración de Django
    location /admin {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        #auth_basic "Admin Login";
        #auth_basic_user_file /etc/nginx/pma_pass;
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
    location /phpmyadmin {
        root /usr/share/;
        index index.php;
        access_log off;
        error_log off;
        #auth_basic "Admin Login";
        #auth_basic_user_file /etc/nginx/pma_pass;    
        try_files \$uri \$uri/ /index.php;
    }

    location ~ ^/phpmyadmin/(.+\.php)$ {
        try_files \$uri /index.php;
        root /usr/share/;
        fastcgi_pass unix:/run/php/php$version_number-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
    }

    location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
        root /usr/share/;
    }

    location ~ ^/(doc|sql|setup)/ {
        deny all;
    }

    location /postfixadmin {
        alias $HTML_PATH/postfixadmin/public;
        index index.php;
        access_log off;
        error_log off;
        #auth_basic "Admin Login";
        #auth_basic_user_file /etc/nginx/pma_pass;    
        try_files \$uri \$uri/ postfixadmin/index.php;
    
        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$request_filename;
            fastcgi_pass unix:/var/run/php/php$version_number-fpm.sock;
        }

        location ~ /\.ht {
            deny all;
        }
    }

    listen 443 ssl;
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/server-cert.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    if ($host = $ip_address) {
        return 301 https://$host/home;
    }

    listen 80;
    server_name $ip_address;
    return 404; 

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
    get_ip
    uninstall_apache2
    restart_nginx
    get_php_fpm_version
    create_pma_pass
    create_nginx_configs
    test_config
    webset
    configure_nextcloud
    echo "**********ALL DONE***********"
}
# Llamar a la función principal
nextcloud_config
