# dbt — Transformación MIMIC → OMOP CDM

Proyecto dbt que transforma los datos clínicos de MIMIC-IV (capa Bronze) al estándar OMOP CDM (capa Silver) usando Trino como motor SQL e Iceberg como formato de tabla de destino.

## Modelos

### `person`

Mapea los pacientes de MIMIC al concepto OMOP `person`.

**Fuente:** `hive.mimic_bronze.patients`

| Campo MIMIC | Campo OMOP | Transformación |
|---|---|---|
| `subject_id` | `person_id` | directo |
| `gender` | `gender_concept_id` | M → 8507 (Male) / F → 8532 (Female) |
| `anchor_year` | `year_of_birth` | directo |
| `gender` | `gender_source_value` | directo |

Materialización: **incremental (append)** — clave única `person_id`.

### `condition_occurrence`

Mapea los diagnósticos de MIMIC al concepto OMOP `condition_occurrence`, incluyendo el mapeo de códigos ICD a SNOMED mediante el vocabulario OMOP.

**Fuentes:**
- `hive.mimic_bronze.diagnoses_icd` — diagnósticos ICD
- `hive.mimic_bronze.admissions` — fechas de ingreso/alta
- `hive.vocabulary.concept` — lookup de códigos ICD
- `hive.vocabulary.concept_relationship` — mapeo ICD → SNOMED ("Maps to")

| Campo | Descripción |
|---|---|
| `condition_occurrence_id` | Surrogate key (hash de subject_id + hadm_id + seq_num) |
| `person_id` | subject_id del paciente |
| `condition_concept_id` | Concepto SNOMED estándar (0 si no hay mapeo) |
| `condition_source_concept_id` | Concepto ICD fuente (0 si no hay mapeo) |
| `condition_source_value` | Código ICD original |
| `condition_start_date` | Fecha de admisión |
| `condition_end_date` | Fecha de alta |
| `condition_type_concept_id` | 32817 (EHR encounter diagnosis) |

Materialización: **incremental (append)** — filtra por `condition_start_date > MAX(fecha ya cargada)`.

## Fuentes (sources.yml)

```
hive.mimic_bronze   → admissions, patients, diagnoses_icd
hive.vocabulary     → concept, concept_relationship
```

## Tests de calidad (34 en total)

### Tests de columna (schema.yml)

- `admissions`: `hadm_id` único y no nulo, `hospital_expire_flag` en {0,1}, `admission_type` no nulo
- `patients`: `subject_id` único y no nulo, `gender` en {M, F}
- `diagnoses_icd`: campos obligatorios no nulos, `icd_version` en {9, 10}
- `condition_occurrence`: `condition_occurrence_id` único, campos clave no nulos, `condition_type_concept_id` = 32817

### Tests personalizados (tests/)

| Test | Severidad | Descripción |
|---|---|---|
| `assert_condition_dates_coherent` | ERROR | `condition_end_date` no puede ser anterior a `condition_start_date` |
| `assert_condition_concept_mapping_rate` | WARN | Avisa si más del 50% de diagnósticos no tienen mapeo SNOMED |
| `assert_condition_visit_exists` | ERROR | Todos los diagnósticos deben referenciar una admisión existente |
| `assert_condition_person_exists` | WARN | Diagnósticos que referencian pacientes no cargados aún |
| `assert_dischtime_after_admittime` | ERROR | La fecha de alta no puede ser anterior a la de ingreso |

> El warning `assert_condition_person_exists` aparece cuando hay años con admissions/diagnoses pero sin patients (el simulador asigna el paciente al año de su primera admisión, por lo que puede haber diagnósticos de años intermedios sin registro de paciente).

## Ejecución manual

```bash
# Desde dentro del contenedor Airflow (o con dbt instalado localmente)
cd /opt/airflow/dbt_project/mimicToOmop

dbt deps                          # instala paquetes (dbt_utils)
dbt run --profiles-dir .          # ejecuta todos los modelos
dbt test --profiles-dir .         # ejecuta los 34 tests
dbt docs generate --profiles-dir . # genera documentación
dbt docs serve --profiles-dir . --port 8085  # sirve docs en localhost:8085
```

## Configuración de conexión (profiles.yml)

El proyecto usa Trino como adaptador, apuntando al contenedor `trino:8080` con los esquemas:
- Output: `iceberg.omop`
- Fuentes: `hive.mimic_bronze`, `hive.vocabulary`
