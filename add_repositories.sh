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
        echo "Agregando el repositorio: '$repository'"
        if ! yes '' | sudo add-apt-repository -y "$repository"; then
            echo "ERROR: No se pudo agregar el repositorio '$repository'"
            if ! yes '' | sudo add-apt-repository -r "$repository"; then
                echo "ERROR: No se pudo agregar el repositorio '$repository'"
                exit 1
            fi
        fi
    done < "$REPO_PATH"
    echo "Todos los repositorios fueron agregados."
}
# Lllamar a la función principal
add_repositories
