# REBS HRMS: Offline-Capable Employee Workspace

A production-grade, offline-first Flutter HRMS client application where a preconfigured employee can record attendance with geofencing, track daily hours, view monthly records, and submit leave requests. It handles unstable networks and total offline conditions gracefully via an ordered, transactional Outbox pattern with strict idempotency.

---

## 1. What is Built

| Feature | Status | Notes |
|---|---|---|
| **Dashboard** | ✅ Done | Employee header, today's status & timers, leave balance, last 5 attendance records, quick actions |
| **Attendance Action (Check-In / Check-Out)** | ✅ Done | Geofenced within 200m Haversine, optimistic local write, droppable event transformer |
| **Offline Cache & Persistence** | ✅ Done | Drift SQLite database; pending outbox events survive app restarts |
| **Reliable Sync Engine** | ✅ Done | Ordered single-lock queue, idempotent `clientEventId`, dependent-event rejection, auto-reconnect trigger |
| **Attendance History** | ✅ Done | Monthly breakdown with badge indicators (present, half-day, pending, rejected) |
| **Leave Management** | ✅ Done | Cached leave list, balance display, 5-rule client-side validator, 422 server error mapping |
| **Debug & Test Panel** | ✅ Done | Built-in scenario switcher, mock server reset, simulated location presets, manual sync trigger |

---

## 2. Tech Stack & Choices

- **Flutter (Dart 3.x):** Single cross-platform codebase following Material 3 guidelines.
- **BLoC & Cubit (`flutter_bloc` 9.x):** Predictable unidirectional state management. Attendance events use `droppable()` transformers to prevent multi-tap race conditions.
- **Drift (SQLite):** Type-safe, reactive database supporting ACID transactions, perfect for the transactional Outbox queue and offline cache.
- **Dio (`dio` 5.x):** Configurable HTTP client with strict connection and receive timeouts (5s default) and typed error handling.
- **Shelf (`shelf` 1.4.x):** Pure Dart mock backend for 100% reproducible development and testing across various failure scenarios without third-party external dependencies.

*Architecture and design decisions are documented in detail in `decisions.md` and `coding_laws_and_architecture.md`.*

---

## 3. Architecture

The project strictly follows Clean Architecture:

```
Presentation Layer (UI, Pages, BLoCs, Cubits)
        ↓ depends on
Domain Layer (Entities, Pure Business Rules, Use Cases, Repositories Interfaces)
        ↑ implemented by
Data Layer (Drift Database, Dio Network Client, Repositories Implementations)
```

### Architectural Guarantees
1. **Domain Layer Independence:** Pure Dart. Zero dependencies on Flutter, Drift, Dio, or platform APIs. Contains business invariants (attendance sequence, 200m geofencing, 5 leave validation rules).
2. **Offline-First Outbox Pattern:** Every attendance action is saved locally in a Drift transaction as `pending` with a unique `clientEventId` (UUID v4) before any network call is initiated. Online and offline follow the identical code path.
3. **Single Sync Lock & Ordering:** Sync runs through an asynchronous mutex lock. Pending events are dispatched sequentially, oldest first. If a network failure occurs, synchronization pauses immediately to preserve causality (preventing a check-out from syncing before its check-in).

---

## 4. Setup & Running Instructions

### Prerequisites
- Flutter SDK 3.27+ / Dart SDK 3.6+
- Android Studio / VS Code with Flutter extension
- Android Emulator or physical device

### Step 1: Start the Mock Server
Open a terminal in the project root:
```bash
cd mock_server
dart pub get
dart run bin/server.dart
```
The mock server starts on `http://localhost:8080` (or `http://0.0.0.0:8080`).

### Step 2: Run the Flutter App
In a separate terminal:
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs --force-jit
```

Run with the appropriate `--dart-define` for your environment:

| Target Environment | Run Command |
|---|---|
| **Android Emulator** | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080` |
| **Physical Device (ngrok)** | `flutter run --dart-define=API_BASE_URL=https://<your-subdomain>.ngrok-free.app` |
| **Physical Device (LAN)** | `flutter run --dart-define=API_BASE_URL=http://<host-machine-ip>:8080` |
| **Desktop / Web** | `flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080` |

### Step 3: Build Debug APK
```bash
flutter build apk --debug --dart-define=API_BASE_URL=https://<your-subdomain>.ngrok-free.app
```
The output APK is generated at: `build/app/outputs/flutter-apk/app-debug.apk`.

### Step 4: Run Tests & Verification
```bash
# Run all unit, domain, repository, sync, and widget tests
flutter test

# Verify static code analysis
flutter analyze
```

