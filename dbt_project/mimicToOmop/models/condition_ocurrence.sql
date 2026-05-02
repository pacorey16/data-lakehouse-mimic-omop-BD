{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'append',
    unique_key = 'condition_occurrence_id'  
    )
}}
    
WITH diagnoses AS (
    SELECT * FROM {{ source('mimic', 'diagnoses_icd') }}
),
admissions AS (
    SELECT * FROM {{ source('mimic', 'admissions') }}
    {% if is_incremental() %}
    WHERE admittime > (SELECT MAX(condition_start_date) FROM {{ this }})
    {% endif %}
),

mapping AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['subject_id', 'hadm_id', 'seq_num']) }} AS condition_occurrence_id,
        d.subject_id AS person_id,
        d.icd_code AS condition_source_value,
        d.hadm_id AS visit_occurrence_id,
        CAST(a.admittime AS DATE) AS condition_start_date,
        CAST(a.dischtime AS DATE) AS condition_end_date,
        32817 AS condition_type_concept_id,
        0 AS condition_concept_id,
        0 AS condition_source_concept_id
    FROM diagnoses d
    JOIN admissions a ON d.hadm_id = a.hadm_id
)
SELECT * FROM mapping



