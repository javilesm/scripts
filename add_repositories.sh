#! /bin/bash
# add_repositories.sh
# Variables
REPO_FILE="repositories.txt"
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
REPO_PATH="$CURRENT_PATH/$REPO_FILE"
# Función principal
function add_repositories() {
    echo "Agregando repositorios..."
    while read -r repository; do
        if ! yes '' | sudo add-apt-repository -y "$repository"; then
            echo "No se pudo agregar el repositorio: $repository"
            exit 1
        fi
    done < "$REPO_PATH"
}
# Lllamar a la función principal
add_repositories