---

## 5. Mock Server Failure Scenarios

The Shelf server provides built-in scenario simulation for network conditions. You can switch modes via the in-app **Debug Panel** or via `curl`:

```bash
# Set scenario mode
curl -X POST http://localhost:8080/__scenario -H "Content-Type: application/json" -d '{"mode":"timeout"}'

# Reset server data and scenario mode to default
curl -X POST http://localhost:8080/__reset
```

| Scenario Mode | Server Behavior | Client Handling |
|---|---|---|
| `success` | 200/201 normal responses | Event transitions to `synced` |
| `slow` | Delays response by 4 seconds | UI shows progress indicator, eventually syncs |
| `timeout` | Drops connection after timeout delay | Dio throws receive timeout; event stays `pending` for retry |
| `accept_then_timeout` | Server saves record, but client receives socket timeout | Event stays `pending`; next sync retries with same `clientEventId`, server detects duplicate and returns 200, app marks `synced` without duplicate |
| `server_error` | Returns HTTP 500 Internal Error | Sync pauses; event stays `pending` |
| `duplicate_conflict` | Returns HTTP 409 Conflict | Server rejected; event marked `rejected` |
| `leave_rejected` | Leave submission returns HTTP 422 Unprocessable | Form shows server validation error |

---

## 6. Location Simulation & Geofencing

The app enforces a **200-meter radius** around the office location (`12.9716° N, 77.5946° E` by default).

To easily test without physical movement:
1. Tap the **Tune / Sliders icon** in the top AppBar to open the **Debug & Developer Panel**.
2. Under **Location Simulation**, choose:
   - **Real Device GPS:** Queries hardware GPS using `geolocator`.
   - **At Office (Within 200m):** Simulates coordinates `12.9716, 77.5946` (0 meters distance). Check-in allowed.
   - **500m Away (Outside):** Simulates coordinates `12.9760, 77.5946` (~489 meters distance). Check-in blocked with distance warning.
   - **Unavailable / GPS Error:** Simulates location service disabled or permission denied.

---

## 7. Sync Protocol: Idempotency & Invariants

1. **Client Event Identity:** Every check-in/out event generates a persistent UUID (`clientEventId`). This ID never changes across retries, restarts, or crashes.
2. **Server Idempotency:** The mock server tracks processed `clientEventId`s. Receiving an already-processed event returns `200 OK` (`duplicate: true`), preventing duplicate attendance records.
3. **Causal Ordering:** Events are queued in Drift by autoincrement ID and timestamp. Synchronization occurs sequentially.
4. **Dependent-Event Rejection:** If event A (Check-In) is rejected with a 4xx error (e.g. 409 Conflict), the subsequent event B (Check-Out) is automatically rejected locally without sending an invalid request to the server.
5. **Survives Restart:** All pending events and leave balances are persisted in SQLite; killing and reopening the app retains pending status and automatically triggers sync when network is detected.

---

## 8. What the Production Server Must Enforce

Client-side checks provide immediate feedback and smooth UX, but the production backend must independently validate:
1. **Authentication & Authorization:** Verify JWT/Bearer token and map to authentic employee identity.
2. **Geofence Boundary:** Recalculate Haversine distance between company office coordinates and reported GPS coordinates.
3. **Session Consistency:** Enforce exactly one active check-in session per day; reject check-outs without check-ins.
4. **Idempotency Store:** Store processed `clientEventId` in Redis/PostgreSQL with unique constraints.
5. **Server Timestamps:** Validate device timestamps against server time with acceptable drift tolerance (e.g. ±5 minutes) to prevent clock tampering.
6. **Company Calendar & Timezone:** Ensure day boundaries conform to the company timezone (`Asia/Kolkata`), not the device local timezone.
7. **Leave Quotas & Overlaps:** Check leave balance atomicity under database transactions to prevent race conditions.

---

## 9. Assumptions Made

- **Single Preconfigured Employee:** Authentication is pre-wired to the active employee profile (`EMP001`) as specified in the assignment prompt.
- **Single Daily Shift:** One check-in and one check-out per calendar day; overnight shift spans across midnight are not considered.
- **Company Timezone:** System date boundaries are anchored to `Asia/Kolkata` using the `timezone` package.
- **Leave Request Policy (Decision D21):** Leave requests require active network connectivity. Failed leave submissions display inline validation and do not queue in the offline attendance outbox. Leave history and balances are cached offline.
- **Mock Server Lifecycle:** Mock server state is maintained in-memory for zero-friction local development and can be reset at any time using `POST /__reset`.

