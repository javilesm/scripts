import os
import random
import string

# lista de subdominios disponibles
subdomains = ['tecnotools.shop', 
              'creativeering.com', 
              'aplika-t.com', 
              'avilesworks.com'
             ]

# lista de proveedores de correo electrónico
domains = ['gmail.com', 
           'yahoo.com', 
           'hotmail.com', 
           'outlook.com'
          ]

# solicitar nombre de usuario
nombre = input("Ingrese su nombre: ")
apellido = input("Ingrese su apellido: ")
username = f"{nombre}.{apellido}"

# solicitar al usuario que elija un subdominio
print("Seleccione un subdominio:")
for i, subdomain in enumerate(subdomains):
    print(f"{i+1}. {subdomain}")
choice = int(input("Opción: "))
while choice < 1 or choice > len(subdomains):
    choice = int(input("Seleccione un subdominio válido: "))
subdomain = subdomains[choice-1]
subdomain2 = subdomains[choice-1].split(".")[0]

# solicitar al usuario que elija un proveedor de correo electrónico
print("Seleccione un proveedor de correo electrónico (opción predeterminada: gmail.com):")
for i, domain in enumerate(domains):
    print(f"{i+1}. {domain}")
choice = input("Opción (presione Enter para seleccionar la opción predeterminada): ")
if choice == '':
    domain = 'gmail.com'
else:
    choice = int(choice)
    while choice < 1 or choice > len(domains):
        choice = int(input("Seleccione un dominio válido: "))
    domain = domains[choice-1]

# generar una contraseña aleatoria de 12 caracteres alfanuméricos
password = ''.join(random.choices(string.ascii_letters + string.digits, k=24))

# imprimir la dirección de correo electrónico y la contraseña generada
email = f"{username}.{subdomain2}@{domain}"
alias = f"{username}@{subdomain}"
# imprimir la dirección de correo electrónico y la contraseña
print("Hola!", nombre, "tus credenciales de acceso al sistema son:")
print("Correo electrónico principal es:", email)
print("Correo electrónico alias es:", alias)
print("La contraseña para ambas cuentas es:", password)
print("Recuerda revisar la política de cuentas antes de cualquier uso, así como cambiar tu contraseña a la brevedad.")
print("Saludos!")

# Crear un archivo de texto para el usuario
# Crear el subdirectorio "credentials" si no existe
credentials_dir = os.path.join(os.path.expanduser("~"), "mail_credentials")
os.makedirs(credentials_dir, exist_ok=True)

# Crear un archivo de texto para el usuario dentro del subdirectorio "credentials"
user_dir = os.path.join(credentials_dir, username)
os.makedirs(user_dir, exist_ok=True)
file_path = os.path.join(user_dir, "{}.txt".format(username))

with open(file_path, "w") as file:
    file.write(f"Nombre de usuario: {username}\n")
    file.write(f"Dirección de correo electrónico: {email}\n")
    file.write(f"Contraseña: {password}\n")
# Imprimir un mensaje de confirmación
print(f"La información del usuario ha sido guardada en el archivo {file_path}.")

# almacenar la información en un archivo CSV
users_file = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),  "scripts", "Postfix", "mail_users.csv")
with open(users_file, "a") as f:
    f.write("{},{}\n".format(email, alias))

# Imprimir un mensaje de confirmación   
print(f"La información del usuario ha sido guardada en el archivo: {users_file}")
