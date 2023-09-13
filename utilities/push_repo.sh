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
COMMIT_MESSAGE="Mensaje de commit"
GITIGNORE_FILE=".gitignore" # Archivo donde se almacenarán las rutas para .gitignore
GITIGNORE_PATH="$SCRIPT_DIR/$GITIGNORE_FILE"
LIMIT_LEVEL=3 # Variable de control para limitar la recursión
spacer="-------------------------------------------------------------------------------"

# Función para solucionar problemas de propiedad en el repositorio Git
function fix_git_ownership() {
    # Agregar una excepción para el directorio /var/www
    echo "Agregando una excepción para el directorio '$SCRIPT_DIR'..."
    git config --global --add safe.directory "$SCRIPT_DIR"

    # Verificar los permisos de archivos y directorios en /var/www
    echo "Verificando los permisos de archivos y directorios en '$SCRIPT_DIR'..."
    ls -l "$SCRIPT_DIR"

    # Ejecutar git fsck --full nuevamente
    echo "Ejecutando git fsck --full para verificar problemas de propiedad..."
    if git fsck --full; then
        echo "Problemas de propiedad resueltos."
    else
        echo "No se pudieron resolver los problemas de propiedad."
    fi
}

# Función para leer credenciales desde archivo de texto
function read_credentials() {
  echo "Leyendo credenciales..."
    if [ -f "$CREDENTIALS_PATH" ]; then
        source "$CREDENTIALS_PATH"
        export username=${username%%[[:space:]]}  # Eliminar espacios en blanco finales
        export token=${token##+[[:space:]]}       # Eliminar espacios en blanco iniciales
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

# Función para cambiar al directorio local donde tienes tu repositorio Git
function change_directory() {
    # Cambiar al directorio local donde tienes tu repositorio Git
    echo "Cambiando al directorio local donde tienes tu repositorio Git: '$SCRIPT_DIR'..."
    cd "$SCRIPT_DIR" && ls "$SCRIPT_DIR"
}
# Función para inicializar un nuevo repositorio Git si no existe
function initialize_repository() {
    # Inicializa un nuevo repositorio Git si no existe
    echo "Inicializando un nuevo repositorio Git si no existe..."
    if [ ! -d ".git" ]; then
        echo "Inicializando un nuevo repositorio Git en '$SCRIPT_DIR'..."
        sudo git init
    fi
}
# Función para configurar la URL del repositorio remoto
function configure_remote_url() {
    # Configurar la URL del repositorio remoto
    echo "Configurando la URL del repositorio remoto 'https://${username}:${token}@github.com/${username}/${REPOSITORY}.git'"
    sudo git remote add origin "https://${username}:${token}@github.com/${username}/${REPOSITORY}.git"
}
function pull_changes(){
    # pull changes
    echo "Realizando el push al repositorio remoto en GitHub..."
    if response=$(curl -s -H "Authorization: token $token" "$API_URL/$username"); then
        echo "¡Inicio de sesión exitoso en GitHub!"
        sudo git pull origin main
    else
        echo "Error al iniciar sesión en GitHub. Por favor, verifica tu token de acceso."
        exit 1
    fi
}
# Función para comprobar la existencia del archivo .gitignore y crearlo si no existe.
function check_gitignore() {
    # comprobar la existencia del archivo .gitignore y crearlo si no existe.
    echo "Comprobando la existencia del archivo $GITIGNORE_FILE y crearlo si no existe..."
    if [ ! -f "$GITIGNORE_PATH" ]; then
        git add "$GITIGNORE_PATH"
    fi
}
# Función para listar subdirectorios en el nivel 2 y sus subdirectorios de nivel 3
function list_level_2_and_3() {
    #echo "Subdirectorios en el nivel 2 y sus subdirectorios en el nivel 3:"
    
    for dir2 in */; do
        if [ -d "$dir2" ]; then
            if [ "$dir2" == "wp_template/" ]; then
                echo "!$(pwd)/$dir2*" && echo "!$(pwd)/$dir2*" >> "$GITIGNORE_PATH"
            else
                echo "#$(pwd)/$dir2" && echo "#$(pwd)/$dir2" >> "$GITIGNORE_PATH"
                
                # Llamar a la función para listar subdirectorios en el nivel 3
                list_level_3_in_level_2 "$dir2"
            fi
        fi
    done
}

# Función para listar subdirectorios en el nivel 3 de un directorio de nivel 2
function list_level_3_in_level_2() {
    local level_2_dir="$1"

    #echo "Subdirectorios en el nivel 3 de $level_2_dir:"
     cd "$level_2_dir"
    
    for dir3 in */; do
        if [ -d "$dir3" ]; then
            if [ "$dir3" == "html/" ]; then
                echo "#$(pwd)/$dir3" && echo "#$(pwd)/$dir3" >> "$GITIGNORE_PATH"
            else
                echo "!$(pwd)/$dir3*" && echo "!$(pwd)/$dir3*" >> "$GITIGNORE_PATH"
            fi
        fi
    done
    cd ..
}
# Función para
function add_changes_to_staging() {
    # Asegúrate de haber agregado los cambios a la zona de preparación (staging)
    echo "Asegúrandose de haber agregado los cambios a la zona de preparación (staging)..."
    sudo git add .
}
function tune_settings(){
    echo "Afinando ajustes..."
    sudo git config --global http.postBuffer 1048576000
    sudo git config --global http.lowSpeedLimit 0
    sudo git config --global http.lowSpeedTime 999999
}
# Función para
function commit_changes() {
    # Realiza un commit con un mensaje
    echo "Realiza un commit con un mensaje..."
    sudo git commit -m "$COMMIT_MESSAGE" 
}
# Función para realizar el push al repositorio remoto en GitHub
function push_to_github() {
    # Realizar el push al repositorio remoto en GitHub
    echo "Realizando el push al repositorio remoto en GitHub..."
    if response=$(curl -s -H "Authorization: token $token" "$API_URL/$username"); then
        echo "¡Inicio de sesión exitoso en GitHub!"
        sudo git push -u origin main -f
    else
        echo "Error al iniciar sesión en GitHub. Por favor, verifica tu token de acceso."
        exit 1
    fi
}
# Función para verificar el estado después del push (opcional)
function check_status() {
    # Verifica el estado después del push (opcional)
    echo "Verificando el estado después del push..."
    sudo git status
}
# Función para encontrar un repositorio Git interno en una ruta específica
function find_internal_git_repo() {
    # Obtén la ruta del directorio superior del repositorio Git actual
    top_level_dir="$(git rev-parse --show-toplevel)"

    # Variable para almacenar la ruta del directorio interno
    internal_repo_dir=""

    # Ejecuta 'git add .' y captura la salida en segundo plano, incluyendo las advertencias
    (git add . 2>&1) | while read -r line; do
        if [[ "$line" == *"warning: adding embedded git repository:"* ]]; then
            # Extrae la ruta del directorio interno de la advertencia
            internal_repo_dir=$(echo "$line" | sed -n 's/warning: adding embedded git repository: //p')
            break
        fi
    done

    # Si se encontró una advertencia, ajusta la ruta interna
    if [ -n "$internal_repo_dir" ]; then
        internal_repo_path="$top_level_dir/$internal_repo_dir"
        echo "Ruta interna ajustada según la advertencia: $internal_repo_path"

        # Ejecuta 'git rm --cached' en el directorio interno para dejar de rastrearlo
        git rm --cached "$internal_repo_path"

        # Verifica si el directorio existe y contiene un repositorio Git interno
        if [ -d "$internal_repo_path/.git" ]; then
            echo "Se encontró un repositorio Git interno en la siguiente ruta:"
            echo "$internal_repo_path"
        else
            echo "No se encontró ningún repositorio Git interno en la ruta especificada."
        fi
    else
        echo "No se encontraron advertencias relacionadas con repositorios Git internos."
    fi
}
# Función principal
function push_repo() {
    echo "**********PUSH REPO***********"
    read_credentials
    echo "$spacer"
    change_directory
    echo "$spacer"
    #fix_git_ownership
    echo "$spacer"
    #initialize_repository
    echo "$spacer"
    configure_remote_url
    echo "$spacer"
    tune_settings
    echo "$spacer"
    pull_changes
    echo "$spacer"
    check_gitignore
    echo "$spacer"
    list_level_2_and_3
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
# Llamar a la función principal
push_repo
