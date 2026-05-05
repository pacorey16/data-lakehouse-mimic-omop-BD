{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'visit_occurrence_id'
  )
}}

WITH raw_admissions AS (
    SELECT * FROM {{ source('mimic', 'admissions') }}
    {% if is_incremental() %}
    WHERE TRY_CAST(date_parse(admittime, '%Y-%m-%d %H:%i:%s') AS DATE) > (SELECT MAX(visit_start_date) FROM {{ this }})
    {% endif %}
),

transformed AS (
    SELECT
        a.hadm_id                                                              AS visit_occurrence_id,
        a.subject_id                                                           AS person_id,
        CASE
            WHEN UPPER(a.admission_type) LIKE '%EMERGENCY%' THEN 9203
            WHEN UPPER(a.admission_type) LIKE '%URGENT%'    THEN 9203
            WHEN UPPER(a.admission_type) LIKE '%ELECTIVE%'  THEN 9201
            ELSE 9201
        END                                                                    AS visit_concept_id,
        TRY_CAST(date_parse(a.admittime, '%Y-%m-%d %H:%i:%s') AS DATE)        AS visit_start_date,
        TRY_CAST(date_parse(a.dischtime, '%Y-%m-%d %H:%i:%s') AS DATE)        AS visit_end_date,
        32817                                                                  AS visit_type_concept_id,
        a.admission_type                                                       AS visit_source_value,
        0                                                                      AS visit_source_concept_id
    FROM raw_admissions a
    INNER JOIN {{ ref('person') }} p ON CAST(a.subject_id AS VARCHAR) = CAST(p.person_id AS VARCHAR)
)

SELECT * FROM transformed
