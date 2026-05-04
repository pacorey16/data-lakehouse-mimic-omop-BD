-- Devuelve diagnósticos cuyo visit_occurrence_id no existe en admissions.
SELECT
    co.condition_occurrence_id,
    co.visit_occurrence_id
FROM {{ ref('condition_ocurrence') }} co
LEFT JOIN {{ source('mimic', 'admissions') }} a ON co.visit_occurrence_id = a.hadm_id
WHERE a.hadm_id IS NULL
