import csv
import os
import pandas as pd
import mysql.connector
import time
import unidecode
import subprocess
import shutil
import configparser

def script_encabezado():
    print("********CREATIVERING SOLUTIONS********")
    print("----------------------------------------")
    print("********IMPORT CSV TO SQL********")
    print("----------------------------------------")
    print("Script de importación de tablas CSV a MySQL")
    print("Este script automatiza la importación de tablas CSV a MySQL")
    print("----------------------------------------")

# Llama a la función para mostrar el encabezado del script
script_encabezado()

# Variables
Repository = "Antares_project"
GitHubRepoURL = f"https://github.com/TCS2211194M1/{Repository}.git"
RepositoryDir = f"/var/www/{Repository}"
GitDir = os.path.join(RepositoryDir, ".git")
directorio_csv = os.path.join(RepositoryDir, "tablas")
Headings_Dir = 'headings'
ruta_archivos_sql = os.path.join(directorio_csv, 'headings')
ruta_config_mysql = "/etc/mysql/mysql.conf.d/mysqld.cnf"
nueva_ubicacion = ""


# Solicitar al usuario que ingrese los valores de las variables
mysql_user = input("Ingresa el nombre de usuario de MySQL: ")
mysql_password = input("Ingresa la contraseña de MySQL: ")
mysql_database = input("Ingresa el nombre de la base de datos de MySQL: ")

# Pregunta al usuario si desea cambiar el valor de mysql_host
default_mysql_host = '127.0.0.1'
use_default_host = input(f"El valor predeterminado para mysql_host es '{default_mysql_host}'. ¿Deseas mantenerlo? (S/n): ")

# Verifica la respuesta del usuario y actualiza mysql_host si es necesario
if use_default_host.strip().lower() == 'n':
    mysql_host = input("Ingresa la dirección IP o nombre de host de MySQL: ")
else:
    mysql_host = default_mysql_host

# Función para verificar si Git está instalado
def check_git_installed():
    
    try:
        subprocess.check_call(["git", "--version"])
    except subprocess.CalledProcessError:
        print("Git no está instalado en este sistema. Por favor, instálelo y vuelva a ejecutar el script.")
        exit(1)
print("Verificando si Git está instalado...")

# Llamar a la función check_git_installed
check_git_installed()

# Función para configurar secure-file-priv
def configurar_secure_file_priv(ruta_config_mysql, nueva_ubicacion):
    
    try:
        # Verificar si el archivo de configuración existe
        if not os.path.isfile(ruta_config_mysql):
            print(f"El archivo de configuración MySQL '{ruta_config_mysql}' no existe.")
            return

        # Crear una copia de seguridad del archivo de configuración
        ruta_copia_seguridad = ruta_config_mysql + '.bak'
        shutil.copy2(ruta_config_mysql, ruta_copia_seguridad)

        # Abrir el archivo de configuración de MySQL
        config = configparser.ConfigParser()
        config.read(ruta_config_mysql)

        # Cambiar la ubicación de secure-file-priv en el archivo de configuración
        if 'mysqld' not in config:
            config.add_section('mysqld')
        config['mysqld']['secure-file-priv'] = nueva_ubicacion

        # Guardar los cambios en el archivo de configuración
        with open(ruta_config_mysql, 'w') as configfile:
            config.write(configfile)

        # Reiniciar el servidor MySQL para que los cambios surtan efecto
        subprocess.call(['service', 'mysql', 'restart'])  # Esto puede variar según tu sistema operativo

        print(f"La ubicación de 'secure-file-priv' se ha configurado en '{nueva_ubicacion}'.")
        print(f"Se ha creado una copia de seguridad en '{ruta_copia_seguridad}'.")

    except Exception as e:
        print(f"Error al configurar 'secure-file-priv': {str(e)}")

print(f"Configurando '{ruta_config_mysql}'...")

# Llamar a la función configurar_secure_file_priv
configurar_secure_file_priv(ruta_config_mysql, nueva_ubicacion)

