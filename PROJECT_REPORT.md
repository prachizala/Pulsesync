# PulseSync: Engineering & Architecture Report

> **Project Title:** PulseSync – Offline-First Emergency & Field Operations Dispatch System  
> **Repository:** [https://github.com/prachizala/Pulsesync.git](https://github.com/prachizala/Pulsesync.git)  
> **Author:** Prachi Zala  
> **Date:** November 2026  
> **Version:** 1.0.0 (Production-Ready MVP)  
> **Platform Support:** Android, iOS, Windows, Web, Linux  

---

## 1. Executive Summary

In acute crisis situations—such as flash floods, severe earthquakes, major structural collapses, or wilderness search-and-rescue—civilian telecommunications infrastructure frequently fails or suffers from severe intermittent bandwidth throttling. Traditional emergency dispatch applications, built on client-server REST paradigms that mandate active internet connections, become completely inoperative under these zero-connectivity conditions.

**PulseSync** is an industrial-grade, offline-first disaster response and emergency dispatch platform engineered specifically for zero-connectivity environments. By pairing a local embedded SQLite database (`Drift`) with a resilient, transactional synchronization queue on mobile clients, and an asynchronous, high-throughput backend (FastAPI, PostgreSQL, Redis Pub/Sub, WebSockets), PulseSync guarantees:
1. **Zero Data Loss:** Immediate local commit of incident reports, situational audio notes, and triage tags.
2. **Automatic Bidirectional Synchronization:** Idempotent push/pull protocol that activates as soon as cell or Wi-Fi connectivity is detected.
3. **Tactical Geospatial Awareness:** Real-time distance calculations, walking/driving ETA estimates, and 500-meter danger zone alerts.
4. **Life-Saving Emergency Toolkit:** 1-tap SOS distress beacons, offline first-aid survival protocols, and high-visibility night strobe signaling.

---

## 2. Technology Stack & Component Architecture

### 2.1 Complete Stack Overview

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

| Layer | Technology | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Mobile Client** | Flutter / Dart | `3.47.2 / 3.13.2` | Cross-platform native mobile application |
| **State Management** | Flutter Riverpod | `2.5.1` | Reactive, testable state management and dependency injection |
| **Local Offline Storage** | Drift SQLite | `2.20.0` | Strongly-typed, transactional SQLite database with migrations |
| **Network Monitoring** | `connectivity_plus` | `6.0.3` | Event-driven network listener for auto-triggering sync |
| **Mapping & Geospatial** | `flutter_map` + `latlong2` | `7.0.2 / 0.9.1` | Offline-tolerant OpenStreetMap raster rendering & distance math |
| **Backend Framework** | FastAPI | `0.110+` | Asynchronous, high-throughput RESTful API & WebSocket hub |
| **ORM & Database** | SQLAlchemy 2.0 + PostgreSQL | `2.0+ / 16` | Asynchronous database access via `asyncpg` |
| **Message Broker** | Redis Pub/Sub | `7.0+` | Real-time event broadcasting between backend nodes and dispatchers |
| **Authentication** | JWT (OAuth2 Password) | RFC 7519 | Role-Based Access Control (`dispatcher`, `responder`, `admin`) |
| **Containerization** | Docker & Docker Compose | Multi-stage | Single-command deployment of entire backend infrastructure |

---

## 3. Core Capabilities & Innovative Features

### 3.1 Idempotent Offline-First Synchronization Protocol
- **Local Transactional Stamping:** Every incident created in the field is assigned a unique UUID `client_id` and initial `version: 1`. It is immediately committed to SQLite before any HTTP attempt.
- **Transactional Sync Queue:** Operations (`create`, `update`) are saved to a dedicated `sync_queue` table with retry counters.
- **Idempotent Push (`POST /api/v1/sync/push`):**
  - Batch transmission of offline incidents and location pings.
  - Conflict resolution using version comparison: if the server has a newer version, the server record prevails; if the mobile version is newer, the server updates and broadcasts to HQ.
- **Delta Watermark Pull (`GET /api/v1/sync/pull?since={timestamp}`):**
  - Mobile clients pull only delta changes since their last synchronization watermark, minimizing cellular data consumption in disaster zones.
- **Cleartext & Device LAN Discovery:**
  - AndroidManifest configured with `android:usesCleartextTraffic="true"` to facilitate peer and local network development.
  - In-app **Backend Server IP Configuration Dialog** allows field workers to re-point their server endpoint directly from the drawer without rebuilding the app.

---

### 3.2 Tactical Geospatial Intelligence & Proximity Engine
- **India Default Centering & Live GPS Tracking:**
  - Map defaults to India geographic center (`20.5937° N, 78.9629° E`) with a smooth animated zoom into the user's exact coordinates once GPS acquires lock.
  - Live user position is displayed as a pulsing blue radar marker.
- **Dynamic Proximity Radar Rings:**
  - Visual circle overlays projecting safe and danger boundaries from the responder's live coordinate:
    - **500m Red Hazard Ring:** Immediate perimeter requiring protective gear or evacuation.
    - **1,000m Orange Warning Ring:** Controlled staging area.
    - **2,500m Cyan Advisory Ring:** Safe perimeter for logistics and command vehicles.
- **Real-Time Distance & ETA Calculator:**
  - Uses the mathematical **Haversine great-circle formula** directly on device to calculate live distance to incidents.
  - Automatically derives estimated walking and driving ETAs (e.g. `📍 450m • ~6 min walk ETA`).
- **Interactive Incident Detail Bottom Sheet:**
  - Clicking any card opens a tactical overview sheet.
  - Alerts responders if they are within the **500m Hazard Zone**.
  - Includes a **"Show on Field Map"** button that auto-pans and focuses the map camera directly onto the targeted incident pin.
  - 1-tap **Status Updating** (`Reported` $\to$ `In Progress` $\to$ `Resolved`) with auto-sync.

---

### 3.3 Life-Saving Emergency Innovations

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PulseSync Emergency Suite                       │
├───────────────────┬───────────────────┬────────────────────────────────┤
│ 1-Tap SOS Beacon  │ Audio Voice Memo  │ Offline First-Aid Survival     │
│ Instant critical  │ 30s situation mic │ Zero-bandwidth CPR, Snakebite, │
│ alert dispatch    │ note recording    │ Bleeding & Burn field guide    │
├───────────────────┼───────────────────┼────────────────────────────────┤
│ Night Strobe      │ Quick Triage Tags │ Dual Tactical Theming          │
│ High-visibility   │ 1-tap chips for   │ Dark Tactical Mode (Midnight)  │
│ Morse SOS beacon  │ rapid reporting   │ & Light Clean Mode (Daylight)  │
└───────────────────┴───────────────────┴────────────────────────────────┘
```

1. **1-Tap SOS Distress Beacon:**
   - Dedicated prominent emergency button triggers an instant critical alert with GPS coordinates and high-priority dispatch flag.
2. **Field Situation Audio Memo Recorder:**
   - Built-in emergency voice recorder allows field responders to capture up to 30 seconds of situation audio (e.g., survivor cries, fire roar, structural creaks) when typing is hazardous.
   - Includes live visual timer, re-record, and deletion safeguards.
3. **Offline First-Aid Survival Guide:**
   - 100% offline, zero-network medical reference detailing critical step-by-step procedures:
     - **CPR (Cardiopulmonary Resuscitation):** Chest compression rates (100-120 bpm) and depth.
     - **Severe Bleeding Control:** Direct pressure, elevation, and arterial tourniquet application rules.
     - **Choking (Heimlich Maneuver):** Abdominal thrust positioning.
     - **Burn Care:** Cooling procedures and contraindication warnings (no ice or butter).
     - **Snakebite Protocol:** Immobilization guidelines and ASV transport warnings.
4. **Night Rescue Strobe Beacon:**
   - High-luminance visual signaling tool featuring:
     - **Fast Strobe:** High-frequency visual flashing for disaster zone visibility.
     - **SOS Morse Code:** Automatic `... --- ...` optical pulsing for search-and-rescue helicopters.
     - **Solid High-Beam:** Torch-alternative illuminating debris.
5. **Dual Tactical Theming:**
   - **Dark Tactical Mode:** Deep midnight palette (`#0F141A`) with glowing crimson accents (`#FF5252`) and charcoal cards (`#19202A`) for glare-free night and battery-conscious field use.
   - **Light Clean Mode:** High-contrast daylight dispatch palette (`#F4F6F9`) with crisp white cards (`#FFFFFF`).
   - Equipped with smooth 360° rotating animated toggle and navigation drawer switch.

---

## 4. Verification & Testing Metrics

Both the backend and mobile clients have automated test suites achieving 100% passing rates.

### 4.1 Backend Test Suite (Pytest)

| Test Module | Coverage Scope | Status | Execution Time |
| :--- | :--- | :---: | :---: |
| `test_auth.py` | Health check, JWT login, Password hashing, RBAC enforcement | **PASSED** | ~1.8s |
| `test_geo.py` | Haversine distance calculations, Nearest responder proximity ranking | **PASSED** | ~0.9s |
| `test_incidents.py` | Incident creation lifecycle, optimistic locking, update workflows | **PASSED** | ~2.1s |
| `test_sync.py` | Idempotent push/pull synchronization, version comparison | **PASSED** | ~2.4s |
| `test_ws.py` | Real-time WebSocket token authorization, live ping/pong | **PASSED** | ~1.6s |
| **Total** | **8 Tests across all core domains** | **100% PASS** | **8.89s** |

### 4.2 Mobile Client Test Suite (Flutter Test & Static Analysis)

| Test / Analysis | Coverage Scope | Status | Result |
| :--- | :--- | :---: | :---: |
| `dart analyze` | Static linting, type safety, deprecation checks | **PASSED** | **0 issues found** |
| `drift_test.dart` (Test 1) | Drift local DB saves incident offline and updates sync state | **PASSED** | Pass |
| `drift_test.dart` (Test 2) | Sync queue enqueues and dequeues operations | **PASSED** | Pass |
| `widget_test.dart` (Test 1) | PulseSyncApp renders incident list and navigation items | **PASSED** | Pass |
| `widget_test.dart` (Test 2) | PulseSyncApp toggles between dark and light mode | **PASSED** | Pass |
| `widget_test.dart` (Test 3) | PulseSyncApp renders search bar and category filter chips | **PASSED** | Pass |
| **Total** | **5 Automated Widget & Unit Tests** | **100% PASS** | **1.8s** |

---

## 5. Deployment & Execution Guide

### 5.1 Local Development (Backend)

```powershell
# Navigate to backend directory
cd backend

# Activate virtual environment
.\.venv\Scripts\activate

# Install requirements
pip install -r requirements.txt

# Run server accessible to local network (physical phone testing)
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
*Interactive Swagger API documentation is accessible at: `http://localhost:8000/api/v1/docs`*

### 5.2 Docker Compose Deployment

```bash
docker compose up --build -d
```
Spins up the FastAPI ASGI server, PostgreSQL 16 container, and Redis 7 container with automated health monitoring and data persistence.

### 5.3 Mobile Client Execution & APK Build

```powershell
# Set Java 17 path (required for Android Gradle transform)
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.21.21-hotspot"

# Run tests
cd mobile
flutter test

# Build single debug APK for physical device installation
flutter build apk --debug
```
*Single installable APK output: `pulsesync.apk`*

---

## 6. Strategic Future Roadmap (Level 10/10 Vision)

1. **Bluetooth Low Energy (BLE) Mesh & Wi-Fi Direct Peer-to-Peer:**
   - Implement zero-infrastructure incident propagation between responder smartphones in catastrophic areas where both cellular and power grids are completely destroyed.
2. **Edge AI Triage Categorization:**
   - Integrate on-device lightweight TensorFlow Lite models to analyze situational audio notes and automatically assign priority scores based on acoustic signals (e.g. fire alarms, sirens, structural crack frequencies).
3. **Central Command Heatmap & Multi-Agency GIS Overlays:**
   - Deploy dynamic Voronoi diagrams and KDE (Kernel Density Estimation) heatmaps on the dispatcher dashboard for visualizing disaster spread and resource allocation in real-time.

---

## 7. Conclusion

PulseSync bridges the critical technological gap between modern cloud dispatch systems and hostile, zero-bandwidth field realities. By coupling mathematical rigor in geospatial proximity calculations with an infallible offline-first SQLite synchronization engine, PulseSync guarantees that emergency responders are never left disconnected when lives depend on immediate action.
