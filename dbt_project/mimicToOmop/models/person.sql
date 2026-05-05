{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'person_id'
  )
}}

WITH raw_patients AS (
    SELECT * FROM {{ source('mimic', 'patients') }}
    {% if is_incremental() %}
    WHERE subject_id NOT IN (SELECT CAST(person_id AS VARCHAR) FROM {{ this }})
    {% endif %}
),

transformed AS (
    SELECT
        -- Tarea: Mapear subject_id a person_id
        subject_id AS person_id,
        
        -- Tarea: Estandarizar el género
        CASE 
            WHEN gender = 'M' THEN 8507 -- Masculino (Concept ID OMOP)
            WHEN gender = 'F' THEN 8532 -- Femenino (Concept ID OMOP)
            ELSE 0 
        END AS gender_concept_id,

        -- Tarea: Calcular el año de nacimiento
        anchor_year AS year_of_birth,
        
        -- Campos extra requeridos por OMOP
        gender AS gender_source_value,
        CAST(subject_id AS VARCHAR) AS person_source_value
    FROM raw_patients
)

SELECT * FROM transformed