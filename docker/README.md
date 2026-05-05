# Docker

Contiene el archivo maestro `docker-compose.yml` y las configuraciones necesarias para levantar toda la infraestructura del Data Lakehouse: **MinIO** (object storage), **Trino** (query engine), **Hive Metastore** y **PostgreSQL**.

## Requisitos previos — Descargar los plugins de Trino

Los JARs de Hadoop/AWS superan el límite de 100 MB de GitHub y **no están en el repositorio**. Antes de levantar el stack hay que descargarlos manualmente:

```bash
mkdir -p docker/trino/plugin/hive

# hadoop-aws (conector S3A para MinIO)
curl -L -o docker/trino/plugin/hive/hadoop-aws-3.3.4.jar \
  https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar

# aws-java-sdk-bundle (dependencia de hadoop-aws)
curl -L -o docker/trino/plugin/hive/aws-java-sdk-bundle-1.12.262.jar \
  https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar
```

> Estos archivos están en `.gitignore` — no los subas al repo.

## Requisitos previos — JARs de Spark/Iceberg para el notebook

Los JARs del notebook de Spark/Iceberg también superan el límite de GitHub y **no están en el repositorio**. Hay que descargarlos en `docker/notebooks/jars/` antes de abrir el notebook:

```bash
mkdir -p docker/notebooks/jars

# Iceberg runtime para Spark 3.5
curl -L -o docker/notebooks/jars/iceberg-spark-runtime-3.5_2.12-1.6.1.jar \
  https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.6.1/iceberg-spark-runtime-3.5_2.12-1.6.1.jar

# Hadoop AWS (conector S3A para MinIO)
curl -L -o docker/notebooks/jars/hadoop-aws-3.3.4.jar \
  https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar

# AWS Java SDK bundle (dependencia de hadoop-aws)
curl -L -o docker/notebooks/jars/aws-java-sdk-bundle-1.12.262.jar \
  https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar
```

> Estos archivos están en `.gitignore` — no los subas al repo. El notebook los referencia desde `/home/jovyan/work/jars/` dentro del contenedor.

## Variables de entorno

Crea el archivo `docker/.env` (no se versiona) con:

```env
POSTGRES_USER=demo
POSTGRES_PASSWORD=demo123
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
```

## Levantar el stack

```bash
cd docker
docker compose up -d
```

| Servicio        | URL                        |
|-----------------|----------------------------|
| Trino UI        | http://localhost:8082       |
| MinIO consola   | http://localhost:9001       |
| PostgreSQL      | localhost:5435              |
| Hive Metastore  | thrift://localhost:9083     |
| Airflow         | http://localhost:8083       |
| Jupyter/Spark   | http://localhost:8888       |

## Resetear todo (borra datos)

```bash
docker compose down -v
```
