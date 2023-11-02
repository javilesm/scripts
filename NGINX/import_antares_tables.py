import csv
import os
import pandas as pd
import mysql.connector
import time
import unidecode
import subprocess
import shutil
import configparser
import re
from io import StringIO

# Variables
Repository = "Antares_project"
GitHubRepoURL = f"https://github.com/TCS2211194M1/{Repository}.git"
Current_Path = os.path.dirname(os.path.abspath(__file__))
parent_directory = os.path.dirname(Current_Path)
RepositoryDir = os.path.join(parent_directory, Repository)
GitDir = os.path.join(RepositoryDir, ".git")
directorio_csv = os.path.join(RepositoryDir, "tablas")
temp_dir = "/var/tmp/tablas"
Headings_Dir = "headings"
ruta_archivos_sql = os.path.join(directorio_csv, 'headings')
ruta_config_mysql = "/etc/mysql/mysql.conf.d/mysqld.cnf"
nueva_ubicacion = ""

# Solicitar al usuario que ingrese los valores de las variables
mysql_user = "2309000000"
mysql_password = "antares1"
mysql_database = "antares"
mysql_host = 'localhost'

# Función para verificar si Git está instalado
def check_git_installed():
    
    try:
        subprocess.check_call(["git", "--version"])
    except subprocess.CalledProcessError:
        print("Git no está instalado en este sistema. Por favor, instálelo y vuelva a ejecutar el script.")
        exit(1)
print("Verificando si Git está instalado...")

def configurar_charset_mysql(ruta_config_mysql):
    # Verificar si el archivo de configuración existe
    if not os.path.isfile(ruta_config_mysql):
        print(f"El archivo de configuración MySQL '{ruta_config_mysql}' no existe.")
        return

    try:
        # Crear una copia de seguridad del archivo de configuración
        ruta_copia_seguridad = ruta_config_mysql + '.bak'
        shutil.copy2(ruta_config_mysql, ruta_copia_seguridad)

        # Copiar el archivo de configuración al directorio temporal con privilegios de superusuario
        copy_command = f'sudo cp {ruta_config_mysql} /tmp/mysql.conf'
        subprocess.run(copy_command, shell=True, check=True)

        # Abrir el archivo de configuración de MySQL desde el directorio temporal
        read_command = 'sudo cat /tmp/mysql.conf'
        config_data = subprocess.check_output(read_command, shell=True, text=True)
        config = configparser.ConfigParser(allow_no_value=True)
        config.read_string(config_data)

        # Cambiar la ubicación de secure-file-priv en el archivo de configuración
        if 'mysqld' not in config:
            config.add_section('mysqld')
        config['mysqld']['character-set-server'] = 'utf8mb4'
        config['mysqld']['collation-server'] = 'utf8mb4_unicode_ci'

        # Guardar los cambios en el archivo de configuración temporal
        with open('/tmp/mysql.conf', 'w') as configfile:
            config.write(configfile)

        # Mover el archivo de configuración temporal a su ubicación original con privilegios de superusuario
        move_command = f'sudo mv /tmp/mysql.conf {ruta_config_mysql}'
        subprocess.run(move_command, shell=True, check=True)

        # Reiniciar el servidor MySQL para que los cambios surtan efecto
        restart_command = 'sudo service mysql restart'  # Comando para reiniciar MySQL
        subprocess.run(restart_command, shell=True, check=True)

        print("La configuración de caracteres en MySQL se ha actualizado a utf8mb4.")
        print(f"Se ha creado una copia de seguridad en '{ruta_copia_seguridad}'.")

    except Exception as e:
        print(f"Error al configurar el conjunto de caracteres en MySQL: {str(e)}")

# Función para crear el directorio si no existe
def create_directory(RepositoryDir, GitDir, GitHubRepoURL, directorio_csv, temp_dir):
    # Comprueba si el directorio existe
    print(f"Comprobando si el directorio '{RepositoryDir}' existe...")
    if not os.path.exists(RepositoryDir):
        print(f"El directorio '{RepositoryDir}' no existe.")
        print(f"Creando el directorio '{RepositoryDir}'...")

        try:
            # Utiliza el comando sudo mkdir para crear el directorio
            subprocess.run(["sudo", "mkdir", RepositoryDir], check=True)
            print(f"Directorio '{RepositoryDir}' creado con éxito.")
        except subprocess.CalledProcessError:
            print(f"Error al crear el directorio '{RepositoryDir}'.")
            exit(1)
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
            subprocess.check_call(["sudo", "git", "clone", GitHubRepoURL, "."])
            print("Repositorio clonado con éxito.")
            copiar_y_ajustar_permisos(directorio_csv, temp_dir)
        except subprocess.CalledProcessError:
            print("Error al clonar el repositorio.")
        else:
            print("Repositorio actualizado con éxito.")
    else:
        print(f"El directorio contiene un repositorio '{GitDir}'. Actualizando el repositorio...")

        try:
            subprocess.check_call(["git", "pull", GitHubRepoURL, "--allow-unrelated-histories"])
            print("Repositorio actualizado con éxito.")
            copiar_y_ajustar_permisos(directorio_csv, temp_dir)
        except subprocess.CalledProcessError:
            print("Error al actualizar el repositorio.")

