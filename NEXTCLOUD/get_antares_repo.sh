#!/bin/bash
# get_antares_repo.sh
# Variables
API_URL="https://api.github.com" # API para autenticación en GitHub
GITHUB_ORGANIZATION="TCS2211194M1"
REPOSITORY="Antares_project" # Respositorio Github a clonar
REPOSITORY_PATH="$GITHUB_ORGANIZATION/$REPOSITORY"
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
WEB_DIR="var/www/samava-cloud"
CREDENTIALS_FILE="git_credentials.txt"
CREDENTIALS_PATH="$PARENT_DIR/$CREDENTIALS_FILE" # Directorio del archivo git_credentials.txt
REPOSITORY_ENDPOINT="$WEB_DIR/$REPOSITORY" # Directorio final

# Función para leer credenciales desde archivo de texto
function read_credentials() {
  echo "Leyendo cedenciales..."
    if [ -f "$CREDENTIALS_PATH" ]; then
        source "$CREDENTIALS_PATH"
        username=${username%%[[:space:]]}  # Eliminar espacios en blanco finales
        token=${token##+[[:space:]]}       # Eliminar espacios en blanco iniciales
        export git="https://${username}:${token}@github.com/${username}/${REPOSITORY}.git"
        echo "***Credenciales de acceso***"
        echo "username: $username"
        echo "token: ${token:0:3}*********"
        echo "URL: $git"
    else
        echo "El archivo '$CREDENTIALS_FILE' no existe en la ubicación '$CREDENTIALS_PATH'. Por favor, cree el archivo con las variables username y token, y vuelva a intentarlo."
    fi 
}

# Función para verificar si el directorio de destino ya existe y clonar/actualizar Git
function check_directory() {
    echo "Verificando si el directorio de destino '$REPOSITORY_ENDPOINT' ya existe..."
  if [ -d "$REPOSITORY_ENDPOINT" ]; then
      echo "El directorio de destino '$REPOSITORY_ENDPOINT' ya existe. Realizando actualización..."
      update_git
  else
      echo "El directorio de destino '$REPOSITORY_ENDPOINT' no existe."
      clone_repository
  fi
}
# Función para clonar repositorios
function clone_repository() {
  echo "Creando directorio '$REPOSITORY_ENDPOINT'..."
  sudo mkdir "$REPOSITORY_ENDPOINT"
  echo "Clonando '$REPOSITORY_PATH' en '$REPOSITORY_ENDPOINT'..."
  if git clone "$REPOSITORY_PATH" "$REPOSITORY_ENDPOINT"; then
      echo "¡Clonado exitoso!"
  else
      echo "Error al clonar el repositorio '$REPOSITORY_PATH'."
      exit 0
  fi
}
# Función para actualizar repositorios
function update_git () {
    cd "$REPOSITORY_ENDPOINT"
    if response=$(curl -s -H "Authorization: token $token" "$API_URL/$username"); then
        echo "¡Inicio de sesión exitoso en GitHub!"
        echo "Actualizando '$REPOSITORY_ENDPOINT' desde '$REPOSITORY_PATH'..."
        if git pull "$REPOSITORY_PATH"; then
            echo "Actualización exitosa."
        else
            echo "Error al actualizar el repositorio. Por favor, verifique su conexión a Internet e inténtelo de nuevo."
            exit 1
        fi
    else
        echo "Error al iniciar sesión en GitHub. Por favor, verifica tu token de acceso."
        exit 1
    fi
}
# Función para actualizar la propiedad del directorio de destino y su contenido
function update_dir_ownership () {
    echo "Actualizando la propiedad del directorio '$REPOSITORY_ENDPOINT' y su contenido..."
    if ! sudo chown -R "$USER:$USER" "$REPOSITORY_ENDPOINT"/*; then
        echo "No se pudo actualizar la propiedad del directorio '$REPOSITORY_ENDPOINT' y su contenido. Por favor, revise los permisos del directorio y vuelva a intentarlo."
    fi
    echo "La propiedad del directorio '$REPOSITORY_ENDPOINT' y su contenido fueron actualizados para '$USER'."
}

# Función principal
function get_antares_repo() {
    echo "**********GET ANTARES REPO***********"
    read_credentials
    check_directory
    update_dir_ownership
    echo "**************ALL DONE***************"
}
# Llamar a la función principal
get_antares_repo
