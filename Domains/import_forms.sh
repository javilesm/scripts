#!/bin/bash
# import_forms.sh
# Variables
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)" # Obtener el directorio actual
PARENT_DIR="$(dirname "$CURRENT_DIR")" # Obtener el directorio padre del directorio actual
CSV_MASTER_FILE="domains.csv"
CSV_MASTER_PATH="$CURRENT_DIR/$CSV_MASTER_FILE"
END_POINT="$CURRENT_DIR/forms"
LOG_FILE="$CURRENT_DIR/imported_forms.log"

# Función para verificar si un formulario ya ha sido procesado
function is_form_imported() {
    local form_id=$1
    if grep -q "$form_id" "$LOG_FILE"; then
        return 0 # El formulario ya ha sido procesado
    else
        return 1 # El formulario no ha sido procesado
    fi
}

# Función para agregar un formulario al registro de formularios procesados
function add_form_to_log() {
    local form_id=$1
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp: $form_id" >> "$LOG_FILE"
}

# Función principal
function import_forms() {
    echo "***************IMPORT FORMS***************"

    # Verificar si el archivo CSV maestro ya existe, si no, crearlo con el encabezado
    if [ ! -f "$CSV_MASTER_PATH" ]; then
        echo "Form ID,Nombre,Correo,Telefono" > "$CSV_MASTER_PATH"
    fi

    # Iterar sobre los archivos de formulario
    for file in "$END_POINT"/*; do
        if [ -f "$file" ]; then
            # Extraer el ID del formulario del nombre del archivo
            form_id=$(basename "$file" .csv)

            # Verificar si el formulario ya ha sido procesado
            if is_form_imported "$form_id"; then
                echo "El formulario $form_id ya ha sido importado. Saltando..."
            else
                # Agregar el formulario al archivo CSV maestro como una nueva línea completa
                cat "$file" >> "$CSV_MASTER_PATH"
                echo "" >> "$CSV_MASTER_PATH" # Asegurar una nueva línea después de cada formulario
                echo "Formulario $form_id importado con éxito."
                # Agregar el formulario al registro de formularios procesados con timestamp
                add_form_to_log "$form_id"
            fi
        fi
    done

    echo "***************ALL DONE***************"
}

# Llamar a la función principal
import_forms
