-- 1. Esquemas
CREATE SCHEMA IF NOT EXISTS iceberg.omop_silver WITH (location = 's3://omop-silver/');
CREATE SCHEMA IF NOT EXISTS hive.mimic_bronze
WITH (location = 's3://mimic-bronze/');

-- 2. Tabla Admissions
CREATE TABLE IF NOT EXISTS hive.mimic_bronze.admissions (
    subject_id VARCHAR,
    hadm_id VARCHAR,
    admittime VARCHAR,
    dischtime VARCHAR,
    deathtime VARCHAR,
    admission_type VARCHAR,
    admit_provider_id VARCHAR,
    admission_location VARCHAR,
    discharge_location VARCHAR,
    insurance VARCHAR,
    language VARCHAR,
    marital_status VARCHAR,
    race VARCHAR,
    edregtime VARCHAR,
    edouttime VARCHAR,
    hospital_expire_flag VARCHAR
)
WITH (
    format = 'CSV',
    external_location = 's3://mimic-bronze/admissions/',
    skip_header_line_count = 1
);

-- 3. Tabla Patients
CREATE TABLE IF NOT EXISTS hive.mimic_bronze.patients (
    subject_id VARCHAR,
    gender VARCHAR,
    anchor_age VARCHAR,
    anchor_year VARCHAR,
    anchor_year_group VARCHAR,
    dod VARCHAR
)
WITH (
    format = 'CSV',
    external_location = 's3://mimic-bronze/patients/',
    skip_header_line_count = 1
);

-- 4. Tabla Diagnoses ICD
CREATE TABLE IF NOT EXISTS hive.mimic_bronze.diagnoses_icd (
    subject_id VARCHAR,
    hadm_id VARCHAR,
    seq_num VARCHAR,
    icd_code VARCHAR,
    icd_version VARCHAR
)
WITH (
    format = 'CSV',
    external_location = 's3://mimic-bronze/diagnoses_icd/',
    skip_header_line_count = 1
);
