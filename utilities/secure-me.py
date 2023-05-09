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
    # Solicitar el motor de base de datos
    engines = {
        "1": "MySQL",
        "2": "PostgreSQL",
        "3": "SQLite",
        "4": "MariaDB"
    }
    print("Seleccione el nombre de su motor:")
    
    for key, value in engines.items():
        print(f"{key}: {value}")
    db_engine_option = input("Ingrese el número de motor de base de datos deseado: ")
    db_engine = engines.get(db_engine_option, None)
    if db_engine is None:
        print("Opción de motor de base de datos inválida")
        exit()
       # Solicitar el nombre de usuario
    username = input("Ingrese el nombre de usuario: ")
    # Solicitar la base de datos
    database = input("Ingrese el nombre de la base de datos: ")
    # Solicitar el host
    host = input("Ingrese el host deseado (presione Enter para usar 'localhost'): ") or 'localhost'
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
            10: "SHUTDOWN",
            11: "USAGE",
            12: "INDEX",
            13: "FILE",
            14: "SUPER",
            15: "SHUTDOWN",
            16: "EXECUTE"
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
            10: "TEMPORARY",
            11: "EXECUTE",
            12: "SET",
            13: "ALTER SYSTEM",
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
            10: "CREATE_TRIGGER",
            11: "DROP_ABLE",
            12: "DROP_INDEX",
            13: "DROP_VIEW",
            14: "DROP_TRIGGER",
            15: "ALTER_TABLE",
            16: "ANALYZE"
        }
        print("Seleccione un privilegio:")
        for i, privilege in privileges.items():
            print(f"{i}: {privilege}")
        privilege_option = input("Ingrese el número de privilegio deseado: ")
        privilege = privileges.get(int(privilege_option), None)
        if privilege is None:
            print("Opción de privilegio inválida")
            exit()
    elif db_engine == "MariaDB":
        users_file = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),  "scripts", "MariaDB", "mariadb_users.csv")
        privileges = {
            0: "NONE",
            1: "ALTER",
            2: "INSERT",
            3: "UPDATE",
            4: "DELETE",
            5: "DROP",
            6: "INDEX",
            7: "REFERENCES",
            8: "LOCKTABLES",
            9: "EXECUTE",
            10: "CREATETEMPORARYTABLES",
            11: "FILE",
            12: "SUPER",
            13: "DROP_VIEW",
            14: "DROP_TRIGGER",
            15: "ALTER_TABLE",
            16: "ANALYZE"
        }
        print("Seleccione un privilegio:")
        for i, privilege in privileges.items():
            print(f"{i}: {privilege}")
        privilege_option = input("Ingrese el número de privilegio deseado: ")
        privilege = privileges.get(int(privilege_option), None)
        if privilege is None:
            print("Opción de privilegio inválida")
            exit()
    return username, db_engine, database, host, users_file, privilege

# Obtener los datos del usuario
db_engine, username, database, host, users_file, privilege = solicitar_datos_usuario()

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
