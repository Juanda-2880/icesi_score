.PHONY: db-up db-migrate db-seed db-connect db-down venv lambda-build

VENV   := .venv
PYTHON := $(VENV)/bin/python
PIP    := $(VENV)/bin/pip

DB_NAME ?= icesi_score
DB_USER ?= icesi_admin

# Macro de shell: extrae host y puerto de Terraform (se expande dentro de cada recipe)
define rds_vars
RDS_ENDPOINT=$$(cd infrastructure && terraform output -raw rds_endpoint); \
RDS_HOST=$$(echo "$$RDS_ENDPOINT" | cut -d: -f1); \
RDS_PORT=$$(echo "$$RDS_ENDPOINT" | cut -d: -f2); \
RDS_PORT=$${RDS_PORT:-5432}
endef

# ---------------------------------------------------------------------------
# venv — crea el entorno virtual e instala dependencias
# ---------------------------------------------------------------------------
venv: $(VENV)/bin/activate

$(VENV)/bin/activate:
	@python3 -m venv $(VENV)
	@$(PIP) install -q psycopg2-binary
	@echo "✓ Entorno virtual listo en $(VENV)/"

# ---------------------------------------------------------------------------
# lambda-build — empaqueta post_confirmation con psycopg2 para Linux x86_64
# ---------------------------------------------------------------------------
lambda-build: venv
	@PKG="backend/post_confirmation/package" && \
	 rm -rf "$$PKG" && \
	 $(PIP) install psycopg2-binary \
	   --target "$$PKG" \
	   --platform manylinux2014_x86_64 \
	   --python-version 3.11 \
	   --only-binary=:all: \
	   --quiet && \
	 cp backend/post_confirmation/lambda_function.py "$$PKG/" && \
	 echo "✓ Paquete Lambda listo en $$PKG"

# ---------------------------------------------------------------------------
# db-up — abre acceso público temporal desde la IP del desarrollador
# ---------------------------------------------------------------------------
db-up: lambda-build
	@echo "Obteniendo IP pública…"
	@MY_IP=$$(curl -s https://ifconfig.me) && \
	 echo "IP detectada: $$MY_IP" && \
	 cd infrastructure && \
	 terraform apply \
	   -var="dev_my_ip=$$MY_IP" \
	   -var="db_password=$(DB_PASSWORD)"

# ---------------------------------------------------------------------------
# db-migrate — aplica schema.sql vía Python (usa venv local)
# ---------------------------------------------------------------------------
db-migrate: venv
	@$(rds_vars); \
	 DB_HOST="$$RDS_HOST" \
	 DB_PORT="$$RDS_PORT" \
	 DB_NAME="$(DB_NAME)" \
	 DB_USER="$(DB_USER)" \
	 DB_PASSWORD="$(DB_PASSWORD)" \
	 $(PYTHON) backend/db/run_migrations.py

# ---------------------------------------------------------------------------
# db-seed — carga datos iniciales con psql
# ---------------------------------------------------------------------------
db-seed:
	@$(rds_vars); \
	 PGPASSWORD="$(DB_PASSWORD)" psql \
	   "host=$$RDS_HOST port=$$RDS_PORT dbname=$(DB_NAME) user=$(DB_USER) sslmode=require" \
	   -f backend/db/seed.sql

# ---------------------------------------------------------------------------
# db-connect — terminal interactiva psql con SSL
# ---------------------------------------------------------------------------
db-connect:
	@$(rds_vars); \
	 PGPASSWORD="$(DB_PASSWORD)" psql \
	   "host=$$RDS_HOST port=$$RDS_PORT dbname=$(DB_NAME) user=$(DB_USER) sslmode=require"

# ---------------------------------------------------------------------------
# db-down — destruye la infraestructura RDS
# ---------------------------------------------------------------------------
db-down:
	@cd infrastructure && terraform destroy \
	  -var="db_password=$(DB_PASSWORD)"
