#!/bin/bash
# push_repo.sh

# Variables
API_URL="https://api.github.com" # API para autenticación en GitHub
CURRENT_DIR="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
PARENT_DIR="$( dirname "$CURRENT_DIR" )" # Get the parent directory of the current directory
GRAND_PARENT_DIR="$( dirname "$PARENT_DIR" )" # Get the parent directory of the parent directory of the current directory
GREATE_GRAND_PARENT_DIR="$( dirname "$GRAND_PARENT_DIR" )" # Get the parent directory of the parent directory of the parent directory of the current directory
GitHubRepoURL="https://github.com/javilesm/www.git"
CREDENTIALS_FILE="git_credentials.txt"
CREDENTIALS_PATH="$GRAND_PARENT_DIR/$CREDENTIALS_FILE" # Directorio del archivo git_credentials.txt
REPOSITORY="www" # Respositorio Github a clonar
SCRIPT_DIR="/var/$REPOSITORY" # Directorio final
spacer="-------------------------------------------------------------------------------"
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

function change_directory() {
    # Cambia al directorio local donde tienes tu repositorio Git
    echo "Cambiando al directorio local donde tienes tu repositorio Git: '$SCRIPT_DIR'..."
    cd "$SCRIPT_DIR"
}

function configure_remote_url() {
    # Configura la URL del repositorio remoto
    echo "Configurando la URL del repositorio remoto..."
    sudo git remote set-url origin "$git"
}

function add_changes_to_staging() {
    # Asegúrate de haber agregado los cambios a la zona de preparación (staging)
    echo "Asegúrandose de haber agregado los cambios a la zona de preparación (staging)..."
    sudo git add .
}

function commit_changes() {
    # Realiza un commit con un mensaje
    echo "Realiza un commit con un mensaje..."
    sudo git commit -m "Mensaje de commit"
}

function push_to_github() {
    # Realiza el push al repositorio remoto en GitHub
    echo "Realizando el push al repositorio remoto en GitHub..."
    sudo git push origin main
}

function check_status() {
    # Verifica el estado después del push (opcional)
    echo "Verificando el estado después del push..."
    sudo git status
}

function push_repo() {
    echo "**********PUSH REPO***********"
    read_credentials
    echo "$spacer"
    change_directory
    echo "$spacer"
    configure_remote_url
    echo "$spacer"
    add_changes_to_staging
    echo "$spacer"
    commit_changes
    echo "$spacer"
    push_to_github
    echo "$spacer"
    check_status
    echo "**************ALL DONE***************"
}

# Llama a la función principal
push_repo
