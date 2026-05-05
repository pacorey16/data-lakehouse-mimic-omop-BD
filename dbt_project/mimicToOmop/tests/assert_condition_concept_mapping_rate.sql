{{ config(severity='warn') }}
-- Falla si más del 50% de los diagnósticos no tienen mapeo ICD->SNOMED (condition_concept_id = 0).
-- Ajusta el umbral según la calidad esperada del vocabulario.
SELECT
    COUNT(*) AS total,
    SUM(CASE WHEN condition_concept_id = 0 THEN 1 ELSE 0 END) AS sin_mapeo,
    CAST(SUM(CASE WHEN condition_concept_id = 0 THEN 1 ELSE 0 END) AS DOUBLE) / COUNT(*) AS ratio_sin_mapeo
FROM {{ ref('condition_ocurrence') }}
HAVING CAST(SUM(CASE WHEN condition_concept_id = 0 THEN 1 ELSE 0 END) AS DOUBLE) / COUNT(*) > 0.5
