#! /bin/bash
# Instalar repositorios
echo "Instalando repositorios..."
yes '' | sudo add-apt-repository ppa:ondrej/php -qq
yes '' | sudo add-apt-repository ppa:ondrej/nginx -qq
sleep 5

# Actualizar todos los paquete
echo "Actualizando paquetes..."
sudo apt update -qq
sleep 5


# Instalar Tree
echo "Instalando Tree.."
sudo apt install tree -yqq
sleep 5

# Instalar ZIP
echo "Instalando ZIP..."
sudo apt-get install zip -yqq
sleep 5

# Instalar NGINX
echo "Instalando NGINX..."
sudo apt install nginx -yqq
sleep 5

# Instalar MySQL
echo "Instalando MySQL..."
sudo apt install mysql-server -yqq
sleep 5

# Instalar PHP
echo "Instalando PHP..."
sudo apt install php-fpm php-cli php-common php-mysql php-mcrypt php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip php-pear php-imagick php-imap php-tidy php-json php-bcmath php-apcu  -yqq

echo "Fin..."
