import random
import string

# lista de subdominios disponibles
subdomains = ['creativeering', 
              'tecnotools', 
              'aplika-t', 
              'avilesweb'
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

# solicitar al usuario que elija un dominio de correo electrónico
print("Seleccione un dominio de correo electrónico (opción predeterminada: gmail.com):")
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
print(f"Su dirección de correo electrónico es {email} y su contraseña es {password}.")
print(f"Su dirección de correo electrónico alias es {alias} y comparte la misma contraseña.")
