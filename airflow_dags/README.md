# Airflow DAGs

Define el flujo de orquestación del pipeline de ingesta clínica.

## DAG: `ingesta_hospitalaria_anual`

Procesa un lote anual de datos MIMIC-IV por ejecución: lo sube a la capa Bronze, lo transforma a OMOP con dbt y valida la calidad de los datos.

### Tareas

```
subir_lote_bronze → marcar_lote_procesado → dbt_run → dbt_test
```

| Tarea | Tipo | Descripción |
|---|---|---|
| `subir_lote_bronze` | S3Hook | Mueve el lote anual de `landing-zone/YYYY/` a `mimic-bronze/` |
| `marcar_lote_procesado` | BashOperator | Elimina los ficheros locales del lote ya procesado |
| `dbt_run` | BashOperator | Ejecuta `dbt run` — transforma Bronze → Silver (OMOP) |
| `dbt_test` | BashOperator | Ejecuta `dbt test` — valida la calidad de los datos |

### Scheduling

El DAG está configurado para ejecución manual o diaria. En condiciones normales se dispara una vez por año simulado (un lote = un año de datos MIMIC).

### Cómo ejecutar

1. Abre Airflow en http://localhost:8083
2. Activa el DAG `ingesta_hospitalaria_anual` (toggle ON)
3. Pulsa **Trigger DAG** para procesar el siguiente lote disponible
4. Repite hasta consumir todos los lotes de `landing-zone`

### Conexión MinIO

El DAG usa la conexión de Airflow `minio_conn` (tipo AWS) configurada como variable de entorno en `docker-compose.yml`:

```
AIRFLOW_CONN_MINIO_CONN=aws://${MINIO_ROOT_USER}:${MINIO_ROOT_PASSWORD}@?endpoint_url=http%3A%2F%2Fminio%3A9000
```

Las credenciales se leen automáticamente de `docker/.env`.

### Comandos dbt en el DAG

```bash
# dbt_run ejecuta:
cd /opt/airflow/dbt_project/mimicToOmop && dbt deps && dbt run --profiles-dir .

# dbt_test ejecuta:
cd /opt/airflow/dbt_project/mimicToOmop && dbt test --profiles-dir .
```
