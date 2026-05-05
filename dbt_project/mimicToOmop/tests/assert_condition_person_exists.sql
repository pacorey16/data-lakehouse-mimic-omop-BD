{{ config(severity='warn') }}
-- Devuelve diagnósticos cuyo person_id no existe en la tabla de pacientes.
SELECT
    co.condition_occurrence_id,
    co.person_id
FROM {{ ref('condition_ocurrence') }} co
LEFT JOIN {{ source('mimic', 'patients') }} p ON co.person_id = p.subject_id
WHERE p.subject_id IS NULL
