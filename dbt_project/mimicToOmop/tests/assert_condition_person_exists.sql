{{ config(severity='warn') }}
-- Devuelve diagnósticos cuyo person_id no aparece en mimic_bronze.patients.
-- WARN esperado: el simulador asigna cada paciente al año de su PRIMERA admisión.
-- En años donde un paciente ya existente vuelve a ser admitido, aparece en
-- diagnoses_icd pero NO en patients de ese año (ya fue cargado en un año anterior).
-- Este warning desaparece una vez que todos los lotes han sido procesados.
SELECT
    co.condition_occurrence_id,
    co.person_id
FROM {{ ref('condition_occurrence') }} co
LEFT JOIN {{ source('mimic', 'patients') }} p ON co.person_id = p.subject_id
WHERE p.subject_id IS NULL
