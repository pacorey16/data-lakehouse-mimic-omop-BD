# Docker — Infraestructura

Contiene el `docker-compose.yml` y todas las configuraciones necesarias para levantar el stack completo del Data Lakehouse.

## Servicios

| Contenedor | Imagen | Puerto | Función |
|---|---|---|---|
| `postgres` | postgres:13 | 5435 | Backend de Airflow y Hive Metastore |
| `minio` | minio/minio | 9000 / 9001 | Almacenamiento S3 compatible |
| `minio-init` | minio/mc | — | Crea los buckets al arrancar |
| `hive-metastore` | apache/hive:3.1.3 | 9083 | Catálogo de metadatos Iceberg/Hive |
| `trino` | trinodb/trino | 8082 | Motor SQL distribuido |
| `airflow` | (Dockerfile.airflow) | 8083 | Orquestación del pipeline |
| `spark` | jupyter/pyspark-notebook | 8888 | Análisis exploratorio |

## Buckets MinIO (creados automáticamente)

| Bucket | Contenido |
|---|---|
| `landing-zone` | Lotes CSV anuales antes de procesar |
| `mimic-bronze` | Datos MIMIC crudos (CSV, tablas Hive externas) |
| `omop-silver` | Tablas OMOP transformadas (Parquet, Iceberg) |
| `mimic-vocabulary` | Vocabulario OMOP (CONCEPT, CONCEPT_RELATIONSHIP) |

## Configuración de credenciales

Los ficheros de configuración de Trino contienen credenciales y **no se versionan** (están en `.gitignore`). Se generan a partir de templates con el comando:

```bash
# Desde la raíz del proyecto
make generate-config
```

Esto lee `docker/.env` y genera:
- `docker/trino/conf/catalog/iceberg.properties`
- `docker/trino/conf/catalog/hive.properties`
- `docker/trino/conf/core-site.xml`

### Crear docker/.env

```bash
make env        # copia docker/.env.example → docker/.env
vi docker/.env  # editar con tus credenciales
```

Contenido mínimo de `docker/.env`:

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=tu_password
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=tu_password
AIRFLOW_FERNET_KEY=<genera con: python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())">
```

## Levantar el stack

```bash
# Desde la raíz del proyecto (recomendado — usa el Makefile)
make up

# O directamente con docker compose
cd docker && docker compose up -d
```

## Comandos útiles

```bash
make logs           # ver logs en tiempo real
make down           # parar todos los servicios
make reset          # parar y eliminar todos los volúmenes (reset total)
```

## Registrar tablas en Hive Metastore

Tras el primer arranque, hay que registrar los esquemas y tablas. El fichero `trino/init_mimic_bronze.sql` está montado en el contenedor y se ejecuta con:

```bash
make init-tables
# equivalente a:
docker exec trino trino --file /etc/trino/init_mimic_bronze.sql
```

Esto crea:
- `hive.mimic_bronze` — tablas MIMIC (admissions, patients, diagnoses_icd)
- `hive.vocabulary` — tablas de vocabulario OMOP (concept, concept_relationship)
- `iceberg.omop` — esquema de destino OMOP en omop-silver

## JARs de Spark/Iceberg (notebook)

Los JARs del notebook de Spark/Iceberg superan el límite de GitHub. Descargar antes de abrir el notebook:

```bash
mkdir -p docker/notebooks/jars

curl -L -o docker/notebooks/jars/iceberg-spark-runtime-3.5_2.12-1.6.1.jar \
  https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.6.1/iceberg-spark-runtime-3.5_2.12-1.6.1.jar

curl -L -o docker/notebooks/jars/hadoop-aws-3.3.4.jar \
  https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar

curl -L -o docker/notebooks/jars/aws-java-sdk-bundle-1.12.262.jar \
  https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar
```
