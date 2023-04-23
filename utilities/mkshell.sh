#!/bin/bash
# mkshell.sh
echo "Script para generar scripts"

# Verifica si el directorio "/home/ubuntu/scripts" existe
if [ ! -d "/home/ubuntu/scripts" ]; then
  echo "El directorio /home/ubuntu/scripts no existe. Creándolo..."
  mkdir -p /home/ubuntu/scripts
fi

# Solicita el nombre del nuevo script a crear
echo "Ingresa el nombre del nuevo script sin extension:"
read script_name

# Verifica si el archivo ya existe
if [ -e "/home/ubuntu/scripts/$script_name" ]; then
  echo "El archivo ya existe. Por favor, elige otro nombre para el script."
else
  # Crea el nuevo archivo de script
  touch "/home/ubuntu/scripts/$script_name"
  echo "El archivo $script_name ha sido creado exitosamente en /home/ubuntu/scripts."
  # Añade un shebang y permisos de ejecución al nuevo script
  echo "#!/bin/bash" >> "/home/ubuntu/scripts/$script_name"
  chown -R $USER:$USER /home/ubuntu/scripts
  chmod +x /home/ubuntu/scripts/$script_name
  source ~/.bashrc
  # Edita el nuevo archivo de script
  echo "Abriendo el archivo en el editor de texto predeterminado del sistema en..."
  sleep 1
  echo "5..."
  sleep 1
  echo "4..."
  sleep 1
  echo "3..."
  sleep 1
  echo "2..."
  sleep 1
  echo "1..."
  sleep 1
  nano "/home/ubuntu/scripts/$script_name"
  echo "El archivo $script_name ha sido editado exitosamente."
fi
