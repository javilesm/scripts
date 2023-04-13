#!/bin/bash
# getscripts

# Variables de autenticación de GitHub
username="javilesm" # usuario
path="/home/ubuntu/scripts/" # Directorio final
git_path="/home/ubuntu/git/" # Directorio de destino para clonar el repositorio
git_url="https://github.com/$username/scripts.git" # URL del repositorio a clonar con credenciales de autenticación

# Verificar si el directorio de destino ya existe
if [ -d $git_path ]; then
  echo "El directorio de destino ya existe. Realizando actualización..."
  cd $git_path
  git pull $git_url
else
  echo "Clonando el repositorio..."
  git clone $git_url $git_path
fi

echo "¡Clonado/Actualizado exitosamente!"

# Copiar todo el contenido del directorio de origen al directorio de destino
cp -rf $git_path* $path

# Asignar permisos de ejecución a cada archivo copiado
find "$path" -type f -exec chmod +x {} +

# Eliminar la extensión ".sh" de los archivos copiados
find "$path/" -name "*.sh" -type f -exec bash -c 'mv "$1" "${1%.sh}"' _ {} \;

echo "El contenido del directorio $git_path se ha copiado correctamente a $path con permisos de ejecución."
exit 0