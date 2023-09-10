#!/bin/bash
# push_repo.sh

# Variables
GitHubRepoURL="https://github.com/javilesm/www.git"
RepositoryDir="/var/www"  # Reemplaza con la ruta correcta

function change_directory() {
    # Cambia al directorio local donde tienes tu repositorio Git
    cd "$RepositoryDir"
}

function configure_remote_url() {
    # Configura la URL del repositorio remoto
    sudo git remote set-url origin "$GitHubRepoURL"
}

function add_changes_to_staging() {
    # Asegúrate de haber agregado los cambios a la zona de preparación (staging)
    sudo git add .
}

function commit_changes() {
    # Realiza un commit con un mensaje
    sudo git commit -m "Mensaje de commit"
}

function push_to_github() {
    # Realiza el push al repositorio remoto en GitHub
    sudo git push origin main
}

function check_status() {
    # Verifica el estado después del push (opcional)
    sudo git status
}

function push_repo() {
    change_directory
    configure_remote_url
    add_changes_to_staging
    commit_changes
    push_to_github
    check_status
}

# Llama a la función principal
push_repo
