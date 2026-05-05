# Datos Simulados

Contiene el script `simulador_lotes.py`, que trocea los CSV originales de MIMIC en fragmentos diarios, simulando la llegada incremental de datos clínicos para probar la ingesta del pipeline.

## Archivos excluidos del repositorio

Los datos generados **no se versionan** (están en `.gitignore`):

- `lotes_landing/` — lotes CSV generados por `simulador_lotes.py`
- `*.csv` / `*.parquet` — datos originales de MIMIC

## Generar los lotes y subir a MinIO

### 1. Datos clínicos (MIMIC)

El script `simulador_lotes.py` genera los lotes y los **sube automáticamente** al bucket `landing-zone` de MinIO:

```bash
# Desde la raíz del proyecto
python datos_simulados/simulador_lotes.py
```

Esto crea los archivos en `datos_simulados/lotes_landing/` y los carga en `s3://landing-zone/`.

> Requiere que el contenedor MinIO esté levantado (`docker compose up -d minio`).

### 2. Vocabulario OMOP

Los archivos de vocabulario (tablas `concept`, `concept_relationship`, etc.) se suben al bucket `mimic-vocabulary` con:

```bash
python datos_simulados/upload_vocabulario.py
```

Descarga los ficheros CSV del vocabulario desde la fuente oficial (ATHENA/OHDSI) y colócalos en `datos_simulados/vocabulario/` antes de ejecutar este script.

### 3. Ejecutar el pipeline completo

Una vez subidos los datos, activa el DAG en Airflow (`http://localhost:8083`) para ejecutar la transformación completa:

```
upload_to_minio → dbt run → dbt test
```
