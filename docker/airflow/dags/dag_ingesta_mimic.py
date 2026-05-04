from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from datetime import datetime
import os

# --- TAREA 1: Ingesta ---
def subir_lote_a_minio():
    base_path = '/opt/airflow/data/lotes_landing'
    s3 = S3Hook(aws_conn_id='minio_conn')
    bucket = 'datalake'
    
    lotes = sorted(os.listdir(base_path))
    if not lotes: return

    lote_del_dia = lotes[0]
    ruta_lote = os.path.join(base_path, lote_del_dia)
    
    for archivo in os.listdir(ruta_lote):
        s3.load_file(
            filename=os.path.join(ruta_lote, archivo),
            key=f'landing/{lote_del_dia}/{archivo}',
            bucket_name=bucket,
            replace=True
        )
    return lote_del_dia # Pasamos el año a la siguiente tarea

# --- TAREA 2: Mover a Bronze ---
def mover_a_bronze(**kwargs):
    ti = kwargs['ti']
    anio = ti.xcom_pull(task_ids='subir_lote_minio')
    s3 = S3Hook(aws_conn_id='minio_conn')
    bucket = 'datalake'
    
    # Listamos archivos en landing/año
    archivos = s3.list_keys(bucket_name=bucket, prefix=f'landing/{anio}/')
    
    for key in archivos:
        new_key = key.replace('landing/', 'mimic-bronze/')
        # Copiamos a la carpeta bronze
        s3.copy_object(source_bucket_key=key, dest_bucket_key=new_key, 
                       source_bucket_name=bucket, dest_bucket_name=bucket)
        # Borramos de landing
        s3.delete_objects(bucket=bucket, keys=key)

with DAG(
    'ingesta_hospitalaria_diaria',
    start_date=datetime(2026, 5, 3),
    schedule_interval='@daily',
    catchup=False
) as dag:

    t1 = PythonOperator(
        task_id='subir_lote_minio',
        python_callable=subir_lote_a_minio
    )

    t2 = PythonOperator(
        task_id='mover_a_bronze',
        python_callable=mover_a_bronze
    )

    # --- TAREAS 3 y 4: dbt ---
    # Nota: El comando asume que dbt está instalado en el contenedor de airflow
    t3 = BashOperator(
        task_id='dbt_run',
        bash_command='cd /opt/airflow/dbt_project/mimicToOmop && dbt deps && dbt run --profiles-dir .'
    )

    t4 = BashOperator(
        task_id='dbt_test',
        bash_command='cd /opt/airflow/dbt_project/mimicToOmop && dbt test --profiles-dir .'
    )

    # Definimos el flujo
    t1 >> t2 >> t3 >> t4