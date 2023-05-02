#!/bin/bash
# nextcloud_config.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
CONFIG_FILE="nextcloud_nginx.conf"
CONFIG_PATH="$CURRENT_PATH/$NGINX_CONFIG_FILE"
DOMAIN="localhost"
NGINX_NEXTCLOUD_CONFIG="/etc/nginx/sites-available/nextcloud"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled/"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available/"
# Funcion para remover el archivo de configuracion
function remove_default_config() {
  # remover el archivo de configuracion
  echo "Removiendo archivo de configuracion..."
  sudo rm "$NGINX_SITES_ENABLED/default"
}
# Funcion para configurar Nginx
function configure_nginx() {
  echo "Configurando NGINX..."
  if ! sudo touch "$NGINX_NEXTCLOUD_CONFIG"; then
    echo "Error: No se pudo crear el archivo de configuración de NGINX."
    return 1
  fi

  if ! sudo ln -s "$NGINX_NEXTCLOUD_CONFIG" "$NGINX_SITES_ENABLED"; then
    echo "Error: No se pudo crear el enlace simbólico para el archivo de configuración de NGINX."
    return 1
  fi

  if ! sudo tee "$NGINX_NEXTCLOUD_CONFIG" >/dev/null <<EOF
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
  then
    echo "Error: No se pudo escribir la configuración de NGINX en el archivo."
    return 1
  fi

  if ! sudo nginx -t; then
    echo "Error: La configuración de NGINX es inválida."
    return 1
  fi

  if ! sudo systemctl reload nginx; then
    echo "Error: No se pudo recargar la configuración de NGINX."
    return 1
  fi

  echo "Configuración de NGINX exitosa."
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
# Función para reiniciar servicios
function restart_services() {
  echo "Reiniciando servicios..."
  if ! sudo systemctl restart nginx; then
    echo "Error al reiniciar el servicio nginx."
    return 1
  fi
  if ! sudo systemctl reload snap.nextcloud.nginx; then
    echo "Error al recargar el servicio de Nextcloud."
    return 1
  fi
  echo "Servicios reiniciados correctamente."
  return 0
}
# Función principal
function nextcloud_config() {
  echo "**********NEXTCLOUD CONFIGURATOR***********"
  configure_nginx
  configure_nextcloud
  restart_services
  echo "**********ALL DONE***********"
}
# Llamar a la función principal
nextcloud_config
