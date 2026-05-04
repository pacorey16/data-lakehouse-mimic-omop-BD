"""
Sube los archivos de vocabulario OMOP al bucket mimic-vocabulary en MinIO.

Origen: data/Concept/CONCEPT.csv, data/Concept/CONCEPT_RELATIONSHIP.csv
Destino MinIO:
  - s3a://mimic-vocabulary/concept/CONCEPT.csv
  - s3a://mimic-vocabulary/concept_relationship/CONCEPT_RELATIONSHIP.csv
"""

import boto3
from pathlib import Path

# Configuración de conexión a MinIO local
s3_client = boto3.client('s3',
    endpoint_url='http://localhost:9000',
    aws_access_key_id='minioadmin',    
    aws_secret_access_key='minioadmin' 
)

VOCABULARY_BUCKET = 'mimic-vocabulary'

# Rutas relativas al directorio de este script
SCRIPT_DIR = Path(__file__).parent


def upload_vocabulario_to_minio(vocab_dir: str = None) -> None:
    """
    Sube los archivos de vocabulario OMOP al bucket mimic-vocabulary.
    Busca en ../../data/Concept por defecto.
    """
    if vocab_dir is None:
        vocab_dir = str(SCRIPT_DIR.parent / "data" / "Concept")
    
    vocab_files = ['CONCEPT.csv', 'CONCEPT_RELATIONSHIP.csv']
    data_path = Path(vocab_dir)
    
    if not data_path.exists():
        print(f"❌ ERROR: No existe la carpeta {data_path}")
        return

    print(f"\n📚 Subiendo vocabulario a bucket '{VOCABULARY_BUCKET}'...")
    
    for file_name in vocab_files:
        file_path = data_path / file_name
        if file_path.exists():
            # Creamos una subcarpeta por tabla para que Trino no se confunda
            folder_name = file_name.replace('.csv', '').lower()
            s3_key = f"{folder_name}/{file_name}"
            
            try:
                s3_client.upload_file(str(file_path), VOCABULARY_BUCKET, s3_key)
                print(f"  ✅ Subido: {s3_key}")
            except Exception as e:
                print(f"  ❌ Error al subir {file_name}: {e}")
        else:
            print(f"  ⚠️ Advertencia: No se encontró {file_name} en {data_path}")

    print(f"\n✨ Vocabulario subido exitosamente")


if __name__ == '__main__':
    upload_vocabulario_to_minio()
