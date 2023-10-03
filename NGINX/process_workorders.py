import os
import subprocess
import mysql.connector
import tempfile
import json
import datetime

# Variables
script_directory = os.path.dirname(os.path.abspath(__file__))
output_file_path = os.path.join(script_directory, 'registros.csv')

# Configuración de la conexión a MySQL
MYSQL_USER = "antares"
MYSQL_PASSWORD = "antares1"
MYSQL_HOST = "localhost"  # Cambia a la dirección de tu servidor MySQL si es necesario
MYSQL_DATABASE = "antares"
MYSQL_STORAGE_TABLE = "t_storage"
MYSQL_PARTITIONS_TABLE = "t_partition"
MYSQL_WORKORDER_TABLE = "t_workorder"
MYSQL_WORKORDERFLAG_TABLE = "t_workorder_flag"
MYSQL_PRODUCT_TABLE = "t_Product"

def read_workorder_table():
    try:
        # Configuración de la conexión a MySQL
        connection = mysql.connector.connect(
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            host=MYSQL_HOST,
            database=MYSQL_DATABASE
        )
        cursor = connection.cursor()

        # Obtener los encabezados de la tabla
        cursor.execute(f"SHOW COLUMNS FROM {MYSQL_WORKORDER_TABLE}")
        headers = [column[0] for column in cursor.fetchall()]

        # Ejecutar la consulta SQL
        SQL_QUERY = f"SELECT * FROM {MYSQL_WORKORDER_TABLE}"
        cursor.execute(SQL_QUERY)
        results = cursor.fetchall()

        print("Encabezados de la tabla:")
        print(headers)
        print("------------------------------------------------------------------------------------------------")

        for row in results:
            workorder_flag = row[headers.index("WORKORDER_FLAG")]
            print(f"Registro en la tabla {MYSQL_PRODUCT_TABLE}:")
            print(row)

            if workorder_flag == 1:
                print("******************************************")
                # Consultar la tabla MYSQL_PRODUCT_TABLE
                SQL_PRODUCT_QUERY = f"SELECT STORAGE_SIZE FROM {MYSQL_PRODUCT_TABLE} WHERE T_PRODUCT = {row[headers.index('T_PRODUCT')]}"
                cursor.execute(SQL_PRODUCT_QUERY)
                product_result = cursor.fetchone()

                if product_result:
                    product_description = product_result[0]  # Obtiene el valor de la primera columna (SHORT_DESCRIPTION)
                    print(f"Espacio en disco requerido: {product_description}")
                else:
                    print("Registro no encontrado en la tabla MYSQL_PRODUCT_TABLE")


                print("******************************************")

            print("------------------------------------------------------------------------------------------------")

        cursor.close()
        connection.close()
    except Exception as e:
        print("Error al ejecutar la consulta SQL en MySQL.")
        print(str(e))

def process_workorders():
    read_workorder_table()
    print("------------------------------------------------------------------------------------------------")

# Llamar a la función principal
process_workorders()
