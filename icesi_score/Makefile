.PHONY: db-up db-migrate db-seed db-connect db-down venv superadmin-seed lambda-build profile-build update-profile-build delete-user-build create-admin-user-build get-teams-build get-leagues-build create-match-build get-matches-build update-match-build delete-match-build get-soccer-events-build get-match-periods-build get-volleyball-data-build

VENV   := .venv
PYTHON := $(VENV)/bin/python
PIP    := $(VENV)/bin/pip

DB_NAME ?= icesi_score
DB_USER ?= icesi_admin

# Superadmin — valores por defecto (sobrescribir en la línea de make)
SUPERADMIN_EMAIL      ?= superadmin@uicesi.edu.co
SUPERADMIN_FULL_NAME  ?= Super Administrador
SUPERADMIN_PHONE      ?= +57000000000
SUPERADMIN_UNIVERSITY ?= Icesi
# SUPERADMIN_PASSWORD no tiene default: se requiere explícitamente

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
	@$(PIP) install -q psycopg2-binary boto3
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
# profile-build — empaqueta get_user_profile con psycopg2 para Linux x86_64
# ---------------------------------------------------------------------------
profile-build: venv
	@PKG="backend/get_user_profile/package" && \
	 rm -rf "$$PKG" && \
	 $(PIP) install psycopg2-binary \
	   --target "$$PKG" \
	   --platform manylinux2014_x86_64 \
	   --python-version 3.11 \
	   --only-binary=:all: \
	   --quiet && \
	 cp backend/get_user_profile/lambda_function.py "$$PKG/" && \
	 echo "✓ Paquete Lambda listo en $$PKG"

# ---------------------------------------------------------------------------
# update-profile-build — empaqueta update_user_profile con psycopg2 para Linux x86_64
# ---------------------------------------------------------------------------
update-profile-build: venv
	@PKG="backend/update_user_profile/package" && \
	 rm -rf "$$PKG" && \
	 $(PIP) install psycopg2-binary \
	   --target "$$PKG" \
	   --platform manylinux2014_x86_64 \
	   --python-version 3.11 \
	   --only-binary=:all: \
	   --quiet && \
	 cp backend/update_user_profile/lambda_function.py "$$PKG/" && \
	 echo "✓ Paquete Lambda listo en $$PKG"

# ---------------------------------------------------------------------------
# delete-user-build — empaqueta delete_user con psycopg2 para Linux x86_64
# ---------------------------------------------------------------------------
delete-user-build: venv
	@PKG="backend/delete_user/package" && \
	 rm -rf "$$PKG" && \
	 $(PIP) install psycopg2-binary \
	   --target "$$PKG" \
	   --platform manylinux2014_x86_64 \
	   --python-version 3.11 \
	   --only-binary=:all: \
	   --quiet && \
	 cp backend/delete_user/lambda_function.py "$$PKG/" && \
	 echo "✓ Paquete Lambda listo en $$PKG"

# ---------------------------------------------------------------------------
# create-admin-user-build — empaqueta create_admin_user con psycopg2 para Linux x86_64
# ---------------------------------------------------------------------------
create-admin-user-build: venv
	@PKG="backend/create_admin_user/package" && \
	 rm -rf "$$PKG" && \
	 $(PIP) install psycopg2-binary \
	   --target "$$PKG" \
	   --platform manylinux2014_x86_64 \
	   --python-version 3.11 \
	   --only-binary=:all: \
	   --quiet && \
	 cp backend/create_admin_user/lambda_function.py "$$PKG/" && \
	 echo "✓ Paquete Lambda listo en $$PKG"

# ---------------------------------------------------------------------------
# get-teams-build — empaqueta get_teams con psycopg2 para Linux x86_64
# ---------------------------------------------------------------------------
get-teams-build: venv
	@PKG="backend/get_teams/package" && \
	 rm -rf "$$PKG" && \
	 $(PIP) install psycopg2-binary \
	   --target "$$PKG" \
	   --platform manylinux2014_x86_64 \
	   --python-version 3.11 \
	   --only-binary=:all: \
	   --quiet && \
	 cp backend/get_teams/lambda_function.py "$$PKG/" && \
	 echo "✓ Paquete Lambda listo en $$PKG"

