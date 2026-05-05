# Datos Simulados

Scripts que preparan los datos de entrada del pipeline: trocea los CSV originales de MIMIC-IV en lotes anuales y los sube a MinIO.

## Estructura

```
datos_simulados/
├── simulador_lotes.py      # Trocea MIMIC en lotes anuales y los sube a landing-zone
├── upload_vocabulario.py   # Sube el vocabulario OMOP a mimic-vocabulary
├── upload_to_minio.py      # Módulo auxiliar de subida a MinIO (usado por simulador)
└── lotes_landing/          # Lotes generados (no versionado)
    ├── 2110/
    │   ├── admissions.csv
    │   ├── patients.csv
    │   └── diagnoses_icd.csv
    └── ...
```

## Requisitos previos

Los CSV de MIMIC-IV deben estar en `data/` (raíz del proyecto):

```
data/
├── admissions.csv
├── patients.csv
└── diagnoses_icd.csv
```

Los scripts leen las credenciales de MinIO desde la variable de entorno `MINIO_ROOT_PASSWORD` (y `MINIO_ROOT_USER`). El Makefile los exporta automáticamente desde `docker/.env`.

## 1. Generar y subir los lotes anuales

```bash
# Desde la raíz del proyecto (recomendado)
make simulate

# O manualmente exportando las credenciales
export $(grep -v '^#' docker/.env | xargs)
python3 datos_simulados/simulador_lotes.py
```

**Qué hace `simulador_lotes.py`:**
- Lee `data/admissions.csv`, `data/patients.csv`, `data/diagnoses_icd.csv`
- Particiona por año de ingreso (`admittime`)
- Guarda cada lote en `datos_simulados/lotes_landing/YYYY/`
- Sube todos los lotes al bucket `landing-zone` de MinIO

Cada ejecución del DAG de Airflow consumirá uno de estos lotes.

## 2. Subir el vocabulario OMOP

El vocabulario OMOP es necesario para mapear códigos ICD a conceptos estándar SNOMED. Sin él, los diagnósticos se almacenan con `condition_concept_id = 0` (sin mapeo).

### Descargar el vocabulario

1. Accede a [Athena OHDSI](https://athena.ohdsi.org)
2. Selecciona los vocabularios **ICD9CM** e **ICD10CM** (mínimo)
3. Descarga y descomprime en `data/Concept/`:

```
data/Concept/
├── CONCEPT.csv
└── CONCEPT_RELATIONSHIP.csv
```

### Subir a MinIO

```bash
# Desde la raíz del proyecto (recomendado)
make upload-vocab

# O manualmente
export $(grep -v '^#' docker/.env | xargs)
python3 datos_simulados/upload_vocabulario.py
```

Los ficheros se suben a:
- `s3://mimic-vocabulary/concept/CONCEPT.csv`
- `s3://mimic-vocabulary/concept_relationship/CONCEPT_RELATIONSHIP.csv`

## Notas sobre los datos generados

- `lotes_landing/` no se versiona (`.gitignore`)
- Algunos años pueden no tener lote de `patients.csv` si ese año no hay primera admisión de ningún paciente nuevo — es comportamiento normal del simulador
- El DAG procesa **un lote por ejecución** en orden cronológico
