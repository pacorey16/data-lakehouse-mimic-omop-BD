CREATE SCHEMA IF NOT EXISTS hive.mimic_vocabulary
WITH (location = 's3a://mimic-vocabulary/');

CREATE TABLE IF NOT EXISTS hive.mimic_vocabulary.concept (
    concept_id         VARCHAR,
    concept_name       VARCHAR,
    domain_id          VARCHAR,
    vocabulary_id      VARCHAR,
    concept_class_id   VARCHAR,
    standard_concept   VARCHAR,
    concept_code       VARCHAR,
    valid_start_date   VARCHAR,
    valid_end_date     VARCHAR,
    invalid_reason     VARCHAR
)
WITH (
    format = 'CSV',
    external_location = 's3a://mimic-vocabulary/concept/',
    skip_header_line_count = 1
);

CREATE TABLE IF NOT EXISTS hive.mimic_vocabulary.concept_relationship (
    concept_id_1       VARCHAR,
    concept_id_2       VARCHAR,
    relationship_id    VARCHAR,
    valid_start_date   VARCHAR,
    valid_end_date     VARCHAR,
    invalid_reason     VARCHAR
)
WITH (
    format = 'CSV',
    external_location = 's3a://mimic-vocabulary/concept_relationship/',
    skip_header_line_count = 1
);