# Función para crear el directorio si no existe
def create_directory():
    # Comprueba si el directorio existe
    print(f"Comprobando si el directorio '{RepositoryDir}' existe...")
    if not os.path.exists(RepositoryDir):
        print(f"El directorio '{RepositoryDir}' no existe.")
        print("Creando el directorio...")
        
        try:
            os.mkdir(RepositoryDir)
        except OSError:
            print("Error al crear el directorio.")
            exit(1)
        else:
            print("Directorio creado con éxito.")
    else:
        print(f"El directorio '{RepositoryDir}' existe...")

    # Accede al directorio
    os.chdir(RepositoryDir)

    # Comprueba si el directorio es un repositorio git
    print(f"Comprobando si el directorio '{RepositoryDir}' contiene un repositorio '{GitDir}'...")
    if not os.path.exists(GitDir):
        print(f"Comprobando si el directorio '{RepositoryDir}' contiene un repositorio '{GitDir}'...")
        print(f"El directorio no contiene un repositorio '{GitDir}'. Clonando el repositorio...")
        
        try:
            subprocess.check_call(["git", "clone", GitHubRepoURL, "."])
        except subprocess.CalledProcessError:
            print("Error al clonar el repositorio.")
        else:
            print("Repositorio clonado con éxito.")
    else:
        print(f"El directorio contiene un repositorio '{GitDir}'. Actualizando el repositorio...")
        
        try:
            subprocess.check_call(["git", "pull", GitHubRepoURL, "--allow-unrelated-histories"])
        except subprocess.CalledProcessError:
            print("Error al actualizar el repositorio.")
        else:
            print("Repositorio actualizado con éxito.")

# Función para mostrar el resultado del proceso
def show_result():
    if os.path.exists(GitDir):
        print("Proceso completado.")
    else:
        print("Error al clonar o actualizar el repositorio.")

if __name__ == "__main__":
    check_git_installed()
    create_directory()
    show_result()
    print("Fin del script.")

def connDB(host, user, password, database):
    print(f"Establciendo conexion con la base de datos...")
    time.sleep(1)
    try:
        conn = mysql.connector.connect(
            host=mysql_host,
            user=mysql_user,
            password=mysql_password,
            database=mysql_database
        )
        cursor = conn.cursor()

        # Comprobar si la base de datos existe
        cursor.execute(f"SHOW DATABASES LIKE '{database}'")
        result = cursor.fetchone()

        if result:
            print(f"Conexión a MySQL exitosa. La base de datos '{database}' existe.")
            return conn
        else:
            print(f"La base de datos '{database}' no existe.")
            conn.close()
            return None

    except mysql.connector.Error as err:
        print(f"Error al conectar a MySQL: {err}")
        return None

# Llamar a la función connDB
conexion = connDB(host=mysql_host, user=mysql_user, password=mysql_password, database=mysql_database)

if conexion is not None:
    # Puedes realizar operaciones con la base de datos aquí
    # No olvides cerrar la conexión cuando hayas terminado
    conexion.close()

