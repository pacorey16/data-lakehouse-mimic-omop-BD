from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from datetime import datetime
import os

def subir_lote_a_minio():
    # Ruta interna del contenedor Airflow (mapeada a docker/data)
    base_path = '/opt/airflow/data/lotes_landing'
    # Conexión que configuraremos en la UI de Airflow
    s3 = S3Hook(aws_conn_id='minio_conn')
    bucket = 'datalake'
    
    # Elegimos el primer año disponible (ej. 2180)
    lotes = sorted(os.listdir(base_path))
    if not lotes:
        print("No hay más lotes para procesar")
        return

    lote_del_dia = lotes[0]
    ruta_lote = os.path.join(base_path, lote_del_dia)
    
    for archivo in os.listdir(ruta_lote):
        path_completo = os.path.join(ruta_lote, archivo)
        # Lo subimos a la zona Landing de nuestro Data Lake
        s3.load_file(
            filename=path_completo,
            key=f'landing/{lote_del_dia}/{archivo}',
            bucket_name=bucket,
            replace=True
        )
    print(f"Lote {lote_del_dia} subido con éxito a MinIO.")

with DAG(
    'ingesta_hospitalaria_diaria',
    start_date=datetime(2026, 5, 3),
    schedule_interval='@daily', 
    catchup=False
) as dag:

    tarea_ingesta = PythonOperator(
        task_id='subir_lote_minio',
        python_callable=subir_lote_a_minio
    )