# ---------------------------------------------------------------------------
# get-leagues-build — empaqueta get_leagues con psycopg2 para Linux x86_64
# ---------------------------------------------------------------------------
get-leagues-build: venv
	@PKG="backend/get_leagues/package" && \
	 rm -rf "$$PKG" && \
	 $(PIP) install psycopg2-binary \
	   --target "$$PKG" \
	   --platform manylinux2014_x86_64 \
	   --python-version 3.11 \
	   --only-binary=:all: \
	   --quiet && \
	 cp backend/get_leagues/lambda_function.py "$$PKG/" && \
	 echo "✓ Paquete Lambda listo en $$PKG"

# ---------------------------------------------------------------------------
# create-match-build — empaqueta create_match con psycopg2 para Linux x86_64
# ---------------------------------------------------------------------------
create-match-build: venv
	@PKG="backend/create_match/package" && \
	 rm -rf "$$PKG" && \
	 $(PIP) install psycopg2-binary \
	   --target "$$PKG" \
	   --platform manylinux2014_x86_64 \
	   --python-version 3.11 \
	   --only-binary=:all: \
	   --quiet && \
	 cp backend/create_match/lambda_function.py "$$PKG/" && \
	 echo "✓ Paquete Lambda listo en $$PKG"

# ---------------------------------------------------------------------------
# get-matches-build — empaqueta get_matches con psycopg2 para Linux x86_64
# ---------------------------------------------------------------------------
get-matches-build: venv
	@PKG="backend/get_matches/package" && \
	 rm -rf "$$PKG" && \
	 $(PIP) install psycopg2-binary \
	   --target "$$PKG" \
	   --platform manylinux2014_x86_64 \
	   --python-version 3.11 \
	   --only-binary=:all: \
	   --quiet && \
	 cp backend/get_matches/lambda_function.py "$$PKG/" && \
	 echo "✓ Paquete Lambda listo en $$PKG"

# ---------------------------------------------------------------------------
# update-match-build — empaqueta update_match con psycopg2 para Linux x86_64
# ---------------------------------------------------------------------------
update-match-build: venv
	@PKG="backend/update_match/package" && \
	 rm -rf "$$PKG" && \
	 $(PIP) install psycopg2-binary \
	   --target "$$PKG" \
	   --platform manylinux2014_x86_64 \
	   --python-version 3.11 \
	   --only-binary=:all: \
	   --quiet && \
	 cp backend/update_match/lambda_function.py "$$PKG/" && \
	 echo "✓ Paquete Lambda listo en $$PKG"

# ---------------------------------------------------------------------------
# delete-match-build — empaqueta delete_match con psycopg2 para Linux x86_64
# ---------------------------------------------------------------------------
delete-match-build: venv
	@PKG="backend/delete_match/package" && \
	 rm -rf "$$PKG" && \
	 $(PIP) install psycopg2-binary \
	   --target "$$PKG" \
	   --platform manylinux2014_x86_64 \
	   --python-version 3.11 \
	   --only-binary=:all: \
	   --quiet && \
	 cp backend/delete_match/lambda_function.py "$$PKG/" && \
	 echo "✓ Paquete Lambda listo en $$PKG"

# ---------------------------------------------------------------------------
# get-soccer-events-build — empaqueta get_soccer_events con psycopg2 para Linux x86_64
# ---------------------------------------------------------------------------
get-soccer-events-build: venv
	@PKG="backend/get_soccer_events/package" && \
	 rm -rf "$$PKG" && \
	 $(PIP) install psycopg2-binary \
	   --target "$$PKG" \
	   --platform manylinux2014_x86_64 \
	   --python-version 3.11 \
	   --only-binary=:all: \
	   --quiet && \
	 cp backend/get_soccer_events/lambda_function.py "$$PKG/" && \
	 echo "✓ Paquete Lambda listo en $$PKG"

# ---------------------------------------------------------------------------
# get-match-periods-build — empaqueta get_match_periods con psycopg2 para Linux x86_64
# ---------------------------------------------------------------------------
get-match-periods-build: venv
	@PKG="backend/get_match_periods/package" && \
	 rm -rf "$$PKG" && \
	 $(PIP) install psycopg2-binary \
	   --target "$$PKG" \
	   --platform manylinux2014_x86_64 \
	   --python-version 3.11 \
	   --only-binary=:all: \
	   --quiet && \
	 cp backend/get_match_periods/lambda_function.py "$$PKG/" && \
	 echo "✓ Paquete Lambda listo en $$PKG"