def copiar_y_ajustar_permisos(directorio_csv, temp_dir):
    try:
        # Copiar el directorio de origen al destino
        shutil.copytree(directorio_csv, temp_dir)

        print(f"Cambiand la propiedad del directorio '{temp_dir}'...")

        # Ejecutar el comando para cambiar la propiedad
        comando_chown = f"sudo chown -R mysql:mysql {temp_dir}"
        subprocess.run(comando_chown, shell=True, check=True)

        # Agregar el comando para cambiar los permisos
        comando_chmod = f"sudo chmod 755 -R {temp_dir}"
        subprocess.run(comando_chmod, shell=True, check=True)

        print("Directorio copiado y permisos ajustados con éxito.")

        check_ruta_Headings_Dir(directorio_csv, Headings_Dir)
    except Exception as e:
        print(f"Error: {str(e)}")

# Función para
def check_ruta_Headings_Dir(directorio_csv, Headings_Dir):
    # Ruta completa del Headings_Dir donde se guardarán los archivos de texto
    ruta_Headings_Dir = os.path.join(directorio_csv, Headings_Dir)

    # Verificar si el Headings_Dir existe y, si no existe, crearlo con "create_directory_with_sudo"
    print(f"Verificando si el directorio '{ruta_Headings_Dir }' existe...")
    if not os.path.exists(ruta_Headings_Dir):
        print(f"El directorio '{ruta_Headings_Dir}' no existe. Creando...")
        create_directory_with_sudo(directorio_csv, Headings_Dir, ruta_Headings_Dir)

def create_directory_with_sudo(directorio_csv, Headings_Dir, ruta_Headings_Dir):
    try:
        print(f"Creando el directorio '{ruta_Headings_Dir}'...")

        # Crea el directorio con sudo mkdir
        subprocess.run(["sudo", "mkdir", ruta_Headings_Dir], check=True)
        print(f"Directorio '{ruta_Headings_Dir}' creado con éxito.")

        # Obtiene el nombre del usuario actual
        print("Obteniendo el nombre del usuario actual...")
        current_user = os.getenv("USER")  # Alternativa a os.getlogin()

        # Cambia la propiedad del directorio al usuario actual y al grupo del usuario actual
        print(f"Cambiando la propiedad del directorio '{ruta_Headings_Dir}' al usuario '{current_user}'...")
        subprocess.run(["sudo", "chown", "-R", f"{current_user}:{current_user}", ruta_Headings_Dir])

        # Cambia los permisos a 755 (ejemplo: el propietario puede leer, escribir y ejecutar)
        subprocess.run(["sudo", "chmod", "755", ruta_Headings_Dir])

    except subprocess.CalledProcessError as e:
        print(f"Error al crear el directorio o ajustar los permisos: {e}")
        return

    # Llamar a la función obtener_encabezados_csv después de que se haya creado el directorio
    obtener_encabezados_csv(directorio_csv, Headings_Dir, ruta_Headings_Dir)

