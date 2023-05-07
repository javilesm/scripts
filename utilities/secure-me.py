import os
import hashlib
import random
from Crypto.Random import get_random_bytes
from random import choice
import string

def generate_password(length):
    special_chars = "!:/\#$%&()*+<=>?@[\\]^_{|}~"
    other_chars = string.ascii_letters + string.digits
    password = ''.join([random.choice(special_chars + other_chars.replace(",", "")) for i in range(length)])
    return password

# Solicitar el nombre de usuario, el motor de base de datos, la base de datos y el host deseado para cada usuario
username = input("Ingrese el nombre de usuario: ")
db_engine = input("Ingrese el motor de base de datos deseado (1 para MySQL, 2 para PostgreSQL, 3 para otro motor): ")
if db_engine == "1":
    db_engine_str = "MySQL"
    users_file = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "scripts", "MySQL", "mysql_users.csv")
elif db_engine == "2":
    db_engine_str = "PostgreSQL"
    users_file = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "scripts", "PostgreSQL", "postgresql_users.csv")
else:
    db_engine_str = input("Ingrese el nombre del motor de base de datos: ")
    users_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), f"{db_engine_str}_users.csv")
database = input("Ingrese el nombre de la base de datos: ")
host = input("Ingrese el host deseado (presione Enter para usar 'localhost'): ") or 'localhost'
privilege = input("Ingrese el privilegio deseado (presione Enter para usar 'ALL PRIVILEGES'): ") or 'ALL PRIVILEGES'


# Generar una contraseña aleatoria
password_length = 64
password = generate_password(password_length)

# Codificar la contraseña en UTF-8 para convertirla en bytes
password_bytes = password.encode('utf-8')

# Crear un objeto de hash SHA-256
sha256 = hashlib.sha256()

# Calcular el hash de la contraseña
sha256.update(password_bytes)

# Obtener el valor hexadecimal del hash
password_hash = sha256.hexdigest()

# Guardar el nombre de usuario, la contraseña, el motor de base de datos, la base de datos, el host y el privilegio en un archivo csv
with open(users_file, "a") as f:
    f.write("{},{},{},{},{}\n".format(username, password, host, database, privilege))

# Imprimir un mensaje de confirmación
print("El nombre de usuario y la información de la base de datos se han almacenado en el archivo '{}'.".format(users_file))

# Crear un archivo de texto para el usuario
# Crear el subdirectorio "credentials" si no existe
credentials_dir = os.path.join(os.path.expanduser("~"), "credentials")
os.makedirs(credentials_dir, exist_ok=True)

# Crear un archivo de texto para el usuario dentro del subdirectorio "credentials"
user_dir = os.path.join(credentials_dir, username)
os.makedirs(user_dir, exist_ok=True)
user_file = os.path.join(user_dir, "{}.txt".format(username))

with open(user_file, "w") as f:
    f.write("Nombre de usuario: {}\n".format(username))
    f.write("Contraseña: {}\n".format(password))
    f.write("Motor de base de datos: {}\n".format(db_engine_str))
    f.write("Base de datos: {}\n".format(database))
    f.write("Host: {}\n".format(host))
    f.write("Privilegio: {}\n".format(privilege))

# Imprimir un mensaje de confirmación
print("El archivo de texto para el usuario '{}' se ha creado en el directorio: {}".format(username, user_file))

