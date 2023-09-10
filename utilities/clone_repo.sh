#!/bin/bash
# clone_repo.sh

# Variables
GitHubRepoURL="https://github.com/javilesm/www.git"
RepositoryDir="/var/www"

# Función para clonar o actualizar un repositorio de GitHub
function clonar_o_actualizar_repositorio() {
    local GitHubRepoURL="$1"
    local RepositoryDir="$2"

    # Comprobar si el directorio existe
    if [ -d "$RepositoryDir" ]; then
        echo "El directorio $RepositoryDir ya existe. Realizando un pull."
        cd "$RepositoryDir"
        sudo git pull
    else
        # Crear el directorio si no existe
        sudo mkdir -p "$RepositoryDir"
        echo "Carpeta creada en el directorio $RepositoryDir."

        # Clonar el repositorio de GitHub
        sudo git clone "$GitHubRepoURL" "$RepositoryDir"
    fi

    echo "Proceso completado."
}

function clone_repo() {
    clonar_o_actualizar_repositorio "$GitHubRepoURL" "$RepositoryDir"
}

# Llamar a la funcion principal
clone_repo
