import subprocess
import os

script_file = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "scripts", "utilities", "secure-me.py")

# Crear un diccionario con las opciones predefinidas
preloaded_data = {
    "db_engine_option": "1",
    "privilege_option": "0"
}

# Ejecutar el script utilizando subprocess y pasar los datos predefinidos como argumentos
subprocess.call(["python", script_file, preloaded_data["db_engine_option"], preloaded_data["privilege_option"]])
