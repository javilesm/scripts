#!/bin/bash
# nextcloud_config.sh
# Variables
DOMAIN="localhost"
# Configurar Nginx
#!/bin/bash
function remove_default_config() {
  echo "Removiendo archivo de configuracion..."
  sudo rm /etc/nginx/sites-enabled/default
}
# Configurar Nginx
function configure_nginx() {
  echo "Configurando NGINX..."
  sudo touch /etc/nginx/sites-available/nextcloud
  sudo ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/
  sudo tee /etc/nginx/sites-available/nextcloud >/dev/null <<EOF
  server {
    listen 80;
    server_name '$DOMAIN';
    return 301 https://\$host\$request_uri;
  }

  server {
    listen 443 ssl http2;
    server_name '$DOMAIN';

    ssl_certificate /etc/letsencrypt/live/'$DOMAIN'/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/'$DOMAIN'/privkey.pem;

    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";

    location / {
      proxy_pass http://127.0.0.1:80;
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-Proto https;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Host \$server_name;
      proxy_set_header X-Forwarded-Port \$server_port;
      proxy_set_header X-Forwarded-Ssl on;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "Upgrade";
    }

    location = /robots.txt {
      allow all;
      log_not_found off;
      access_log off;
    }

    location ^~ /.well-known {
      allow all;
      log_not_found off;
      access_log off;
    }

    client_max_body_size 0;
  }
EOF
}
# Configurar MySQL
function configure_mysql() {
  echo "Configurando MySQL..."
  sudo mysql -u root -p -e "CREATE DATABASE nextcloud;
  GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost' IDENTIFIED BY 'tu-contraseña';
  FLUSH PRIVILEGES;"
}
# Configurar PHP
function configure_php() {
  echo "Configurando PHP..."
  php_version=$(php -v | head -n 1 | cut -d " " -f 2 | cut -f1-2 -d".")
  sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/$php_version/fpm/php.ini
  sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100G/" /etc/php/$php_version/fpm/php.ini
  sudo sed -i "s/post_max_size = .*/post_max_size = 100G/" /etc/php/$php_version/fpm/php.ini
  sudo sed -i "s/;date.timezone.*/date.timezone = America\/Mexico_City/" /etc/php/$php_version/fpm/php.ini
}
# Configurar NEXTCLOUD
function configure_nextcloud() {
  echo "Configurando Nextcloud..."
  sudo nextcloud.occ maintenance:install --database "mysql" --database-name "nextcloud" --database-user "nextcloud" --database-pass "tu-contraseña" --admin-user "tu-usuario-administrador" --admin-pass
}
# Reiniciar servicios
function system_restart() {
  sudo systemctl restart nginx
  sudo systemctl restart mysql
  sudo systemctl restart php$php_version-fpm
}
# Función principal
function nextcloud_config() {
  echo "**********NEXTCLOUD CONFIGURATOR***********"
  configure_nginx
  configure_mysql
  configure_php
  configure_nextcloud
  system_restart
  echo "**********ALL DONE***********"
}
# Llamar a la función principal
nextcloud_config
