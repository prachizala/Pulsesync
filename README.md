# PulseSync

> Offline-first Emergency & Field Operations Dispatch System

PulseSync is designed for rapid and resilient coordination during emergency response operations, even with intermittent or zero network connectivity.

## System Architecture

- **Backend**: Python 3.11+, FastAPI (Async), Async SQLAlchemy 2.0, PostgreSQL, Redis Pub/Sub, WebSockets, JWT role-based access control.
- **Mobile**: Flutter (Dart 3+), Riverpod state management, Drift (SQLite) offline storage, background auto-sync via `connectivity_plus`, OpenStreetMap via `flutter_map`, and device location with `geolocator`.

## Project Structure

```text
pulsesync/
├── backend/
│   ├── app/
│   │   ├── api/v1/endpoints/
│   │   ├── core/
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── services/
│   │   └── main.py
│   ├── docker/
│   ├── tests/
│   ├── requirements.txt
│   └── README.md
├── mobile/
│   ├── lib/
│   │   ├── core/
│   │   ├── data/
│   │   ├── logic/
│   │   ├── views/
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── README.md
├── .gitignore
└── README.md
```

## Setup & Development

See backend and mobile directories for their respective setup guides.
