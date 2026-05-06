from airflow import DAG
from airflow.exceptions import AirflowSkipException
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from datetime import datetime
import os

LANDING_BUCKET = 'landing-zone'
BRONZE_BUCKET = 'mimic-bronze'
TABLAS = ['admissions', 'patients', 'diagnoses_icd']

# --- TAREA 1: Subir lote de landing-zone a mimic-bronze ---
def subir_lote_a_bronze(**kwargs):
    base_path = '/opt/airflow/data/lotes_landing'
    s3 = S3Hook(aws_conn_id='minio_conn')

    lotes = sorted(os.listdir(base_path))
    if not lotes:
        raise AirflowSkipException("No quedan lotes en lotes_landing — pipeline completado.")

    anio = lotes[0]

    # Evitar reprocesar un lote ya subido
    existing = s3.list_keys(bucket_name=BRONZE_BUCKET, prefix=f'admissions/{anio}_')
    if existing:
        raise AirflowSkipException(f"El lote {anio} ya existe en {BRONZE_BUCKET} — se omite.")

    ruta_lote = os.path.join(base_path, anio)

    for archivo in os.listdir(ruta_lote):
        tabla = os.path.splitext(archivo)[0]  # e.g. 'admissions'
        s3.load_file(
            filename=os.path.join(ruta_lote, archivo),
            key=f'{tabla}/{anio}_{archivo}',   # mimic-bronze/admissions/2110_admissions.csv
            bucket_name=BRONZE_BUCKET,
            replace=True
        )

    # Borramos el lote de landing-zone
    for archivo in os.listdir(ruta_lote):
        tabla = os.path.splitext(archivo)[0]
        s3.delete_objects(
            bucket=LANDING_BUCKET,
            keys=[f'{anio}/{archivo}']
        )

    kwargs['ti'].xcom_push(key='anio', value=anio)
    return anio


# --- TAREA 2: Borrar lote local procesado ---
def marcar_lote_procesado(**kwargs):
    import subprocess
    base_path = '/opt/airflow/data/lotes_landing'
    anio = kwargs['ti'].xcom_pull(key='anio', task_ids='subir_lote_bronze')
    ruta_lote = os.path.join(base_path, anio)
    if os.path.exists(ruta_lote):
        # shutil.rmtree falla en Docker con bind mounts de macOS (dir_fd issue)
        subprocess.run(['rm', '-rf', ruta_lote], check=True)


with DAG(
    'ingesta_hospitalaria_anual',
    start_date=datetime(2026, 5, 3),
    schedule_interval='@daily',
    catchup=False
) as dag:

    t1 = PythonOperator(
        task_id='subir_lote_bronze',
        python_callable=subir_lote_a_bronze,
        provide_context=True
    )

    t2 = PythonOperator(
        task_id='marcar_lote_procesado',
        python_callable=marcar_lote_procesado,
        provide_context=True
    )

    t3 = BashOperator(
        task_id='dbt_run',
        bash_command='cd /opt/airflow/dbt_project/mimicToOmop && rm -rf dbt_packages && /home/airflow/.local/bin/dbt deps && /home/airflow/.local/bin/dbt run --profiles-dir .'
    )

    t4 = BashOperator(
        task_id='dbt_test',
        bash_command='cd /opt/airflow/dbt_project/mimicToOmop && /home/airflow/.local/bin/dbt test --profiles-dir .'
    )

    t1 >> t2 >> t3 >> t4
