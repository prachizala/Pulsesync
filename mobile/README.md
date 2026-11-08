# PulseSync - Mobile Field Operations Client

Offline-first Flutter application for first responders and field dispatch teams.

## Key Capabilities

- **Offline-First Persistence**: Powered by [Drift](https://drift.simonbinder.eu/) (SQLite). All incidents and breadcrumb locations are saved locally before network transmission.
- **Adaptive Auto-Sync**: Background network monitoring via `connectivity_plus`. Automatically dispatches queued incidents upon re-establishing Wi-Fi or Cellular network connections.
- **Interactive Geospatial Mapping**: Powered by `flutter_map` with OpenStreetMap raster tiles, rendering real-time incidents categorized by urgency level.
- **State Management**: Reactive state management with `flutter_riverpod`.

## Project Structure

```text
mobile/
├── lib/
│   ├── core/
│   │   ├── api_client.dart       # HTTP client with auth and sync push/pull
│   │   └── constants.dart        # URLs, status enums, priority constants
│   ├── data/
│   │   └── local/
│   │       ├── database.dart     # Drift DB tables, DAOs & query helpers
│   │       └── database.g.dart   # Generated Drift code
│   ├── logic/
│   │   ├── providers.dart        # Riverpod dependency injection graph
│   │   └── sync/
│   │       └── sync_service.dart # Auto-sync engine and queue flusher
│   ├── views/
│   │   ├── incident_list_screen.dart   # Dashboard with sync status & feeds
│   │   ├── incident_report_screen.dart # Report creator with GPS capture
│   │   └── map_screen.dart             # OSM dynamic field map
│   └── main.dart                 # Application entrypoint
├── pubspec.yaml
└── README.md
```

## Running the App

### 1. Install Dependencies & Generate Database
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 2. Run on Emulator / Device
```bash
# Windows Desktop
flutter run -d windows

# Android Device / Emulator
flutter run -d android

# Chrome / Web
flutter run -d chrome
```
