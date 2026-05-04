import boto3
from pathlib import Path

# Configuración de conexión a MinIO local
s3_client = boto3.client('s3',
    endpoint_url='http://localhost:9000',
    aws_access_key_id='minioadmin',    
    aws_secret_access_key='minioadmin' 
)

LANDING_BUCKET = 'landing-zone'

# Rutas relativas al directorio de este script
SCRIPT_DIR = Path(__file__).parent
LOTES_DEFAULT = SCRIPT_DIR / 'lotes_landing'


def upload_lotes_to_landing(lotes_dir: str = None) -> None:
    """
    Sube todos los lotes generados por simulador_lotes.py al bucket landing-zone.
    Estructura: landing-zone/YYYY/<tabla>.csv
    """
    if lotes_dir is None:
        lotes_dir = str(LOTES_DEFAULT)
    
    lotes_path = Path(lotes_dir)
    
    if not lotes_path.exists():
        print(f"❌ ERROR: No existe la carpeta {lotes_path}")
        return
    
    print(f"🚀 Subiendo lotes de {lotes_dir} a bucket '{LANDING_BUCKET}'...")
    archivos_subidos = 0
    
    for anio_folder in sorted(lotes_path.iterdir()):
        if anio_folder.is_dir():
            anio = anio_folder.name
            for csv_file in anio_folder.glob('*.csv'):
                tabla_name = csv_file.stem
                s3_key = f"{anio}/{tabla_name}.csv"
                
                try:
                    s3_client.upload_file(str(csv_file), LANDING_BUCKET, s3_key)
                    print(f"  ✅ Subido: {s3_key}")
                    archivos_subidos += 1
                except Exception as e:
                    print(f"  ❌ Error al subir {s3_key}: {e}")
    
    print(f"\n✨ Se subieron {archivos_subidos} archivos al landing-zone")


if __name__ == '__main__':
    upload_lotes_to_landing()