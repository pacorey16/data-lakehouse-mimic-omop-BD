# Data Lakehouse MIMIC → OMOP

Pipeline de datos clínicos que ingiere registros hospitalarios del dataset **MIMIC-IV** de forma incremental (un lote por año) y los transforma al estándar **OMOP CDM**, almacenándolos en formato Iceberg sobre MinIO.

---

## Arquitectura

```
  CSV MIMIC-IV          MinIO                  Trino + dbt           MinIO
(admissions, patients  landing-zone  →  mimic-bronze  →  OMOP CDM  →  omop-silver
  diagnoses_icd)       (lotes anuales)   (Hive / CSV)    (person,      (Iceberg /
                                                          condition)    Parquet)

Orquestación: Airflow DAG · Catálogo: Hive Metastore · Backend: PostgreSQL
```

### Stack tecnológico

| Servicio | Rol |
|---|---|
| **MinIO** | Almacenamiento S3 (data lake) |
| **Apache Iceberg** | Formato de tabla ACID con versionado |
| **Hive Metastore** | Catálogo de metadatos |
| **Trino** | Motor SQL distribuido |
| **dbt** | Transformaciones SQL con tests integrados |
| **Airflow** | Orquestación y scheduling del pipeline |
| **PostgreSQL** | Backend de Airflow y Hive Metastore |
| **Spark / Jupyter** | Análisis exploratorio (capa Gold) |

### URLs de los servicios (en local)

| Servicio | URL |
|---|---|
| Airflow | http://localhost:8083 |
| MinIO consola | http://localhost:9001 |
| Trino UI | http://localhost:8082 |
| Jupyter / Spark | http://localhost:8888 |

---

## Puesta en marcha

### Requisitos

- Docker Desktop en ejecución
- Python 3.9+ con `pandas` y `boto3` (`pip install pandas boto3`)
- CSV de MIMIC-IV (`admissions.csv`, `patients.csv`, `diagnoses_icd.csv`) en `data/`
- CSV de vocabulario OMOP (`CONCEPT.csv`, `CONCEPT_RELATIONSHIP.csv`) en `data/Concept/`
  → Descarga en [Athena OHDSI](https://athena.ohdsi.org) (selecciona vocabularios ICD9CM e ICD10CM)

### Instalación en un solo comando

```bash
# 1. Crear y editar las credenciales
make env
vi docker/.env          # cambia POSTGRES_PASSWORD, MINIO_ROOT_PASSWORD y AIRFLOW_FERNET_KEY

# 2. Setup completo (genera configs + arranca Docker + registra tablas + sube datos)
make setup
```

`make setup` hace automáticamente:
1. Genera los ficheros de config de Trino con tus credenciales
2. Arranca todos los contenedores Docker
3. Espera a que Trino esté operativo
4. Registra los esquemas y tablas en Hive Metastore
5. Sube el vocabulario OMOP a MinIO
6. Genera los lotes anuales de MIMIC y los sube al landing-zone

### Ejecutar el pipeline

Una vez completado el setup, abre Airflow en http://localhost:8083 y dispara el DAG `ingesta_hospitalaria_anual`. Cada ejecución procesa un lote anual:

```
subir_lote_bronze → marcar_lote_procesado → dbt_run → dbt_test
```

Para ver todos los comandos disponibles:

```bash
make help
```

---

## Estructura del repositorio

```
├── Makefile                    # Punto de entrada principal
├── data/                       # CSVs de MIMIC-IV (no versionados)
│   ├── admissions.csv
│   ├── patients.csv
│   ├── diagnoses_icd.csv
│   └── Concept/                # Vocabulario OMOP (no versionado)
│       ├── CONCEPT.csv
│       └── CONCEPT_RELATIONSHIP.csv
├── docker/                     # Infraestructura Docker
│   ├── docker-compose.yml
│   ├── .env.example            # Plantilla de credenciales
│   └── trino/conf/             # Config de Trino (generada con make generate-config)
├── datos_simulados/            # Scripts de generación y subida de lotes
├── dbt_project/mimicToOmop/    # Modelos dbt (transformación MIMIC → OMOP)
├── airflow_dags/               # Definición del DAG de Airflow
├── scripts/                    # Scripts de utilidad
│   └── generate_config.py      # Genera configs de Trino desde docker/.env
└── spark_analytics/            # Notebooks PySpark (capa Gold)
```

---

## Capas de datos

| Capa | Bucket MinIO | Formato | Conector Trino |
|---|---|---|---|
| Landing | `landing-zone` | CSV por año | — |
| Bronze | `mimic-bronze` | CSV | Hive (external tables) |
| Silver | `omop-silver` | Parquet (Iceberg) | Iceberg |
| Vocabulario | `mimic-vocabulary` | CSV | Hive (external tables) |
