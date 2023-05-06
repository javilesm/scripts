import os
import hashlib
from Crypto.Random import get_random_bytes
from random import choice
import string

def generate_password(length):
    # Definir los caracteres especiales permitidos
    special_chars = string.punctuation.replace(",", "")
    
    # Definir los demás caracteres permitidos
    other_chars = string.ascii_letters + string.digits
    
    # Generar una cantidad de bytes igual a la mitad de la longitud deseada
    num_bytes = (length + 1) // 2
    rand_bytes = get_random_bytes(num_bytes)

    # Seleccionar caracteres aleatorios de ambas listas y combinarlos en una sola cadena
    password = ''.join([choice(special_chars + other_chars) for i in range(length)])
    return password

# Obtener la ruta del archivo usuarios.csv
current_dir = os.path.dirname(os.path.abspath(__file__))
users_file = os.path.join(current_dir, "users.csv")

# Solicitar el nombre de usuario, el motor de base de datos, la base de datos y el host deseado para cada usuario
username = input("Ingrese el nombre de usuario: ")
db_engine = input("Ingrese el motor de base de datos deseado (1 para MySQL, cualquier otro valor para PostgreSQL): ")
database = input("Ingrese el nombre de la base de datos: ")
host = input("Ingrese el host deseado (presione Enter para usar 'localhost'): ") or 'localhost'
privilege = input("Ingrese el privilegio deseado (presione Enter para usar 'ALL PRIVILEGES'): ") or 'ALL PRIVILEGES'

# Establecer el motor de base de datos
if db_engine == "1":
    db_engine_str = "MySQL"
else:
    db_engine_str = "PostgreSQL"

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
    f.write("{},{},{},{},{},{}\n".format(username, password, db_engine_str, host, database, privilege))

# Imprimir un mensaje de confirmación
print("El nombre de usuario y la información de la base de datos se han almacenado en el archivo 'usuarios.csv'.")

# Crear un archivo de texto para el usuario
user_file = os.path.join(current_dir, "{}.txt".format(username))
with open(user_file, "w") as f:
    f.write("Nombre de usuario: {}\n".format(username))
    f.write("Contraseña: {}\n".format(password))
    f.write("Motor de base de datos: {}\n".format(db_engine_str))
    f.write("Base de datos: {}\n".format(database))
    f.write("Host: {}\n".format(host))
    f.write("Privilegio: {}\n".format(privilege))

# Imprimir un mensaje de confirmación
print("El archivo de texto para el usuario '{}' se ha creado en el directorio actual.".format(username))
