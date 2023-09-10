#!/bin/bash
# clone_repo.sh

# Variables
API_URL="https://api.github.com" # API para autenticación en GitHub
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
GitHubRepoURL="https://github.com/javilesm/www.git"
RepositoryDir="/var/www"
CREDENTIALS_FILE="git_credentials.txt"
CREDENTIALS_PATH="$CURRENT_DIR/$CREDENTIALS_FILE" # Directorio del archivo git_credentials.txt
REPOSITORY="www" # Respositorio Github a clonar
SCRIPT_DIR="/var/$REPOSITORY" # Directorio final
# Función para leer credenciales desde archivo de texto
function read_credentials() {
  echo "Leyendo credenciales..."
if [ -f "$CREDENTIALS_PATH" ]; then
    source "$CREDENTIALS_PATH"
    username=${username%%[[:space:]]}  # Eliminar espacios en blanco finales
    token=${token##+[[:space:]]}       # Eliminar espacios en blanco iniciales
    export git="https://${username}:${token}@github.com/${username}/${REPOSITORY}.git"
    echo "***Credenciales de acceso***"
    echo "--> username: $username"
    echo "--> token: ${token:0:3}*********"
    echo "--> URL: $git"
else
    echo "El archivo '$CREDENTIALS_FILE' no existe en la ubicación '$CREDENTIALS_PATH'. Por favor, cree el archivo con las variables username y token, y vuelva a intentarlo."
    exit 1
fi 
}

# Función para verificar si el directorio de destino ya existe y clonar/actualizar Git
function check_directory() {
    echo "Verificando si el directorio de destino ya existe..."
  if [ -d "$SCRIPT_DIR" ]; then
      echo "El directorio de destino ya existe. Realizando actualización..."
      update_git
  else
      echo "El directorio de destino no existe."
      clone_repository
  fi
}

# Función para clonar repositorios
function clone_repository() {
  echo "Creando directorio '$SCRIPT_DIR'..."
  sudo mkdir -p "$SCRIPT_DIR"
  echo "Clonando '$git' en '$SCRIPT_DIR'..."
  if git clone "$git" "$SCRIPT_DIR"; then
      echo "¡Clonado exitoso!"
      ls "$SCRIPT_DIR"
  else
      echo "Error al clonar el repositorio."
      exit 0
  fi
}

# Función para actualizar repositorios
function update_git () {
    cd "$SCRIPT_DIR"
    if response=$(curl -s -H "Authorization: token $token" "$API_URL/$username"); then
        echo "¡Inicio de sesión exitoso en GitHub!"
        echo "Actualizando '$SCRIPT_DIR' desde '$git'..."
        if git pull "$git"; then
            echo "Actualización exitosa."
            ls "$SCRIPT_DIR"
        else
            echo "Error al actualizar el repositorio. Por favor, verifique su conexión a Internet e inténtelo de nuevo."
            exit 1
        fi
    else
        echo "Error al iniciar sesión en GitHub. Por favor, verifica tu token de acceso."
        exit 1
    fi
}

function clone_repo() {
    echo "**********CLONE REPO***********"
    read_credentials
    check_directory
    echo "**************ALL DONE***************"
}

# Llamar a la funcion principal
clone_repo
