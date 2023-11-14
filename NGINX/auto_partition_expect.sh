#!/usr/bin/expect -f

# Obtener el comando pasado como argumento
set partition_command [lrange $argv 1 end]

# Ejecutar el comando con sudo
spawn sudo {*}$partition_command

# Esperar a que el comando termine
expect eof