# Función para obtener los encabezados CSV
def obtener_encabezados_csv(directorio_csv, Headings_Dir, ruta_Headings_Dir):
    print("Obteniendo los encabezados CSV...")

    # Obtener la lista de archivos CSV en el directorio
    archivos_csv = [archivo for archivo in os.listdir(directorio_csv) if archivo.endswith('.csv')]

    # Mapear los tipos de datos de pandas a tipos de datos SQL, incluyendo números de teléfono
    tipos_de_datos_sql = {
        'int64': 'BIGINT NOT NULL',
        'float64': 'FLOAT NOT NULL',
        'object': 'VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL',
        'datetime64': 'DATETIME',
        'date': 'DATE',
        'phone_number': 'VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL'
    }

    # Crear un conjunto para realizar un seguimiento de los encabezados procesados
    encabezados_procesados = set()

    for archivo_csv in archivos_csv:
        # Ruta completa del archivo CSV actual
        ruta_csv = os.path.join(directorio_csv, archivo_csv)

        # Nombre del archivo de texto correspondiente al archivo CSV actual
        archivo_texto = os.path.splitext(archivo_csv)[0] + '.txt'
        ruta_archivo_texto = os.path.join(ruta_Headings_Dir, archivo_texto)

        # Leer el archivo CSV con codificación UTF-8 y manejo de caracteres no válidos
        df = cargar_csv_con_codificacion(ruta_csv, 'utf-8')

        # Eliminar la extensión del nombre del archivo CSV
        nombre_tabla = os.path.splitext(archivo_csv)[0]

        # Crear un diccionario para rastrear los encabezados duplicados
        encabezados_duplicados = {}

        # Abrir el archivo de texto para el archivo CSV actual en modo escritura
        with open(ruta_archivo_texto, 'w', encoding='utf-8') as texto_file:
            print(f"Creando query SQL para crear tabla:'{nombre_tabla}' desde: '{ruta_archivo_texto}'...")

            # Escribir la leyenda en la primera línea
            texto_file.write(f"CREATE TABLE {nombre_tabla} (\n")

            # Lista para almacenar las definiciones de columna
            column_definitions = []

            for i, col in enumerate(df.columns):
                # Verificar si el encabezado ya existe y manejar duplicados
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
                if (
                    col == "Fecha de inicio de vigencia" or
                    col == "Fecha inicio de vigencia" or
                    col == "create_date" or
                    col == "update_date" or
                    col == "Fecha de fin de vigencia" or
                    col == "Fecha fin de vigencia"
                ):
                    tipo_dato_sql = "DATE"
                else:
                    # Determinar el tipo de dato SQL según el tipo de datos de pandas
                    tipo_dato = df[col].dtype
                    tipo_dato_sql = tipos_de_datos_sql.get(str(tipo_dato), 'VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL')

                # Verificar si el encabezado se refiere a un número de teléfono
                if re.search(r'phone|cellphone|telephone|phone1|phone2|tel|telefono', col, re.IGNORECASE):
                    tipo_dato_sql = 'VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL'

                # Convertir el encabezado a mayúsculas y eliminar caracteres especiales y espacios
                col = unidecode.unidecode(col).upper().replace(' ', '_')

                # Agrega la definición de la columna a la lista
                column_definitions.append(f"{col} {tipo_dato_sql}")

            # Escribe las definiciones de columna en el archivo de texto
            texto_file.write(",\n".join(column_definitions))

            # Escribe la clave primaria (PRIMARY KEY) al final del último encabezado
            texto_file.write(f",\nPRIMARY KEY ({column_definitions[0].split()[0]})")

            # Finaliza la definición de la tabla y especifica el motor de la base de datos y el conjunto de caracteres
            texto_file.write(f"\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;\n")

            print(f"Tabla SQL '{nombre_tabla}' creada con éxito.")

        # Mensaje de progreso y pausa
        print(f"Los encabezados y tipos de datos de '{archivo_csv}' se han guardado en: '{ruta_archivo_texto}'")
        print(f"-------------------------------------------------------------------------------------------------")
        time.sleep(1)

    # Llamar a la función crear_tablas_mysql_desde_archivos para obtener la lista de tablas SQL creadas
    tablas_sql_creadas = crear_tablas_mysql_desde_archivos(mysql_host, mysql_user, mysql_password, mysql_database, ruta_archivos_sql, directorio_csv)

# Función para crear tablas SQL desde archivos SQL
def crear_tablas_mysql_desde_archivos(mysql_host, mysql_user, mysql_password, mysql_database, ruta_archivos_sql, directorio_csv):
    tablas_sql = []  # Lista para almacenar los nombres de las tablas SQL creadas
    print("Creando tablas SQL desde archivos SQL...")

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

            # Sentencia SQL para eliminar la tabla si ya existe
            drop_table_sql = f"DROP TABLE IF EXISTS {nombre_tabla}"

            # Ejecutar la sentencia SQL para eliminar la tabla si existe
            cursor.execute(drop_table_sql)
            conn.commit()

            # Leer el contenido del archivo de texto
            with open(ruta_sql, 'r') as sql_file:
                print(f"Creando tabla SQL '{nombre_tabla}' desde: '{ruta_sql}'...")

                sql_query = sql_file.read()
                print(f"{sql_query}")

                # Ejecutar la sentencia SQL para crear la tabla
                cursor.execute(sql_query)
                conn.commit()

                print(f"Tabla '{nombre_tabla}' creada desde '{archivo_sql}'")
                print("----------------------------------------------------------")

        # Llama a la función importar_datos_a_sql después de que se haya completado la creación de tablas
        importar_datos_a_sql(directorio_csv, tablas_sql)

    except mysql.connector.Error as err:
        print(f"Error al conectar a MySQL: {err}")
    except Exception as e:
        print(f"Error general: {e}")
    finally:
        if conn.is_connected():
            cursor.close()
            conn.close()
            print("Conexión a MySQL cerrada.")

