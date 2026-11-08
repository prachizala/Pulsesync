# PulseSync

> **Offline-first emergency & field operations dispatch system.**

PulseSync is built for rapid and resilient coordination during critical field emergencies with zero or intermittent network connectivity. Responders can draft incidents, capture real-time GPS coordinates, visualize situations on interactive maps, and automatically synchronize bi-directionally with HQ when connectivity is restored.

---

## 🏗️ Architecture & Technology Stack

```
                          ┌────────────────────────┐
                          │   Flutter Mobile App   │
                          │  (Riverpod + Drift DB) │
                          └───────────┬────────────┘
                                      │
            ┌─────────────────────────┴─────────────────────────┐
            │ Offline Mode (Local SQLite)   Online Mode (REST/WS)
            ▼                                                   ▼
┌───────────────────────┐                       ┌────────────────────────┐
│ Drift Local Database  │                       │    FastAPI Backend     │
│ - Incidents           │                       │  (Async Python 3.11+)  │
│ - SyncQueue           │                       └───────────┬────────────┘
│ - BreadcrumbLocations │                                   │
└───────────────────────┘                         ┌─────────┴─────────┐
                                                  ▼                   ▼
                                         ┌─────────────────┐ ┌────────────────┐
                                         │ PostgreSQL 16   │ │ Redis 7 PubSub │
                                         │ (Asyncpg 2.0)   │ │ & WebSockets   │
                                         └─────────────────┘ └────────────────┘
```

### Components

- **Backend (`/backend`)**:
  - **Framework**: Python 3.11+, FastAPI (fully async ASGI)
  - **Database & ORM**: PostgreSQL 16 + Async SQLAlchemy 2.0 (`asyncpg` driver), async SQLite for zero-dependency unit tests
  - **Event Pub/Sub & WebSockets**: Redis 7 Pub/Sub with persistent connection manager for real-time dispatch events
  - **Security**: JWT Bearer token authentication with Role-Based Access Control (`dispatcher`, `responder`, `admin`)
  - **Geospatial Engine**: Haversine formula calculation for ranking responders by proximity to incident coordinates
  - **Containerization**: Multi-stage `Dockerfile` + root `docker-compose.yml`

- **Mobile (`/mobile`)**:
  - **Framework**: Flutter (Dart 3+)
  - **State Management**: Riverpod (`flutter_riverpod`)
  - **Offline-First Storage**: Drift (`drift` + `sqlite3`)
  - **Network Monitor**: `connectivity_plus` with background sync triggers
  - **Interactive Mapping**: `flutter_map` with OpenStreetMap raster tiles
  - **Location Services**: `geolocator` GPS integration

---

## 📁 Repository Structure

```text
pulsesync/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   ├── deps.py               # Dependency injection (Auth, DB, RBAC)
│   │   │   └── v1/
│   │   │       ├── api.py            # API V1 router aggregation
│   │   │       └── endpoints/
│   │   │           ├── auth.py       # User register, login & profile
│   │   │           ├── health.py     # Live DB & Redis check
│   │   │           ├── incidents.py  # Incident CRUD & status workflows
│   │   │           ├── sync.py       # Idempotent push/pull & proximity API
│   │   │           └── ws.py         # Real-time WebSocket dispatch stream
│   │   ├── core/
│   │   │   ├── config.py             # Pydantic v2 application settings
│   │   │   ├── database.py           # Async SQLAlchemy engine & session factory
│   │   │   ├── redis.py              # Async Redis client & pub/sub publisher
│   │   │   └── security.py           # Password hashing & JWT encode/decode
│   │   ├── models/                   # SQLAlchemy 2.0 models (User, Incident, ResponderLocation)
│   │   ├── schemas/                  # Pydantic v2 validation schemas
│   │   ├── services/                 # Geo Haversine & WebSocket connection manager
│   │   └── main.py                   # FastAPI application factory
│   ├── docker/
│   │   └── Dockerfile                # Production-ready multi-stage image
│   ├── tests/                        # Full test suite (Auth, Geo, Sync, Incidents, WS)
│   ├── requirements.txt
│   ├── .env.example
│   └── README.md
├── mobile/
│   ├── lib/
│   │   ├── core/                     # Constants and ApiClient
│   │   ├── data/local/               # Drift database tables, DAOs & generated code
│   │   ├── logic/                    # Riverpod providers & background SyncService
│   │   ├── views/                    # IncidentListScreen, IncidentReportScreen, MapScreen
│   │   └── main.dart                 # Application entrypoint
│   ├── test/                         # Drift DB tests & widget smoke tests
│   ├── pubspec.yaml
│   └── README.md
├── docker-compose.yml
├── .gitignore
└── README.md
```

---

## ⚡ Quick Start Guide

### 1. Backend Service

#### Using Docker Compose (Recommended)
```bash
docker compose up --build
```
This spins up:
- **FastAPI**: `http://localhost:8000` (Interactive docs at `/api/v1/docs`)
- **PostgreSQL**: `localhost:5432`
- **Redis**: `localhost:6379`

#### Running Locally with Python
```bash
cd backend
python -m venv .venv
# On Windows:
.venv\Scripts\activate
# On Linux/macOS:
source .venv/bin/activate

pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

### 2. Mobile Application

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Run on your target device:
flutter run -d windows    # Windows Desktop
flutter run -d chrome     # Web
flutter run -d android    # Android device/emulator
```

---

## 🔄 Offline-First Sync Protocol

PulseSync implements an **idempotent versioned synchronization protocol**:

1. **Client ID Guarantee**: Every entity created on a mobile device is stamped with a UUID `client_id` and initial `version: 1`.
2. **Local Commit**: Incident reports and responder location updates are stored directly in Drift SQLite and queued in `SyncQueue` before any HTTP network calls are made.
3. **Idempotent Push (`POST /api/v1/sync/push`)**:
   - The client pushes batches of incidents and location coordinates.
   - If an incident `client_id` already exists on the server, the server compares versions:
     - Newer version $\to$ updates record, increments version, and broadcasts update.
     - Identical/older version $\to$ returns server's current record safely without duplication or errors.
4. **Delta Pull (`GET /api/v1/sync/pull?since={timestamp}`)**:
   - The client fetches all records updated since its last sync watermark.
   - The server returns matching records and provides a new `server_timestamp`.
5. **Auto-Reconnect Flush**: `connectivity_plus` actively monitors network transitions. When the device returns from dead zones (`none` $\to$ `wifi`/`mobile`), the sync queue flushes automatically.

---

## 🧪 Automated Testing

### Backend Unit & Integration Tests (100% Pass)
```bash
cd backend
.venv\Scripts\pytest -v
```
Tests cover:
- Health check verification
- JWT user registration, password hashing, and authentication flow
- Role-Based Access Control (`dispatcher`, `responder`, `admin`)
- Haversine great-circle distance accuracy & nearest responder ranking
- Incident creation, lifecycle updates, and optimistic locking
- Push and pull idempotency & conflict handling
- WebSocket token authorization and live ping/pong

### Mobile Tests & Static Analysis (100% Pass)
```bash
cd mobile
dart analyze
flutter test
```
Tests cover:
- Drift SQLite offline database persistence & sync status state changes
- Sync queue enqueue and dequeue execution
- Widget smoke tests for incident feeds and navigation
