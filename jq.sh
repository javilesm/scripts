#!/bin/bash

# Verificar si se ejecuta el script como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ser ejecutado como root" 
   exit 1
fi

# Actualizar el sistema
apt update

# Instalar Curl
apt install -y curl

# Instalar JQ
apt install -y jq

# Imprimir mensaje de instalación exitosa
echo "Curl y JQ han sido instalados exitosamente."

# Salir del script
exit 0