# Función para importar datos desde archivos CSV a tablas SQL
def importar_datos_a_sql(directorio_csv, tablas_sql):
    try:
        print("Importando datos desde archivos CSV a tablas SQL...")

        # Conexión a la base de datos MySQL
        conn = mysql.connector.connect(
            host=mysql_host,
            user=mysql_user,
            password=mysql_password,
            database=mysql_database,
        )

        cursor = conn.cursor()

        # Verificar si la conexión fue exitosa
        if conn.is_connected():
            print("Conexión a MySQL exitosa.")
        else:
            print("\033[91mError de conexión a MySQL.\033[0m")

        # Habilitar la funcionalidad de carga de datos locales
        print("Habilitando la funcionalidad de carga de datos locales...")
        cursor.execute("SET GLOBAL local_infile=1;")
        conn.commit()
        print("--------------------------------------------")

        for tabla in tablas_sql:
            # Ruta completa del archivo CSV correspondiente a la tabla
            ruta_csv = os.path.join(temp_dir, f"{tabla}.csv")

            # Verificar si el archivo CSV existe
            if not os.path.exists(ruta_csv):
                print(f"El archivo CSV para la tabla '{tabla}' no existe en '{ruta_csv}'. Saltando...")
                continue

            # Leer el archivo CSV y cargar los datos en la tabla SQL
            print(f"Importando datos a la tabla '{tabla}' desde '{ruta_csv}'...")
            
            with open(ruta_csv, 'r', encoding='utf-8', newline='') as csv_file:
                csv_reader = csv.reader(csv_file)
                next(csv_reader)  # Saltar la primera línea (encabezados)

                # Encierra la ruta entre comillas simples y ajusta las barras diagonales
                ruta_csv = ruta_csv.replace("\\", "\\\\")
                
                # Utiliza la sentencia SQL 'LOAD DATA LOCAL INFILE' para importar los datos desde el CSV
                query = f"LOAD DATA INFILE '{ruta_csv}' INTO TABLE {tabla} FIELDS TERMINATED BY ',' ENCLOSED BY '\"' IGNORE 1 LINES;"
                print(f"Ejecutando query: {query}")
                
                try:
                    cursor.execute(query)
                    conn.commit()
                    print(f"Datos importados exitosamente a la tabla '{tabla}'.")
                except mysql.connector.Error as import_error:
                    print(f"\033[91mError al importar datos a MySQL: {import_error}\033[0m")

            print("--------------------------------------------")

    except mysql.connector.Error as err:
        print(f"\033[91mError al importar datos a MySQL: {err}\033[0m")
    except Exception as e:
        print(f"\033[91mError general: {e}\033[0m")
    finally:
        if conn.is_connected():
            cursor.close()
            conn.close()
            print("Conexión a MySQL cerrada.")

# Función para mostrar el resultado del proceso
def show_result():
    if os.path.exists(GitDir):
        print("Proceso completado.")
    else:
        print("Error al clonar o actualizar el repositorio.")

if __name__ == "__main__":
    check_git_installed()
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
    conexion.close()

# Función para cargar un archivo CSV con codificación y manejo de caracteres no válidos
def cargar_csv_con_codificacion(ruta_csv, codificacion):
    with open(ruta_csv, 'r', encoding=codificacion, errors='replace') as archivo:
        contenido = archivo.read()
        contenido = contenido.replace('�', '')  # Elimina los caracteres no válidos

    # Crea un objeto StringIO para cargar el contenido modificado en Pandas
    buffer = StringIO(contenido)

    # Lee el archivo CSV desde el buffer
    df = pd.read_csv(buffer)

    return df

# Función para eliminar el directorio ruta_archivos_sql
def eliminar_directorio(temp_dir):
    try:
        if os.path.exists(temp_dir):
            # Utiliza el comando 'sudo rm -rf' para eliminar el directorio y su contenido recursivamente
            subprocess.run(["sudo", "rm", "-rf", temp_dir], check=True)
            print(f"El directorio '{temp_dir}' ha sido eliminado con éxito.")
        else:
            print(f"El directorio '{temp_dir}' no existe y no se pudo eliminar.")
    except subprocess.CalledProcessError as e:
        print(f"Error al eliminar el directorio '{temp_dir}': {e}")

# Función principal
def main():
    configurar_charset_mysql(ruta_config_mysql)
    show_result()
    create_directory(RepositoryDir, GitDir, GitHubRepoURL, directorio_csv, temp_dir)
    eliminar_directorio(temp_dir)

main()
