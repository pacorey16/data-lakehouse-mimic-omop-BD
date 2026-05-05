-- Devuelve registros donde condition_end_date es anterior a condition_start_date.
SELECT
    condition_occurrence_id,
    person_id,
    condition_start_date,
    condition_end_date
FROM {{ ref('condition_occurrence') }}
WHERE condition_end_date IS NOT NULL
  AND condition_end_date < condition_start_date