---

## 10. Limitations & Trade-offs

- **Background Sync:** Synchronization triggers on app launch, network reconnection, attendance action, and manual "Sync Now". True OS background execution (WorkManager / BGAppRefreshTask) was omitted to keep within the 8-hour assignment scope.
- **Mock Location Detection:** For ease of reviewer testing, simulated mock locations are explicitly permitted rather than blocked.
- **ngrok Session Limits:** On the free ngrok tier, tunnels expire upon restart, requiring updating `--dart-define=API_BASE_URL`.

---


## 12. AI-Usage Disclosure

In accordance with academic and evaluation integrity:
- **Claude (Anthropic):** assignment analysis, architecture planning, and drafting the planning documents (phase plan, logic, decisions, coding rules, README draft).
- **Antigravity / Gemini:** (write what you really used it for, such as mock server routes or test scaffolding).
- I reviewed everything, and I can explain and modify all of it.

---

## Project Documentation Index

- [`phase_plan.md`](phase_plan.md) — Implementation schedule and milestone breakdown.
- [`logic.md`](logic.md) — Exhaustive business rules, calculations, and error tables.
- [`decisions.md`](decisions.md) — Architectural decision records (ADRs).
- [`coding_laws_and_architecture.md`](coding_laws_and_architecture.md) — Layer boundaries, dependency rules, and coding standards.
- [`task_progress.md`](task_progress.md) — Real-time task tracking and time log.
- [`Demo Video`](Muhammed_Najeeb_REBS_HRMS_demo.mp4) — Demo video of the app.
- [`Release APK`](Muhammed_Najeeb_REBS_HRMS_release.apk) — Ready-to-install Android Release APK.

<video controls src="Muhammed_Najeeb_REBS_HRMS_demo.mp4" title="Title"></video>

---

## 13. Step-by-Step Guide: Running with ngrok (Physical Device Testing)

This guide explains how to expose the local Shelf mock server to the public internet using **ngrok** so that a physical Android phone or external reviewer can connect and test the app.

### 1. Prerequisites
- Install ngrok on Windows:
  ```powershell
  winget install ngrok.ngrok
  ```
  *(Or download from [ngrok.com/download](https://ngrok.com/download))*.
- Verify you have a modern version (`ngrok --version`). If it is below `3.30.0`, run `ngrok update`.
- Sign up for a free account at [ngrok.com](https://ngrok.com) and retrieve your authtoken from your dashboard.
- Connect your authtoken (one-time setup):
  ```powershell
  ngrok config add-authtoken <your-authtoken>
  ```

---

### 2. Execution Runbook

You will need **three terminal windows** during testing:

#### Window 1: Start the Local Mock Server
```powershell
cd mock_server
dart run bin/server.dart
```
> Keep this terminal open and running. It will show:
> `REBS HRMS mock API listening on http://0.0.0.0:8080`

#### Window 2: Start the ngrok Tunnel
If you have claimed a free static domain (recommended, e.g. `powdery-paramedic-lining.ngrok-free.dev`):
```powershell
ngrok http --domain=powdery-paramedic-lining.ngrok-free.dev 8080
```
Or for a standard random URL:
```powershell
ngrok http 8080
```
> Keep this terminal open. Look for the line:
> `Forwarding https://<your-subdomain>.ngrok-free.dev -> http://localhost:8080`
> Copy that HTTPS URL.

#### Window 3: Run or Build the App

**Option A: Run live in Debug mode on your connected phone / emulator:**
```powershell
flutter run --dart-define=API_BASE_URL=https://<your-subdomain>.ngrok-free.dev
```

**Option B: Build the standalone Release APK to share with testers:**
```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://<your-subdomain>.ngrok-free.dev
```
The output file will be saved at:
`build/app/outputs/flutter-apk/app-release.apk`

---

### 3. Testing on the Physical Phone
1. Install `app-release.apk` on the phone.
2. Open the app — the dashboard connects via the ngrok URL to your computer's mock server.
3. **Test Online Attendance:** Tap **Check In** or **Check Out** within the office area.
4. **Test Offline Sync:** Turn on **Airplane Mode** on the phone, tap **Check In** or **Check Out** (saved locally as "Pending"), turn off Airplane Mode, and watch the event automatically sync to the server.
5. **Test Edge Cases via Debug Panel:** Tap the **Tune icon (sliders)** in the top AppBar to switch server scenarios (`timeout`, `slow`, `server_error`, `accept_then_timeout`) or simulate GPS locations (`At Office`, `500m Away`, `GPS Off`) directly from the device.
