#!/bin/bash
# postgresql_create_role.sh
# Variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROLES_FILE="postgresql_roles.csv"
ROLES_PATH="$SCRIPT_DIR/$ROLES_FILE"
# Función para validar la existencia del archivo de roles
function check_roles_file() {
    echo "Validando la existencia del archivo de roles..."
    if [ ! -f "$ROLES_PATH" ]; then
        echo "El archivo '$ROLES_FILE' no existe"
        exit 1
    fi
    echo "El archivo '$ROLES_FILE' existe"
}

# Función para crear roles de usuario en PostgreSQL
function create_roles() {
    echo "Creando roles de usuario en PostgreSQL desde $ROLES_PATH ..."
    # Leer la lista de roles de usuario desde el archivo postgresql_roles.csv
    while IFS=, read -r rolename password; do
        # Crear el rol de usuario
        echo "Creando el rol '$rolename'..."
        if ! sudo -u postgres psql -c "CREATE ROLE $rolename LOGIN PASSWORD '$password';"; then
            echo "Error al crear el rol '$rolename'."
            exit 1
        fi
        echo "El rol '$rolename' ha sido creado exitosamente."
        # Verificar que el rol de usuario se ha creado correctamente
        echo "Verificando que el rol de usuario '$rolename' se haya creado correctamente..."
        if ! sudo -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname='$rolename'" | grep -q 1; then
            echo "No se ha podido crear el rol de usuario '$rolename'."
            exit 1
        fi
        echo "El rol '$rolename' ha sido verificado exitosamente."
    done < <(sed -e '$a\' "$ROLES_PATH")
    echo "Todas los roles en '$ROLES_FILE' fueron creados."
}
# Función para mostrar todos los roles
function show_roles() {
    echo "Mostrando todos los roles en PostgreSQL..."
    sudo -u postgres psql -c "\du"
}
# Función principal
function postgresql_create_role() {
    echo "**********POSTGRESQL CREATE ROLE**********"
    check_roles_file
    create_roles
    show_roles
    echo "**************ALL DONE**************"
}
# Llamar a la función principal
postgresql_create_role
