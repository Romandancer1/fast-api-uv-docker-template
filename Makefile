.DEFAULT_GOAL := help
include .env

DOCKER_COMP   = docker compose -f docker-compose.dev.yml
NAME 		  = backend
EXEC  = $(DOCKER_COMP) exec $(NAME)
UV            = $(EXEC) uv
DEFAULT_IMAGES = well-monitoring-python

ifeq ($(app_env), production)
	DOCKER_COMP  = docker compose -f docker-compose.prod.yml
endif


POSTGRES_CONT = $(DOCKER_COMP) exec db
BACKEND_CONT = $(DOCKER_COMP) exec backend

help:
	@echo "make help					- Prints this command and exit"
	@echo "			------ Working with docker compose -----"
	@echo "make build					- Forces build and pull containers from docker compose file"
	@echo "make up						- Ups containers from docker compose file"
	@echo "make up-debug					- Ups containers from docker compose file with logs output"
	@echo "make down 					- Downs containers from docker compose file"
	@echo "make full-restart 				- Downs and then ups containers from docker compose file"
	@echo "make clean 					- Downs containers and delete built images from docker compose file"
	@echo "make full-clean 				- Downs containers, remove volumes and delete built images from docker compose file"
	@echo "make rebuild				        - Downs containers, remove volumes, delete built images and build new from docker compose file"
	@echo "make update				        - Fully update backend service (rebuild images and restart containers without deleting volumes)"
	@echo "			------ Working with docker containers -----"
	@echo "make logs name=service_name			- Shows logs from all containers specified in docker compose file"
	@echo "make bash name=service_name			- Opens bash in specified container"
	@echo "make install_package name=your_packagename	- Installs new package to the integration service"
	@echo "make install-dev-package name=your_packagename	- Installs new dev package to the integration service"
	@echo "make restart name=service_name			- Restarts container with provided service_name (use name from docker compose file)"
	@echo "			------ Working with alembic migrations -----"
	@echo "make makemigrations name="migration"	- Create new migration"
	@echo "make migrate"						- Apply migrations to database"
	@echo "make downgrade name="revision"		- Downgrade migrations"
	@echo "			------ Working with linters -----"
	@echo "make linters					- Run all linters that were configured for project"


# ---------- Docker Compose ----------
build:
	@$(DOCKER_COMP) build --pull --no-cache

up:
	@$(DOCKER_COMP) up --detach --wait

up-debug:
	@$(DOCKER_COMP) up

down:
	@$(DOCKER_COMP) down --remove-orphans

full-restart: down up

clean:
	@$(DOCKER_COMP) down
	@docker rmi $(DEFAULT_IMAGES) || exit 0;

full-clean:
	@$(DOCKER_COMP) down --volumes
	@docker rmi $(DEFAULT_IMAGES) || exit 0;

rebuild: clean build

update: rebuild up

# ---------- Docker containers ----------
logs:
	@$(DOCKER_COMP) logs $(name) --tail=0 --follow

bash:
	@$(DOCKER_COMP) exec $(name) bash

postgres:
	@$(POSTGRES_CONT) psql -U postgres -w postgres -d $(database_name)

download-dump:
	@echo "Dumping to $(name)..."
	@$(POSTGRES_CONT) pg_dump -U postgres -Fc $(database_name) > $(name)

download-text-dump:
	@echo "Dumping to $(name)..."
	@$(POSTGRES_CONT) pg_dump -U postgres -d $(database_name) > $(name)


upload-dump:
	@echo "Recreating '$(database_name)' database..."
	@$(POSTGRES_CONT) psql -U postgres -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$(database_name)';"
	@$(POSTGRES_CONT) psql -U postgres -c "DROP DATABASE IF EXISTS $(database_name);"
	@$(POSTGRES_CONT) psql -U postgres -c "CREATE DATABASE $(database_name);"
	@echo "Applying $(name) dump..."
	@$(POSTGRES_CONT) psql -U postgres -d $(database_name) -c "SELECT timescaledb_pre_restore();"
	@$(POSTGRES_CONT) bash -c "pg_restore -e -v -U postgres -Fc --no-owner --no-privileges -d $(database_name) /dump/$(name)"
	@$(POSTGRES_CONT) psql -U postgres -d $(database_name) -c "SELECT timescaledb_post_restore();"

upload-text-dump:
	@echo "Recreating '$(database_name)' database..."
	@$(POSTGRES_CONT) psql -U postgres -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$(database_name)';"
	@$(POSTGRES_CONT) psql -U postgres -c "DROP DATABASE IF EXISTS $(database_name);"
	@$(POSTGRES_CONT) psql -U postgres -c "CREATE DATABASE $(database_name);"
	@echo "Applying $(name) dump..."
	@$(POSTGRES_CONT) psql -U postgres -d $(database_name) -c "SELECT timescaledb_pre_restore();"
	@$(POSTGRES_CONT) bash -c "psql -e -v -U postgres -d $(database_name) -f /dump/$(name)"
	@$(POSTGRES_CONT) psql -U postgres -d $(database_name) -c "SELECT timescaledb_post_restore();"


restart:
	@$(DOCKER_COMP) restart $(name)

install_package:
	@$(EXEC) echo $(name) >> requirements/input/requirements.in
	@$(UV) pip compile requirements/input/requirements.in -o requirements/lock/requirements.txt
	@$(UV) pip compile requirements/input/requirements-dev.in -o requirements/lock/requirements-dev.txt
	@$(UV) pip sync requirements/lock/requirements-dev.txt --system

install-dev-package:
	@$(EXEC) echo $(name) >> requirements/input/requirements-dev.in
	@$(UV) pip compile requirements/input/requirements-dev.in -o requirements/lock/requirements-dev.txt
	@$(UV) pip sync requirements/lock/requirements-dev.txt --system

show-python-list:
	@$(UV) python list


# ---------- Alembic MIGRATIONS ----------
init-alembic:
	@$(BACKEND_CONT) alembic init -t async migration

makemigrations:
	@$(BACKEND_CONT) alembic revision --autogenerate -m $(name)

migrate:
	@$(BACKEND_CONT) alembic upgrade head

downgrade:
	@$(BACKEND_CONT) alembic downgrade $(name)

# ---------- Linters ----------
linters:
	@echo "-------- running black --------"
	@$(UV) run black ./app
	@echo "-------- running isort --------"
	@$(UV) run isort ./app
	@echo "-------- running ruff --------"
	@$(UV) run ruff check --fix ./app
	@$(UV) run ruff check ./app


black:
	@$(UV) run black ./app
isort:
	@$(UV) run isort ./app
ruff:
	@$(UV) run ruff check --fix ./app
	@$(UV) run ruff check ./app