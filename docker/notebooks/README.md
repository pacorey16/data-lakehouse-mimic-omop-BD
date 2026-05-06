# Spark Analytics

Notebooks PySpark para análisis exploratorio de los datos OMOP almacenados en la capa Silver (`omop-silver`).

## Acceso

El servidor Jupyter arranca con el stack Docker:

```
http://localhost:8888
```

No requiere contraseña (token vacío configurado en docker-compose).

## Conexión a las tablas Iceberg

Los notebooks se conectan a MinIO y leen las tablas Iceberg de `omop-silver` mediante el conector Iceberg de Spark:

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("OMOP Analytics") \
    .config("spark.jars", "/home/jovyan/work/jars/iceberg-spark-runtime-3.5_2.12-1.6.1.jar,"
                          "/home/jovyan/work/jars/hadoop-aws-3.3.4.jar,"
                          "/home/jovyan/work/jars/aws-java-sdk-bundle-1.12.262.jar") \
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
    .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog") \
    .config("spark.sql.catalog.iceberg.type", "hive") \
    .config("spark.sql.catalog.iceberg.uri", "thrift://hive-metastore:9083") \
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
    .config("spark.hadoop.fs.s3a.access.key", "minioadmin") \
    .config("spark.hadoop.fs.s3a.secret.key", "<MINIO_ROOT_PASSWORD>") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .getOrCreate()

# Leer tablas OMOP
persons    = spark.table("iceberg.omop.person")
conditions = spark.table("iceberg.omop.condition_ocurrence")
```

## Requisitos — JARs

Los JARs no se versionan. Descárgalos antes de usar el notebook:

```bash
mkdir -p docker/notebooks/jars

curl -L -o docker/notebooks/jars/iceberg-spark-runtime-3.5_2.12-1.6.1.jar \
  https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.6.1/iceberg-spark-runtime-3.5_2.12-1.6.1.jar

curl -L -o docker/notebooks/jars/hadoop-aws-3.3.4.jar \
  https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar

curl -L -o docker/notebooks/jars/aws-java-sdk-bundle-1.12.262.jar \
  https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar
```

## Tablas disponibles

| Tabla | Esquema Trino | Descripción |
|---|---|---|
| `person` | `iceberg.omop.person` | Pacientes con género mapeado a SNOMED |
| `condition_occurrence` | `iceberg.omop.condition_ocurrence` | Diagnósticos ICD mapeados a OMOP |
