#!/bin/bash
set -e

echo "Initializing Airflow database..."
airflow db upgrade || airflow db init || { echo "Database initialization failed"; exit 1; }

echo "Database initialized successfully!"

echo "Creating admin user..."
airflow users create \
    --username admin \
    --password admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com || echo "User already exists"

echo "Adding Postgres connection..."
airflow connections add postgres_default \
    --conn-type postgres \
    --conn-host postgres \
    --conn-port 5432 \
    --conn-login "${POSTGRES_USER}" \
    --conn-password "${POSTGRES_PASSWORD}" \
    --conn-schema airflow_db || echo "Connection already exists"

echo "Starting Airflow scheduler in background..."
airflow scheduler &

echo "Starting Airflow webserver..."
exec airflow webserver --port 8080