# Obtener los encabezados CSV
def obtener_encabezados_csv(directorio_csv, Headings_Dir):
    print("Obteniendo los encabezados CSV...")

    # Obtener la lista de archivos CSV en el directorio
    archivos_csv = [archivo for archivo in os.listdir(directorio_csv) if archivo.endswith('.csv')]

    # Ruta completa del Headings_Dir donde se guardarán los archivos de texto
    ruta_Headings_Dir = os.path.join(directorio_csv, Headings_Dir)

    # Verificar si el Headings_Dir existe y, si no existe, crearlo
    if not os.path.exists(ruta_Headings_Dir):
        os.mkdir(ruta_Headings_Dir)

    # Mapear los tipos de datos de pandas a tipos de datos SQL
    tipos_de_datos_sql = {
        'int64': 'INT',
        'float64': 'FLOAT',
        'object': 'VARCHAR(1000)',  # Agregar la longitud deseada (por ejemplo, 1000)
        'datetime64': 'DATETIME',
        'date': 'DATE',  # Agregar tipo DATE para las columnas de fecha
    }
    
    # Crear un conjunto para realizar un seguimiento de los encabezados procesados
    encabezados_procesados = set()

    for archivo_csv in archivos_csv:
        # Ruta completa del archivo CSV actual
        ruta_csv = os.path.join(directorio_csv, archivo_csv)

        # Nombre del archivo de texto correspondiente al archivo CSV actual
        archivo_texto = os.path.splitext(archivo_csv)[0] + '.txt'
        ruta_archivo_texto = os.path.join(ruta_Headings_Dir, archivo_texto)

        # Leer el archivo CSV y especificar las columnas de fecha
        df = pd.read_csv(ruta_csv, encoding='ISO-8859-1', dayfirst=True)
        
        # Eliminar la extensión del nombre del archivo CSV
        nombre_archivo_sin_extension = os.path.splitext(archivo_csv)[0]

        # Crear un diccionario para rastrear los encabezados duplicados
        encabezados_duplicados = {}

        # Abrir el archivo de texto para el archivo CSV actual en modo escritura
        with open(ruta_archivo_texto, 'w') as texto_file:
            print(f"Obteniendo los encabezados y tipos de datos de '{archivo_csv}'...")

            # Escribir la leyenda en la primera línea
            texto_file.write(f"CREATE TABLE {nombre_archivo_sin_extension} (\n")
            
            # Escribir los encabezados y tipos de datos en el archivo de texto
            for i, col in enumerate(df.columns):
                # Verificar si el encabezado ya existe
                if col in encabezados_procesados:
                    # Generar un nombre único para encabezados duplicados
                    encabezado_duplicado = col
                    contador = 1
                    while encabezado_duplicado in encabezados_duplicados:
                        contador += 1
                        encabezado_duplicado = f"{col}_{contador}"
                    encabezados_duplicados[col] = encabezado_duplicado
                    col = encabezado_duplicado

                # Agregar el encabezado al conjunto de encabezados procesados
                encabezados_procesados.add(col)

                # Verificar si el encabezado coincide con nombres específicos y ajustar el tipo de dato
                if col == "Fecha de inicio de vigencia" or col == "Fecha inicio de vigencia" or col == "create_date" or col == "update_date" or col == "Fecha de fin de vigencia" or col == "Fecha fin de vigencia":
                    tipo_dato_sql = "DATE"
                else:
                    tipo_dato = df[col].dtype
                    tipo_dato_sql = tipos_de_datos_sql.get(str(tipo_dato), 'VARCHAR(1000)')  # Tipo de dato predeterminado con longitud

                # Convertir el encabezado a mayúsculas y eliminar caracteres especiales y espacios
                col = unidecode.unidecode(col).upper().replace(' ', '_')

                if i == len(df.columns) - 1:
                    # Última columna, escribir punto y coma y salto de línea
                    texto_file.write(f"{col} {tipo_dato_sql}\n);\n")
                else:
                    # Escribir el encabezado, tipo de dato y una coma
                    texto_file.write(f"{col} {tipo_dato_sql},\n")

        print(f"Los encabezados y tipos de datos de '{archivo_csv}' se han guardado en: '{ruta_archivo_texto}'")
        print(f"-------------------------------------------------------------------------------------------------")
        time.sleep(1)

# Llamar a la función obtener_encabezados_csv
obtener_encabezados_csv(directorio_csv, Headings_Dir)



# Crear tablas SQL desde CSV   
def crear_tablas_mysql_desde_archivos(mysql_host, mysql_user, mysql_password, mysql_database, ruta_archivos_sql):
    tablas_sql = []  # Lista para almacenar los nombres de las tablas SQL creadas
    print("Creando tablas SQL desde CSV...")

    try:
        # Conexión a la base de datos MySQL
        conn = mysql.connector.connect(
            host=mysql_host,
            user=mysql_user,
            password=mysql_password,
            database=mysql_database
        )

        cursor = conn.cursor()

        # Verificar si la conexión fue exitosa
        if conn.is_connected():
            print("Conexión a MySQL exitosa.")
        else:
            print("Error de conexión a MySQL.")

        # Obtener la lista de archivos de texto en la ruta especificada
        archivos_sql = [archivo for archivo in os.listdir(ruta_archivos_sql) if archivo.endswith('.txt')]

        # Iterar a través de los archivos y ejecutar las sentencias SQL
        for archivo_sql in archivos_sql:
            ruta_sql = os.path.join(ruta_archivos_sql, archivo_sql)

            # Obtener el nombre de la tabla a partir del nombre del archivo
            nombre_tabla = os.path.splitext(archivo_sql)[0]
            
            # Agregar el nombre de la tabla a la lista tablas_sql
            tablas_sql.append(nombre_tabla)

            # Leer el contenido del archivo de texto
            with open(ruta_sql, 'r') as sql_file:
                print(f"Creando tabla SQL '{nombre_tabla}' desde: '{ruta_sql}'...")

                sql_query = sql_file.read()
                print(f"{sql_query}")

                # Ejecutar la sentencia SQL
                cursor.execute(sql_query)
                conn.commit()

                print(f"Tabla '{nombre_tabla}' creada desde '{archivo_sql}'")

    except mysql.connector.Error as err:
        print(f"Error al conectar a MySQL: {err}")
    except Exception as e:
        print(f"Error general: {e}")
    finally:
        if conn.is_connected():
            cursor.close()
            conn.close()
            print("Conexión a MySQL cerrada.")
    
    return tablas_sql  # Devuelve la lista de nombres de tablas SQL creadas

