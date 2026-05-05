-- 1. Esquemas
CREATE SCHEMA IF NOT EXISTS hive.mimic_bronze WITH (location = 's3://mimic-bronze/');
CREATE SCHEMA IF NOT EXISTS iceberg.omop WITH (location = 's3://omop-silver/');
CREATE SCHEMA IF NOT EXISTS hive.vocabulary WITH (location = 's3://mimic-vocabulary/');

-- 2. Vocabulario OMOP
CREATE TABLE IF NOT EXISTS hive.vocabulary.concept (
    concept_id        VARCHAR,
    concept_name      VARCHAR,
    domain_id         VARCHAR,
    vocabulary_id     VARCHAR,
    concept_class_id  VARCHAR,
    standard_concept  VARCHAR,
    concept_code      VARCHAR,
    valid_start_date  VARCHAR,
    valid_end_date    VARCHAR,
    invalid_reason    VARCHAR
) WITH (
    format = 'CSV',
    external_location = 's3://mimic-vocabulary/concept/',
    skip_header_line_count = 1
);

CREATE TABLE IF NOT EXISTS hive.vocabulary.concept_relationship (
    concept_id_1     VARCHAR,
    concept_id_2     VARCHAR,
    relationship_id  VARCHAR,
    valid_start_date VARCHAR,
    valid_end_date   VARCHAR,
    invalid_reason   VARCHAR
) WITH (
    format = 'CSV',
    external_location = 's3://mimic-vocabulary/concept_relationship/',
    skip_header_line_count = 1
);

-- 3. Tablas MIMIC Bronze
CREATE TABLE IF NOT EXISTS hive.mimic_bronze.admissions (
    subject_id           VARCHAR,
    hadm_id              VARCHAR,
    admittime            VARCHAR,
    dischtime            VARCHAR,
    deathtime            VARCHAR,
    admission_type       VARCHAR,
    admit_provider_id    VARCHAR,
    admission_location   VARCHAR,
    discharge_location   VARCHAR,
    insurance            VARCHAR,
    language             VARCHAR,
    marital_status       VARCHAR,
    race                 VARCHAR,
    edregtime            VARCHAR,
    edouttime            VARCHAR,
    hospital_expire_flag VARCHAR
) WITH (
    format = 'CSV',
    external_location = 's3://mimic-bronze/admissions/',
    skip_header_line_count = 1
);

CREATE TABLE IF NOT EXISTS hive.mimic_bronze.patients (
    subject_id        VARCHAR,
    gender            VARCHAR,
    anchor_age        VARCHAR,
    anchor_year       VARCHAR,
    anchor_year_group VARCHAR,
    dod               VARCHAR
) WITH (
    format = 'CSV',
    external_location = 's3://mimic-bronze/patients/',
    skip_header_line_count = 1
);

CREATE TABLE IF NOT EXISTS hive.mimic_bronze.diagnoses_icd (
    subject_id  VARCHAR,
    hadm_id     VARCHAR,
    seq_num     VARCHAR,
    icd_code    VARCHAR,
    icd_version VARCHAR
) WITH (
    format = 'CSV',
    external_location = 's3://mimic-bronze/diagnoses_icd/',
    skip_header_line_count = 1
);
