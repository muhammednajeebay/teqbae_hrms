# REBS HRMS: Offline-Capable Employee Workspace

A Flutter app where one preconfigured employee can check in/out, view attendance, and apply for leave. It works offline and syncs safely when the internet returns.

> Draft: replace every **TODO** with what was really built before submitting.

---

## 1. What is built

| Feature                                                                         | Status |
| ------------------------------------------------------------------------------- | ------ |
| Dashboard (employee info, today's status, times, leave balance, last 5 records) | TODO   |
| Check-in / check-out with GPS (200 m rule)                                      | TODO   |
| Offline cache and pending events (survive restart)                              | TODO   |
| Sync: manual "Sync Now" + auto on reconnect                                     | TODO   |
| Leave form, validation, and list                                                | TODO   |

Use: ✅ Done · 🟨 Partial · ❌ Not done

---

## 2. Tech stack

Flutter + Dart · BLoC · Drift (SQLite) · Dio · Dart Shelf (mock server)

**Why:**

- **BLoC:** clear events and states, easy to test, ignores repeated taps.
- **Drift:** ordered queue for pending events, safe transactions, easy tests.
- **Shelf:** same language as the app, so I can explain and change it.

More detail: `decisions.md`.

---

## 3. Architecture

```
Presentation (screens, BLoCs)  →  Domain (rules, pure Dart)  ←  Data (Drift, Dio)
```

- **Presentation:** shows state, sends events. No logic in `build()`.
- **Domain:** attendance rules, 200 m rule, leave validation. No Flutter/Drift/Dio.
- **Data:** database, API, repositories.

Every check-in/out is **saved locally first as Pending**, then a sync engine sends it. Online and offline use the same path.

---

## 4. Setup

**Start the mock server**

```bash
cd mock_server
dart pub get
dart run bin/server.dart      # http://localhost:8080 (TODO: confirm port)
```

**Run the app**

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

| Device              | API URL                            |
| ------------------- | ---------------------------------- |
| Android emulator    | `http://10.0.2.2:8080`             |
| Real device (ngrok) | `https://<your-id>.ngrok-free.app` |

**Build APK**

```bash
flutter build apk --debug --dart-define=API_BASE_URL=https://<your-id>.ngrok-free.app
```

**ngrok:** run `ngrok http 8080` and keep it (and the mock server) running during review. The free URL changes on restart.

**Tests:** `flutter test`

---

## 5. Mock server scenarios

Switch scenario:

```bash
curl -X POST http://localhost:8080/__scenario -H "Content-Type: application/json" -d '{"mode":"timeout"}'
curl -X POST http://localhost:8080/__reset     # reset everything
```

| Mode                  | What happens                             |
| --------------------- | ---------------------------------------- |
| `success`             | Normal responses                         |
| `slow`                | Answers after ~4 seconds                 |
| `timeout`             | No reply in time                         |
| `accept_then_timeout` | Server saves the event but never replies |
| `server_error`        | Returns 500                              |
| `duplicate_conflict`  | Returns 409 for a new event              |
| `leave_rejected`      | Leave submission returns 422             |

(TODO: confirm names match the code.)

---

## 6. Simulating location

- **In-app:** Menu → Debug → turn on _Simulated location_ → choose _At office_, _500 m away_, or _Unavailable_.
- **Emulator:** Extended controls → Location → set coordinates near the office (TODO: add coordinates).

---

## 7. Sync: identity and idempotency

- Each event gets a **UUID (`clientEventId`)** when the user taps. It never changes, even on retry or restart.
- The server remembers the IDs it has seen. A repeated ID returns "duplicate" and creates **no** new record.
- Events are sent **one at a time, oldest first**. If the network fails, sync stops, so a check-out never arrives before its check-in.

| Server answer              | App does                              |
| -------------------------- | ------------------------------------- |
| 201 created                | Synced                                |
| 200 duplicate              | Synced                                |
| 409 / 422                  | Rejected (with reason)                |
| Timeout / no network / 5xx | Stays Pending, retry with the same ID |

**Timeout case:** the server saved the event but the reply was lost → app retries with the same ID → server says "duplicate" → app marks Synced. One record only.

---

## 8. What the production server must repeat

The phone checks are for user experience only. The server must also check:

1. Who the employee is (authentication)
2. Distance from the office
3. One check-in per day, and check-out only after check-in
4. Duplicate events by `clientEventId`
5. Timestamp (device time can be wrong or faked)
6. Company date and timezone
7. All leave rules (balance, overlap, dates)

---

## 9. Assumptions

- One preconfigured employee, no login.
- One attendance session per day, no overnight shifts.
- Company timezone decides "today".
- All calendar days count as leave.
- The server's leave balance is final (Pending requests are not subtracted again).
- Leave submission needs internet. Leave list is cached.
- Sync runs only while the app is open.
- Mock server data is in memory and resets on restart.

---

## 10. Limitations

- TODO: list anything unfinished.
- No background sync.
- Free ngrok URL changes when restarted.

---

## 11. Time spent

| Part                  | Hours    |
| --------------------- | -------- |
| Setup + mock server   | TODO     |
| Rules + data layer    | TODO     |
| Sync engine           | TODO     |
| UI + leave            | TODO     |
| README, APK, video    | TODO     |
| **Total (limit 8 h)** | **TODO** |

---

## 12. AI disclosure

TODO: write the truth. Example:

- Tool: Claude (Anthropic)
- Used for: planning, architecture discussion, and documentation drafts (TODO: add code help if used)
- I reviewed everything and can explain and modify all of it.

---

## Other docs

`phase_plan.md` · `logic.md` · `decisions.md` · `coding_laws_and_architecture.md` · `task_progress.md`
