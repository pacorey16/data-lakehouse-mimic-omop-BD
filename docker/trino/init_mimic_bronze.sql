-- 1. Esquemas
CREATE SCHEMA IF NOT EXISTS iceberg.omop_silver WITH (location = 's3a://omop-silver/');
CREATE SCHEMA IF NOT EXISTS hive.mimic_bronze
WITH (location = 's3a://mimic-bronze/');

-- 2. Tabla Admissions (Todo VARCHAR)
CREATE TABLE IF NOT EXISTS hive.mimic_bronze.admissions (
    subject_id VARCHAR,
    hadm_id VARCHAR,
    admittime VARCHAR,
    dischtime VARCHAR,
    deathtime VARCHAR,
    admission_type VARCHAR,
    admission_location VARCHAR,
    discharge_location VARCHAR,
    insurance VARCHAR,
    language VARCHAR,
    religion VARCHAR,
    marital_status VARCHAR,
    ethnicity VARCHAR,
    edregtime VARCHAR,
    edouttime VARCHAR,
    diagnosis VARCHAR,
    hospital_expire_flag VARCHAR,
    has_chartevents_data VARCHAR
) 
WITH (
    format = 'CSV',
    external_location = 's3a://mimic-bronze/admissions/',
    skip_header_line_count = 1
);

-- 3. Tabla Patients (Todo VARCHAR)
CREATE TABLE IF NOT EXISTS hive.mimic_bronze.patients (
    subject_id VARCHAR,
    gender VARCHAR,
    dob VARCHAR,
    dod VARCHAR,
    dod_hosp VARCHAR,
    dod_ssn VARCHAR,
    expire_flag VARCHAR
) 
WITH (
    format = 'CSV',
    external_location = 's3a://mimic-bronze/patients/',
    skip_header_line_count = 1
);

-- 4. Tabla Diagnoses (Todo VARCHAR)
CREATE TABLE IF NOT EXISTS hive.mimic_bronze.diagnoses_icd (
    subject_id VARCHAR,
    hadm_id VARCHAR,
    seq_num VARCHAR,
    icd9_code VARCHAR
) 
WITH (
    format = 'CSV',
    external_location = 's3a://mimic-bronze/diagnoses_icd/',
    skip_header_line_count = 1
);
