# FAST API template

This project is a service template built with FastAPI, Celery, PostgreSQL, and Redis.
All current features well tested on UNIX systems.

Used stack:

- Python 3.12
- [uv](https://docs.astral.sh/uv/) as package manager
- PostgreSQL database
- Celery worker for background tasks
- SQLAlchemy
- Alembic for migrations
- Linters, like [ruff](https://docs.astral.sh/ruff/), isort and black
- A lot of usefull commands with makefile, that makes life easy

## Project Structure

The project consists of several services:

- `db`: PostgreSQL database
- `backend`: FastAPI application
- `celery`: Celery worker for background tasks
- `whodb`: Custom database service

## Prerequisites

- Docker
- Docker Compose
- Make (optional, for using Makefile commands)

## Setup

1. Clone the repository
2. Copy the `.env.example` file to `.env` and adjust the values if needed
3. Build and start the services:

```bash
make build
make up
```

## API Documentation

Once the services are up, you can access the API documentation at:

http://localhost:9003/docs

## Available Make Commands

- make help: Show all available commands
- make build: Build Docker images
- make up: Start all services
- make down: Stop all services
- make full-restart: Restart all services
- make clean: Remove containers and images
- make full-clean: Remove containers, images, and volumes
- make rebuild: Rebuild all services
- make update: Update backend service
  For more commands, run make help.

## Database Management

- Connect to PostgreSQL: make postgres
- Create a database dump: make download-dump name=dump_name
- Restore a database dump: make upload-dump name=dump_name
- Connect to Whodb database explorer: http://localhost:8080
- Enter your db params and connect

## Development

- Install a new package: make install-package name=package_name
- Install a new dev package: make install-dev-package name=package_name

## Run linters:

- make linters

## Alembic Migrations

- Create a new migration: make makemigrations name="migration_name"
- Apply migrations: make migrate
- Downgrade migrations: make downgrade name=revision
