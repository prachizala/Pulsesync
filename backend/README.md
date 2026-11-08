# PulseSync - Backend Service

FastAPI-powered async backend for the PulseSync emergency & field operations dispatch platform.

## Features

- **Async Architecture**: FastAPI with Python 3.11+ and async SQLAlchemy 2.0.
- **Relational Storage**: PostgreSQL (production/docker) and SQLite async support (local/tests).
- **Authentication & RBAC**: JWT Bearer tokens with distinct operational roles:
  - `dispatcher`: Can assign incidents, update priority, view all responders.
  - `responder`: Can create incidents, update incident progress, broadcast live locations.
  - `admin`: Full system management and user provisioning.
- **Health Checks**: `/api/v1/health` verifying async database and Redis connectivity.
- **Containerization**: Multi-stage `Dockerfile` and root `docker-compose.yml`.

## Local Development Setup

### 1. Virtual Environment & Dependencies

```bash
cd backend
python -m venv .venv
# Windows:
.venv\Scripts\activate
# Linux/macOS:
source .venv/bin/activate

pip install -r requirements.txt
```

### 2. Environment Variables

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

### 3. Running with Docker Compose

To start PostgreSQL, Redis, and the FastAPI backend together:

```bash
cd ..
docker compose up --build
```

### 4. Running Locally

```bash
uvicorn app.main:app --reload --port 8000
```

Interactive Swagger API documentation will be available at:
`http://localhost:8000/api/v1/docs`
