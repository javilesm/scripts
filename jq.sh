#!/bin/bash
# SCRIPT PARA INSTALAR JQ
# Verificar si se ejecuta el script como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ser ejecutado como root" 
   exit 1
fi

# Actualizar el sistema
apt update

# Instalar JQ
apt install -y jq

# Imprimir mensaje de instalación exitosa
echo "JQ ha sido instalado exitosamente."

# Salir del script
exit 0
