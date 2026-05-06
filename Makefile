.PHONY: help env generate-config up down reset logs wait init-tables upload-vocab simulate setup setup-infra load-data

DOCKER_DIR := docker
DATOS_DIR  := datos_simulados
ENV_FILE   := $(DOCKER_DIR)/.env

# ─────────────────────────────────────────────
help:
	@echo ""
	@echo "Data Lakehouse MIMIC-OMOP — comandos disponibles"
	@echo "─────────────────────────────────────────────────"
	@echo ""
	@echo "  Configuración inicial (ejecutar una sola vez):"
	@echo "    make env             Crea docker/.env a partir de docker/.env.example"
	@echo "    make generate-config Genera configs de Trino con las credenciales de docker/.env"
	@echo "    make setup           Todo en uno: generate-config + up + wait + init + vocab + lotes"
	@echo "    make setup-infra     Solo infraestructura: generate-config + up + wait + init-tables (repetible)"
	@echo "    make load-data       Solo datos: upload-vocab + simulate (solo primera vez)"
	@echo ""
	@echo "  Infraestructura:"
	@echo "    make up              Arranca todos los servicios Docker"
	@echo "    make down            Para todos los servicios"
	@echo "    make reset           Para y elimina todos los volúmenes (reset total)"
	@echo "    make logs            Muestra logs en tiempo real"
	@echo ""
	@echo "  Datos (se ejecutan automáticamente en 'make setup'):"
	@echo "    make wait            Espera a que Trino esté operativo"
	@echo "    make init-tables     Registra tablas MIMIC en Hive Metastore"
	@echo "    make upload-vocab    Sube vocabulario OMOP a MinIO"
	@echo "    make simulate        Genera lotes anuales y los sube al landing-zone"
	@echo ""
	@echo "  Requisitos previos a 'make setup':"
	@echo "    · data/admissions.csv, data/patients.csv, data/diagnoses_icd.csv"
	@echo "    · data/Concept/CONCEPT.csv, data/Concept/CONCEPT_RELATIONSHIP.csv"
	@echo "      (descarga en https://athena.ohdsi.org — selecciona ICD9CM e ICD10CM)"
	@echo ""

# ─────────────────────────────────────────────
# 1. Crear docker/.env
# ─────────────────────────────────────────────
env:
	@if [ -f $(ENV_FILE) ]; then \
		echo "$(ENV_FILE) ya existe. Edítalo si necesitas cambiar credenciales."; \
	else \
		cp $(DOCKER_DIR)/.env.example $(ENV_FILE); \
		echo "Fichero $(ENV_FILE) creado. Edita las credenciales antes de continuar:"; \
		echo "  vi $(ENV_FILE)"; \
	fi

# ─────────────────────────────────────────────
# 2. Generar configs de Trino desde templates
# ─────────────────────────────────────────────
generate-config:
	@[ -f $(ENV_FILE) ] || (echo "ERROR: Falta $(ENV_FILE). Ejecuta 'make env' primero." && exit 1)
	@ENV_FILE=$(ENV_FILE) python3 scripts/generate_config.py

# ─────────────────────────────────────────────
# 3. Docker
# ─────────────────────────────────────────────
up:
	@cd $(DOCKER_DIR) && docker compose up -d
	@echo "Servicios arrancados. Usa 'make logs' para ver el estado."

down:
	@cd $(DOCKER_DIR) && docker compose down

reset:
	@echo "AVISO: Esto eliminará todos los datos almacenados en los volúmenes Docker."
	@read -p "¿Seguro? (s/N): " c && [ "$$c" = "s" ] || exit 1
	@cd $(DOCKER_DIR) && docker compose down -v
	@echo "Reset completado."

logs:
	@cd $(DOCKER_DIR) && docker compose logs -f

# ─────────────────────────────────────────────
# 4. Esperar a que Trino esté listo
# ─────────────────────────────────────────────
wait:
	@echo "Esperando a que Trino esté operativo (puede tardar 2-5 min en Apple Silicon)..."
	@n=0; until docker exec trino trino --execute "SHOW CATALOGS" > /dev/null 2>&1; do \
		n=$$((n+1)); \
		if [ $$n -ge 36 ]; then echo "Timeout: Trino no arrancó en 6 minutos." && exit 1; fi; \
		printf "  esperando... ($$n/36)\r"; \
		sleep 10; \
	done
	@echo "  Trino listo.                    "

# ─────────────────────────────────────────────
# 5. Registrar tablas MIMIC en Hive Metastore
# ─────────────────────────────────────────────
init-tables:
	@echo "Registrando esquemas y tablas en Hive Metastore..."
	@docker exec trino trino --file /etc/trino/init_mimic_bronze.sql
	@echo "  Tablas registradas."

# ─────────────────────────────────────────────
# 6. Subir vocabulario OMOP a MinIO
# ─────────────────────────────────────────────
upload-vocab:
	@[ -f $(ENV_FILE) ] || (echo "ERROR: Falta $(ENV_FILE)" && exit 1)
	@[ -f data/Concept/CONCEPT.csv ] || ( \
		echo "ERROR: Falta data/Concept/CONCEPT.csv"; \
		echo "       Descarga el vocabulario en https://athena.ohdsi.org"; \
		echo "       (selecciona ICD9CM e ICD10CM) y coloca los CSV en data/Concept/"; \
		exit 1)
	@echo "Subiendo vocabulario OMOP a MinIO..."
	@export $$(grep -v '^#' $(ENV_FILE) | grep '=' | xargs) && \
		python3 $(DATOS_DIR)/upload_vocabulario.py

# ─────────────────────────────────────────────
# 7. Generar y subir lotes anuales
# ─────────────────────────────────────────────
simulate:
	@[ -f $(ENV_FILE) ] || (echo "ERROR: Falta $(ENV_FILE)" && exit 1)
	@[ -f data/admissions.csv ] || ( \
		echo "ERROR: Falta data/admissions.csv"; \
		echo "       Descarga MIMIC-IV de https://physionet.org y coloca los CSV en data/"; \
		exit 1)
	@echo "Generando lotes anuales y subiéndolos al landing-zone..."
	@export $$(grep -v '^#' $(ENV_FILE) | grep '=' | xargs) && \
		python3 $(DATOS_DIR)/simulador_lotes.py

# ─────────────────────────────────────────────
# Setup dividido por idempotencia
# ─────────────────────────────────────────────
setup-infra: generate-config up wait init-tables
	@echo "Infraestructura lista. Ejecuta 'make load-data' para cargar los datos."

load-data: upload-vocab simulate
	@echo "Datos cargados. Dispara el DAG en http://localhost:8083"

# Setup completo (una sola vez tras clonar el repo)
# ─────────────────────────────────────────────
setup: setup-infra load-data
	@echo ""
	@echo "Setup completo."
	@echo ""
	@echo "  Airflow:  http://localhost:8083  (credenciales en docker/.env)"
	@echo "  MinIO:    http://localhost:9001"
	@echo "  Trino:    http://localhost:8082"
	@echo "  Spark:    http://localhost:8888"
	@echo ""
	@echo "Dispara el DAG 'ingesta_hospitalaria_anual' en Airflow para procesar el primer lote."
	@echo ""
