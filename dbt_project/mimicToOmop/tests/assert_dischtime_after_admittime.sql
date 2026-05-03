-- Devuelve ingresos donde la fecha de alta es anterior a la de ingreso.
-- Si el resultado tiene filas, el test falla.
SELECT
    hadm_id,
    admittime,
    dischtime
FROM {{ source('mimic', 'admissions') }}
WHERE dischtime IS NOT NULL
  AND dischtime < admittime
