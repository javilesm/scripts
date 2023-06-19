#! /bin/bash
# add_repositories.sh
# Variables
REPO_FILE="repositories.txt"
CURRENT_PATH="$( cd "$( dirname "${0}" )" && pwd )" # Obtener el directorio actual
REPO_PATH="$CURRENT_PATH/$REPO_FILE"
# Función principal
function add_repositories() {
    if [[ ! -f "$REPO_PATH" ]]; then
        echo "ERROR: El archivo '$REPO_FILE' no existe."
        exit 1
    fi
    
    echo "Agregando repositorios..."
    local count=0
    local errors=0

    while read -r repository; do
        if [[ -z "$repository" ]]; then
            echo "ADVERTENCIA: Repositorio vacío. Saltando..."
            continue
        fi

        ((count++))
        echo "Agregando el repositorio: '$repository'"
        
        if ! yes '' | sudo add-apt-repository -y "$repository"; then
            echo "ERROR: No se pudo agregar el repositorio '$repository'"
            ((errors++))
            if ! yes '' | sudo add-apt-repository -r "$repository"; then
                echo "ERROR: No se pudo eliminar el repositorio '$repository'"
                exit 1
            fi
        fi
    done < "$REPO_PATH"
    
    echo "------------------------"
    echo "Resumen de operación:"
    echo "------------------------"
    echo "Repositorios procesados: $count"
    echo "Repositorios con errores: $errors"
    
    if [[ $errors -eq 0 ]]; then
        echo "Todos los repositorios fueron agregados correctamente."
    else
        echo "Se produjeron errores durante la operación."
    fi
}

# Llamar a la función principal
add_repositories
