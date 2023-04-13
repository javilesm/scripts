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

# Copiar todo el contenido del directorio de origen al directorio de destino
cp -rf $git_path* $path
echo "¡Clonado/Actualizado exitosamente!"

# Eliminar la extensión ".sh" de los archivos copiados
find "$path" -type f -name "*.sh" -exec mv {} $(dirname {})/$(basename {} .sh) \;

# Asignar permisos de ejecución a cada archivo copiado
find "$path" -type f -exec chmod +x {} +

# Crear enlaces simbólicos en /usr/local/bin/
for script in $path*; do
  if [ -f "$script" ]; then
    ln -sf "$script" "/usr/local/bin/$(basename "$script")"
  fi
done

# Actualiza la sesión de tu terminal ejecutando source en el archivo de perfil de shell 
source ~/.bashrc

echo "El contenido del directorio $git_path se ha copiado correctamente a $path con permisos de ejecución."
exit 0
