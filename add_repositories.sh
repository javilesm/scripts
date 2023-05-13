#! /bin/bash

# Variables
REPO_FILE="repositories.txt"
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
REPO_PATH="$CURRENT_PATH/$REPO_FILE"

# Función principal
function add_repositories() {
    echo "Agregando repositorios..."
    while read -r repository; do
        echo "Verificando si el repositorio '$repository' ya está agregado..."
        if ! grep -q "^deb .*$repository" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
            echo "El repositorio '$repository' no está agregado. Agregando..."
            if ! yes '' | sudo add-apt-repository -r "$repository"; then
                echo "ERROR: No se pudo agregar el repositorio '$repository' con la opción '-r'. Intentando con la opción '-y'..."
                if ! yes '' | sudo add-apt-repository -y "$repository"; then
                    echo "ERROR: No se pudo agregar el repositorio '$repository'. Saltando a la siguiente entrada."
                    continue
                fi
            fi
        else
            echo "El repositorio '$repository' ya está agregado. Saltando a la siguiente entrada."
        fi
    done < "$REPO_PATH"
    echo "Todos los repositorios fueron agregados."
}

# Lllamar a la función principal
add_repositories