# ---------------------------------------------------------------------------
# get-volleyball-data-build — empaqueta get_volleyball_data con psycopg2 para Linux x86_64
# ---------------------------------------------------------------------------
get-volleyball-data-build: venv
	@PKG="backend/get_volleyball_data/package" && \
	 rm -rf "$$PKG" && \
	 $(PIP) install psycopg2-binary \
	   --target "$$PKG" \
	   --platform manylinux2014_x86_64 \
	   --python-version 3.11 \
	   --only-binary=:all: \
	   --quiet && \
	 cp backend/get_volleyball_data/lambda_function.py "$$PKG/" && \
	 echo "✓ Paquete Lambda listo en $$PKG"

# ---------------------------------------------------------------------------
# db-up — abre acceso público temporal desde la IP del desarrollador
# ---------------------------------------------------------------------------
db-up: lambda-build profile-build update-profile-build delete-user-build create-admin-user-build get-teams-build get-leagues-build create-match-build get-matches-build update-match-build delete-match-build get-soccer-events-build get-match-periods-build get-volleyball-data-build
	@echo "Obteniendo IP pública…"
	@MY_IP=$$(curl -s https://ifconfig.me) && \
	 echo "IP detectada: $$MY_IP" && \
	 cd infrastructure && \
	 terraform apply \
	   -var="dev_my_ip=$$MY_IP" \
	   -var="db_password=$(DB_PASSWORD)"

# ---------------------------------------------------------------------------
# db-migrate — aplica schema.sql y crea el SUPERADMIN
# Uso: make db-migrate DB_PASSWORD=X SUPERADMIN_PASSWORD=Y
# ---------------------------------------------------------------------------
db-migrate: venv
	@$(rds_vars); \
	 DB_HOST="$$RDS_HOST" \
	 DB_PORT="$$RDS_PORT" \
	 DB_NAME="$(DB_NAME)" \
	 DB_USER="$(DB_USER)" \
	 DB_PASSWORD="$(DB_PASSWORD)" \
	 $(PYTHON) backend/db/run_migrations.py
	@$(MAKE) superadmin-seed DB_PASSWORD="$(DB_PASSWORD)" SUPERADMIN_PASSWORD="$(SUPERADMIN_PASSWORD)"

# ---------------------------------------------------------------------------
# superadmin-seed — crea/actualiza el SUPERADMIN en Cognito y en la BD
# Uso: make superadmin-seed DB_PASSWORD=X SUPERADMIN_PASSWORD=Y
# Opcional: SUPERADMIN_EMAIL  SUPERADMIN_FULL_NAME  SUPERADMIN_PHONE  SUPERADMIN_UNIVERSITY
# ---------------------------------------------------------------------------
superadmin-seed: venv
	@if [ -z "$(SUPERADMIN_PASSWORD)" ]; then \
	  echo "❌ Falta SUPERADMIN_PASSWORD. Uso: make superadmin-seed DB_PASSWORD=X SUPERADMIN_PASSWORD=Y"; \
	  exit 1; \
	fi
	@$(rds_vars); \
	 POOL_ID=$$(cd infrastructure && terraform output -raw cognito_user_pool_id); \
	 DB_HOST="$$RDS_HOST" \
	 DB_PORT="$$RDS_PORT" \
	 DB_NAME="$(DB_NAME)" \
	 DB_USER="$(DB_USER)" \
	 DB_PASSWORD="$(DB_PASSWORD)" \
	 COGNITO_USER_POOL_ID="$$POOL_ID" \
	 SUPERADMIN_EMAIL="$(SUPERADMIN_EMAIL)" \
	 SUPERADMIN_PASSWORD="$(SUPERADMIN_PASSWORD)" \
	 SUPERADMIN_FULL_NAME="$(SUPERADMIN_FULL_NAME)" \
	 SUPERADMIN_PHONE="$(SUPERADMIN_PHONE)" \
	 SUPERADMIN_UNIVERSITY="$(SUPERADMIN_UNIVERSITY)" \
	 $(PYTHON) backend/db/seed_superadmin.py

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
