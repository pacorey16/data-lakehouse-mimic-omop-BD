-- ==============================================================
-- VALIDACIÓN DE DATOS (CONTEO BRONZE)
-- ==============================================================

SELECT 
    (SELECT COUNT(*) FROM hive.mimic_bronze.patients) as total_pacientes,
    (SELECT COUNT(*) FROM hive.mimic_bronze.admissions) as total_admisiones,
    (SELECT COUNT(*) FROM hive.mimic_bronze.diagnoses_icd) as total_diagnosticos;