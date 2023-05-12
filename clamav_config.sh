#!/bin/bash
# clamav_config.sh
function update_virus_db {
  echo "Actualizando base de datos de virus..."
  if sudo freshclam; then
    echo "Base de datos de virus actualizada correctamente."
  else
    echo "Error al actualizar la base de datos de virus." >&2
    exit 1
  fi
}

function backup_config {
  echo "Creando copia de seguridad de la configuración de ClamAV..."
  if sudo cp /etc/clamav/clamd.conf /etc/clamav/clamd.conf.bak; then
    echo "Copia de seguridad creada correctamente."
  else
    echo "Error al crear copia de seguridad de la configuración de ClamAV." >&2
    exit 1
  fi
}

function configure_clamav {
  echo "Configurando ClamAV..."
  if sudo sed -i 's/#TCPSocket/TCPSocket/g' /etc/clamav/clamd.conf && \
     sudo sed -i 's/#TCPAddr/TCPAddr/g' /etc/clamav/clamd.conf && \
     sudo sed -i 's/#Foreground/Foreground/g' /etc/clamav/clamd.conf && \
     sudo sed -i 's/#LogFile/LogFile/g' /etc/clamav/clamd.conf; then
    echo "ClamAV configurado correctamente."
  else
    echo "Error al configurar ClamAV." >&2
    exit 1
  fi
}

function restart_clamav {
  echo "Reiniciando servicio de ClamAV..."
  if sudo service clamav-daemon restart; then
    echo "Servicio de ClamAV reiniciado correctamente."
  else
    echo "Error al reiniciar servicio de ClamAV." >&2
    exit 1
  fi
}

function install_and_configure_clamav {
  echo "**********CLAMAV CONFIG***********"
  update_packages
  install_clamav
  update_virus_db
  backup_config
  configure_clamav
  restart_clamav
  echo "**************ALL DONE***************"
}

install_and_configure_clamav
