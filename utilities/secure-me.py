import os
import hashlib
import random
from Crypto.Random import get_random_bytes
from random import choice
import string
# Funcion para generar contrasenas
def generate_password(length):
    special_chars = "!:/\#$%&()*+<=>?@[\\]^_{|}~"
    other_chars = string.ascii_letters + string.digits
    password = ''.join([random.choice(special_chars + other_chars.replace(",", "")) for i in range(length)])
    return password

def solicitar_datos_usuario():
    # Solicitar el nombre de usuario, el motor de base de datos, la base de datos y el host deseado para cada usuario
    engines = {
        "1": "MySQL",
        "2": "PostgreSQL",
        "3": "SQLite",
        "4": "Dovecot"
    }
    print("Seleccione el nombre de su motor:")
    username = input("Ingrese el nombre de usuario: ")
    for key, value in engines.items():
        print(f"{key}: {value}")
    db_engine_option = input("Ingrese el número de motor de base de datos deseado: ")
    db_engine = engines.get(db_engine_option, None)
    if db_engine is None:
        print("Opción de motor de base de datos inválida")
        exit()

    if db_engine == "MySQL":
        users_file = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "scripts", "MySQL", "mysql_users.csv")
        privileges = {
            0: "ALL PRIVILEGES",
            1: "CREATE",
            2: "DROP",
            3: "ALTER",
            4: "SELECT",
            5: "INSERT",
            6: "UPDATE",
            7: "DELETE",
            8: "PROCESS",
            9: "RELOAD",
            "A": "SHUTDOWN",
            "B": "USAGE",
            "C": "INDEX",
            "D": "FILE",
            "E": "SUPER",
            "F": "SHUTDOWN",
            "G": "EXECUTE"
        }
        print("Seleccione un privilegio:")
        for i, privilege in privileges.items():
            print(f"{i}: {privilege}")
        privilege_option = input("Ingrese el número de privilegio deseado: ")
        privilege = privileges.get(int(privilege_option), None)
        if privilege is None:
            print("Opción de privilegio inválida")
            exit()
    elif db_engine == "PostgreSQL":
        users_file = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "scripts", "PostgreSQL", "postgresql_users.csv")
        privileges = {
            0: "USAGE",
            1: "SELECT",
            2: "INSERT",
            3: "UPDATE",
            4: "DELETE",
            5: "TRUNCATE",
            6: "REFERENCES",
            7: "TRIGGER",
            8: "ALL",
            9: "CONNECT",
            "A": "TEMPORARY",
            "B": "EXECUTE",
            "C": "SET",
            "D": "ALTER SYSTEM",
        }
        print("Seleccione un privilegio:")
        for i, privilege in privileges.items():
            print(f"{i}: {privilege}")
        privilege_option = input("Ingrese el número de privilegio deseado: ")
        privilege = privileges.get(int(privilege_option), None)
        if privilege is None:
            print("Opción de privilegio inválida")
            exit()
    elif db_engine == "SQLite":
        users_file = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "scripts", "SQLite", "sqlite_users.csv")
        privileges = {
            0: "NONE",
            1: "READ",
            2: "INSERT",
            3: "UPDATE",
            4: "DELETE",
            5: "READWRITE",
            6: "PRAGMA",
            7: "CREATE_TABLE",
            8: "CREATE_INDEX",
            9: "CREATE_VIEW",
            "A": "CREATE_TRIGGER",
            "B": "DROP_ABLE",
            "C": "DROP_INDEX",
            "D": "DROP_VIEW",
            "E": "DROP_TRIGGER",
            "F": "ALTER_TABLE",
            "G": "ANALYZE"
        }
        print("Seleccione un privilegio:")
        for i, privilege in privileges.items():
            print(f"{i}: {privilege}")
        privilege_option = input("Ingrese el número de privilegio deseado: ")
        privilege = privileges.get(int(privilege_option), None)
        if privilege is None:
            print("Opción de privilegio inválida")
            exit()
    elif db_engine == "Dovecot":
        users_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dovecot_users.csv")
        privilege = input("Ingrese el privilegio deseado: ")

    database = input("Ingrese el nombre de la base de datos: ")
    host = input("Ingrese el host deseado (presione Enter para usar 'localhost'): ") or 'localhost'

    return username, db_engine, database, host, users_file, privilege

# Obtener los datos del usuario
username, db_engine, database, host, users_file, privilege = solicitar_datos_usuario()

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
    f.write("Motor de base de datos: {}\n".format(db_engine))
    f.write("Base de datos: {}\n".format(database))
    f.write("Host: {}\n".format(host))
    f.write("Privilegio: {}\n".format(privilege))

# Imprimir un mensaje de confirmación
print("El archivo de texto para el usuario '{}' se ha creado en el directorio: {}".format(username, user_file))
