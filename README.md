# PulseSync

<div align="center">

![PulseSync Logo Banner](https://img.shields.io/badge/PulseSync-Offline--First%20Emergency%20Dispatch-D32F2F?style=for-the-badge&logo=shield&logoColor=white)

[![Flutter Version](https://img.shields.io/badge/Flutter-3.47.2-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI Version](https://img.shields.io/badge/FastAPI-0.110%2B-009688?style=flat-square&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python Version](https://img.shields.io/badge/Python-3.11%2B-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?style=flat-square&logo=postgresql&logoColor=white)](https://postgresql.org)
[![Redis](https://img.shields.io/badge/Redis-7%20Pub%2FSub-DC382D?style=flat-square&logo=redis&logoColor=white)](https://redis.io)
[![Drift SQLite](https://img.shields.io/badge/Drift%20SQLite-2.20.0-003B57?style=flat-square&logo=sqlite&logoColor=white)](https://drift.simonbinder.eu)
[![Tests Passing](https://img.shields.io/badge/Tests-100%25%20Passing-success?style=flat-square&logo=checkmarx&logoColor=white)](#-automated-testing-100-pass)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions%20Passing-brightgreen?style=flat-square&logo=githubactions&logoColor=white)](https://github.com/prachizala/Pulsesync/actions)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](#)

<p align="center">
  <b>Resilient, offline-first emergency coordination & disaster dispatch system engineered for zero-connectivity environments.</b>
</p>

</div>

---

## 📌 Overview

During natural disasters (flash floods, earthquakes, structural collapses, wilderness search-and-rescue), telecommunications infrastructure frequently collapses. Standard emergency response apps fail completely without cell tower connections.

**PulseSync** is an industrial-grade, offline-first disaster response and field dispatch platform. Responders can draft incidents, record voice situation memos, capture GPS coordinates, calculate real-time walking/driving ETAs, and navigate dynamic radar perimeters—even in complete dead zones. The moment connectivity is restored, PulseSync executes an **idempotent versioned synchronization protocol** with the central FastAPI & Redis command center.

---

## 🏗️ System Architecture

```
                          ┌───────────────────────────────────────┐
                          │          Flutter Mobile App           │
                          │   (Dart 3.13+, Riverpod 2.5, Drift)   │
                          └───────────────────┬───────────────────┘
                                              │
                    ┌─────────────────────────┴─────────────────────────┐
                    │ Zero-Connectivity (Offline)      Active Wi-Fi / LTE
                    ▼                                                   ▼
        ┌───────────────────────┐                           ┌────────────────────────┐
        │  Drift Local SQLite   │                           │    FastAPI Backend     │
        │  - LocalIncidents     │                           │  (Python 3.11+, ASGI)  │
        │  - SyncQueue (Tx)     │                           └───────────┬────────────┘
        │  - CachedLocations    │                                       │
        └───────────────────────┘                             ┌─────────┴─────────┐
                                                              ▼                   ▼
                                                     ┌─────────────────┐ ┌────────────────┐
                                                     │ PostgreSQL 16   │ │ Redis 7 PubSub │
                                                     │ (Asyncpg + 2.0) │ │ & WebSockets   │
                                                     └─────────────────┘ └────────────────┘
```

---

## 🌟 Key Features & Innovations

### 1. 🔄 True Offline-First Sync Architecture
- **Drift SQLite Local Storage:** Every incident report, location breadcrumb, and triage tag commits locally before any network call.
- **Idempotent Push (`POST /api/v1/sync/push`):** Deduplicates records using unique UUID `client_id`s and optimistic version numbers.
- **Incremental Delta Pull (`GET /api/v1/sync/pull?since={timestamp}`):** Fetches only records updated since last watermark to minimize bandwidth consumption.
- **Auto-Sync Listener:** Uses `connectivity_plus` to automatically push queued records the instant Wi-Fi or cellular network returns.
- **LAN Discovery & Cleartext Support:** Configured for seamless physical device testing (`android:usesCleartextTraffic="true"`) with an in-app **Backend Server IP** configuration dialog.

### 2. 📍 Tactical Geospatial & Proximity Engine
- **India Default Centering & Live GPS Tracking:** Defaults to India coordinates (`20.5937° N, 78.9629° E`) with live pulsing user locator.
- **Dynamic Radar Hazard Rings:**
  - 🔴 **500m Red Hazard Ring:** Dangerous impact zone requiring evacuation or protective gear.
  - 🟠 **1,000m Orange Warning Ring:** Controlled response staging zone.
  - 🔵 **2,500m Advisory Ring:** Safe perimeter for logistics.
- **Live Distance & ETA Calculation:** Haversine great-circle distance math computes live walking and driving ETA on every incident card.
- **Interactive Detail Bottom Sheet:** Alerts responders if they are in the **500m Hazard Zone**, provides a **"Show on Map"** camera swoop button, and allows 1-tap status updates (`Reported` $\to$ `In Progress` $\to$ `Resolved`).

### 3. 🚨 Life-Saving Emergency Suite
- **1-Tap SOS Distress Beacon:** Immediate critical alert dispatch with GPS coordinates and visual pulsation.
- **🎙️ Field Audio Voice Memo Recorder:** 30-second situational audio recording with live timer and playback safeguards for situations where typing is hazardous.
- **Offline First-Aid Survival Guide:** 100% offline, zero-network medical instructions for CPR, Severe Bleeding & Hemorrhage, Burn Care, Choking (Heimlich), and Snakebites.
- **Night Rescue Strobe Beacon:** High-visibility optical signaling tool with Fast Strobe frequency, SOS Morse Code (`... --- ...`), and Solid High-Beam illumination.
- **Quick Triage Chips:** 1-tap rapid incident tagging (`⚠️ Trapped People`, `🔥 Active Flames`, `🩸 Critical Injury`, `⚡ Live Wire`, `🌊 High Water`).

### 4. 🌗 Dual Tactical Theming
- **Dark Tactical Mode (Default):** Deep midnight palette (`#0F141A`) with glowing crimson accents (`#FF5252`) and charcoal cards (`#19202A`) for night missions and battery longevity.
- **Light Clean Mode:** High-contrast daylight emergency dispatch palette (`#F4F6F9`) with crisp white cards (`#FFFFFF`).
- Smooth 360° rotating animated toggle in AppBar and dedicated switch in the navigation drawer.

---

## 📁 Repository Structure

```text
pulsesync/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   ├── deps.py               # Auth, DB, and Field Responder fallback dependencies
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
│   │   └── Dockerfile                # Production multi-stage image
│   ├── tests/                        # 8 passing test suites (Auth, Geo, Sync, Incidents, WS)
│   ├── requirements.txt
│   └── README.md
├── mobile/
│   ├── lib/
│   │   ├── core/                     # Constants and ApiClient
│   │   ├── data/local/               # Drift database tables, DAOs & generated code
│   │   ├── logic/                    # Riverpod providers, ThemeNotifier, & SyncService
│   │   ├── views/
│   │   │   ├── incident_list_screen.dart   # Main feed with Search, Filters, KPIs
│   │   │   ├── incident_report_screen.dart # Form with Audio Memo & Triage Chips
│   │   │   ├── incident_detail_modal.dart  # Tactical proximity, ETA & Map Jump
│   │   │   ├── map_screen.dart             # OpenStreetMap with radar rings
│   │   │   ├── emergency_guide_screen.dart # 100% offline First-Aid guide
│   │   │   ├── night_beacon_screen.dart    # Optical Morse SOS & Strobe
│   │   │   └── sos_beacon_dialog.dart      # 1-tap instant distress beacon
│   │   └── main.dart                 # Application entrypoint with Dual Themes
│   ├── test/                         # 5 passing widget & Drift unit tests
│   ├── pubspec.yaml
│   └── README.md
├── docker-compose.yml                # Multi-container orchestration (FastAPI + PG16 + Redis7)
├── PROJECT_REPORT.md                 # Complete engineering & architectural evaluation report
├── pulsesync.apk                     # Single installable Android application package
└── README.md
```

---

## ⚡ Quick Start Guide

### 1. Backend Service

#### Option A: Docker Compose (Recommended)
```bash
docker compose up --build
```
Spins up:
- **FastAPI**: `http://localhost:8000` (Interactive docs at `http://localhost:8000/api/v1/docs`)
- **PostgreSQL 16**: `localhost:5432`
- **Redis 7**: `localhost:6379`

#### Option B: Running Locally with Python
```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt

# Run with host 0.0.0.0 so physical mobile devices on Wi-Fi can sync:
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

---

### 2. Mobile Application

```powershell
cd mobile
flutter pub get

# Run on target platform:
flutter run -d windows    # Windows Desktop
flutter run -d chrome     # Web browser
flutter run -d android    # Connected Android device/emulator
```

#### Installing on Physical Android Device:
Copy the pre-built single APK [`pulsesync.apk`](file:///C:/Users/prachi/OneDrive/Desktop/pulsesync/pulsesync.apk) to your phone and install directly.

---

## 🧪 Automated Testing (100% Pass)

### Backend Pytest Suite
```powershell
cd backend
.\.venv\Scripts\pytest -v
```
- ✅ `test_health_check` (DB & Redis connection verification)
- ✅ `test_register_and_login_flow` (JWT hashing & lifecycle)
- ✅ `test_role_based_access_control` (RBAC dispatcher/responder permissions)
- ✅ `test_haversine_distance_known_points` (Geospatial math accuracy)
- ✅ `test_rank_responders_by_proximity` (Proximity ranking engine)
- ✅ `test_incident_lifecycle` (Creation, status transitions, versioning)
- ✅ `test_sync_push_and_pull_idempotency` (Offline conflict-free sync)
- ✅ `test_websocket_auth_and_ping` (Live real-time dispatch stream)

### Mobile Flutter Suite & Static Analysis
```powershell
cd mobile
flutter analyze   # 0 issues found
flutter test      # 5 passing tests
```
- ✅ `drift_test.dart` (Offline SQLite save & state transition)
- ✅ `drift_test.dart` (Sync queue enqueue & dequeue)
- ✅ `widget_test.dart` (Incident list & navigation rendering)
- ✅ `widget_test.dart` (Animated Dark/Light mode theme toggle)
- ✅ `widget_test.dart` (Search bar & category filter chips)

---

## 📄 Documentation & Reports
For an in-depth architectural and engineering analysis, see:
- 📖 [**PROJECT_REPORT.md**](PROJECT_REPORT.md) — Comprehensive technical report, system breakdown, and future roadmap.
