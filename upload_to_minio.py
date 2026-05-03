import boto3
import os

# 1. Configuración de conexión a tu MinIO local
s3_client = boto3.client('s3',
    endpoint_url='http://localhost:9000',
    aws_access_key_id='minioadmin',    
    aws_secret_access_key='minioadmin' 
)

bucket_name = 'mimic-bronze'

# 2. Diccionario de archivos (Ruta local -> Ruta en el Bucket)
archivos_a_subir = {
    'docker/data/admissions.csv': 'admissions/admissions.csv',
    'docker/data/patients.csv': 'patients/patients.csv',
    'docker/data/diagnoses_icd.csv': 'diagnoses_icd/diagnoses_icd.csv'
}

print("🚀 Iniciando carga de datos reales en MinIO...")

for archivo_local, ruta_minio in archivos_a_subir.items():
    if os.path.exists(archivo_local):
        print(f"⏳ Subiendo {archivo_local}...")
        try:
            s3_client.upload_file(archivo_local, bucket_name, ruta_minio)
            print(f"Subido con éxito")
        except Exception as e:
            print(f"Error al subir: {e}")
    else:
        print(f"ERROR: No encuentro el archivo en {archivo_local}")

print("\n¡Proceso terminado! Ya puedes consultar en Trino.")