# Llamar a la función crear_tablas_mysql_desde_archivos para obtener la lista de tablas SQL creadas
#tablas_sql_creadas = crear_tablas_mysql_desde_archivos(mysql_host, mysql_user, mysql_password, mysql_database, ruta_archivos_sql)

# Importar datos a SQL
def importar_datos_a_sql(conn, directorio_csv, tablas_sql):
    print("Importando datos a SQL...")
    try:
        # Conexión a la base de datos MySQL
        conn = mysql.connector.connect(
            host=mysql_host,
            user=mysql_user,
            password=mysql_password,
            database=mysql_database
        )

        cursor = conn.cursor()

        # Verificar si la conexión fue exitosa
        if conn.is_connected():
            print("Conexión a MySQL exitosa.")
        else:
            print("Error de conexión a MySQL.")

        # Habilitar la funcionalidad de carga de datos locales
        print("Habilitando la funcionalidad de carga de datos locales...")
        cursor.execute("SET GLOBAL local_infile=1;")
        conn.commit()

        for tabla in tablas_sql:
            # Ruta completa del archivo CSV correspondiente a la tabla
            ruta_csv = os.path.join(directorio_csv, f"{tabla}.csv")

            # Verificar si el archivo CSV existe
            if not os.path.exists(ruta_csv):
                print(f"El archivo CSV para la tabla '{tabla}' no existe en '{ruta_csv}'. Saltando...")
                continue

            # Leer el archivo CSV y cargar los datos en la tabla SQL
            print(f"Importando datos a la tabla '{tabla}' desde '{ruta_csv}'...")
            with open(ruta_csv, 'r', encoding='ISO-8859-1') as csv_file:
                # Utiliza la sentencia SQL 'LOAD DATA INFILE' para importar los datos desde el CSV
                # Encierra la ruta entre comillas simples y ajusta las barras diagonales
                ruta_csv = ruta_csv.replace("\\", "\\\\")
                print(f"Ejecutando query: LOAD DATA INFILE '{ruta_csv}' INTO TABLE {tabla} FIELDS TERMINATED BY ',' ENCLOSED BY '\"' IGNORE 1 LINES;")
                query = f"LOAD DATA INFILE '{ruta_csv}' INTO TABLE {tabla} FIELDS TERMINATED BY ',' ENCLOSED BY '\"' IGNORE 1 LINES;"
                cursor.execute(query)
                conn.commit()

            print(f"Datos importados exitosamente a la tabla '{tabla}'.")

    except mysql.connector.Error as err:
        print(f"Error al importar datos a MySQL: {err}")
    except Exception as e:
        print(f"Error general: {e}")

# Llama a la función importar_datos_a_sql
importar_datos_a_sql(conexion, directorio_csv, tablas_sql_creadas)

def script_footer():
    print("****************ALL DONE****************")
    print("----------------------------------------")
    print("Copyright TECNOLOGIA COMERCIAL Y SERVICIOS INTEGRALES SAMAVA SAS DE CV. 2023. All rights reserved.")
    print("----------------------------------------")
    print("Para uso interno. Queda prohibida toda copia no autorizada.")


# Llama a la función para mostrar el pie del script
script_footer()

# Función para eliminar el directorio ruta_archivos_sql
def eliminar_directorio(directorio):
    try:
        if os.path.exists(directorio):
            shutil.rmtree(directorio)
            print(f"El directorio '{directorio}' ha sido eliminado.")
        else:
            print(f"El directorio '{directorio}' no existe y no se pudo eliminar.")
    except Exception as e:
        print(f"Error al eliminar el directorio '{directorio}': {e}")

# Llama a la función para eliminar el directorio ruta_archivos_sql
#eliminar_directorio(ruta_archivos_sql)
