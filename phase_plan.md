# Phase Plan — REBS HRMS (Offline-Capable Employee Workspace)

**Stack:** Flutter + Dart (null safety) · BLoC · Drift (SQLite) · Dio · Dart Shelf mock server
**Total budget:** 8 hours (7 hours planned work + 1 hour buffer)

---

## How to use this plan

1. Work **one phase at a time**, in order.
2. Do not start the next phase until the **"Done when"** check of the current phase passes.
3. After each phase: run `flutter analyze` and `flutter test`, then make a Git commit.
4. Update `task_progress.md` at the end of every phase (tick boxes, write the real time spent).

**Why this order?** The hard and risky parts (rules, storage, sync) come first. The screens come after, because screens are easy once the logic is solid and tested. If time runs out, the UI can be simple, but a broken sync engine cannot be hidden.

---

## Time budget

| Phase | What | Planned time |
|---|---|---|
| 0 | Project setup | 0.50 h |
| 1 | Mock server (Shelf) | 0.75 h |
| 2 | Domain rules and pure Dart logic (+ tests) | 0.75 h |
| 3 | Data layer: Drift, Dio, repositories | 1.25 h |
| 4 | Sync engine (+ tests) | 1.50 h |
| 5 | Dashboard and attendance UI (+ widget test) | 1.00 h |
| 6 | Leave feature | 0.75 h |
| 7 | Finish: README, APK, video | 0.50 h |
| — | Buffer for bugs and surprises | 1.00 h |
| | **Total** | **8.00 h** |

---

## Phase 0 — Project setup (0.5 h)

**Goal:** A clean, running skeleton so every later phase has a place to put code.

**Tasks**
- [ ] Create Git repo and `.gitignore` (include `*.env`, `build/`, `.dart_tool/`, generated files if you choose not to commit them).
- [ ] `flutter create` the app. Create `mock_server/` folder for the Shelf project.
- [ ] Add dependencies (see README → Dependencies).
- [ ] Create the folder structure from `coding_laws_and_architecture.md`.
- [ ] Add `analysis_options.yaml` with strict rules (`flutter_lints` + `always_use_package_imports`, `prefer_final_locals`).
- [ ] Read the API base URL from `--dart-define=API_BASE_URL` (never hardcode).
- [ ] Create README skeleton from the draft.

**Done when:** The app runs on an emulator, `flutter analyze` is clean, first commit is made.
**Branch/commit:** `chore: project setup`

---

## Phase 1 — Mock server with Dart Shelf (0.75 h)

**Goal:** A fake backend that behaves like a real one, including the bad days.

**Tasks**
- [ ] Shelf project with `shelf` and `shelf_router`. Data stored in memory.
- [ ] Seed data: 1 employee, office location and radius, company timezone, 8 attendance records, leave balance, 3 leave requests (1 Pending, 1 Approved, 1 Rejected).
- [ ] 6 endpoints from the assignment:
  `GET /employee/me`, `GET /attendance?month=`, `POST /attendance/events`, `GET /leave/balance`, `GET /leave/requests`, `POST /leave/requests`.
- [ ] **Idempotency** on `POST /attendance/events` using `clientEventId`.
- [ ] Server-side checks (the ones production must repeat): order, once per day, distance, valid timestamp.
- [ ] Scenario switch: `POST /__scenario {"mode": "..."}`, `GET /__scenario`, `POST /__reset`.
- [ ] Scenarios: `success`, `slow`, `timeout`, `accept_then_timeout`, `server_error`, `duplicate_conflict`, `leave_rejected`.
- [ ] Test every scenario with `curl` and keep the commands in the README.

**Done when:** Every scenario returns what the README table says, and `accept_then_timeout` really saves the record but does not reply.
**Commit:** `feat(mock-server): endpoints, idempotency and scenarios`

**Risk:** Spending too long on server polish. Keep it simple, it only exists to test the app.

---

## Phase 2 — Domain rules and pure Dart logic (0.75 h)

**Goal:** All business rules written as **plain Dart classes** with no Flutter, no database, no network. They are fast to write and easy to test.

**Tasks**
- [ ] Entities: `Employee`, `OfficeConfig`, `AttendanceEvent`, `AttendanceRecord`, `LeaveRequest`, `LeaveBalance`.
- [ ] `Clock` abstraction (so tests can control "now").
- [ ] `CompanyCalendar`: converts an instant to the company date using the configured timezone.
- [ ] `DistanceCalculator` (Haversine) and `GeofenceRule` (200 m).
- [ ] `AttendanceRules`: `canCheckIn`, `canCheckOut`, `deriveTodayStatus`.
- [ ] `LeaveValidator`: the 5 rules from the assignment.
- [ ] Failure types (sealed classes) with human-readable messages.
- [ ] **Tests:** check-out without check-in is rejected · second check-in on the same day is rejected · overlapping leave is rejected · end before start · reason under 10 characters · balance exceeded · inside/outside 200 m.

**Done when:** All rule tests are green.
**Commit:** `feat(domain): attendance and leave rules with tests`

---

## Phase 3 — Data layer (1.25 h)

**Goal:** Talk to the server and the local database, and hide both behind repositories.

**Tasks**
- [ ] Drift tables: `employee_cache`, `attendance_records`, `attendance_events` (the outbox queue), `leave_requests`, `leave_balance`.
- [ ] `attendance_events` columns: local `sequence` (auto-increment, defines order), `clientEventId` (UUID), `type`, `occurredAt` (UTC), `companyDate`, `latitude`, `longitude`, `accuracy`, `isMockedLocation`, `status` (pending/synced/rejected), `attempts`, `lastError`, `createdAt`.
- [ ] Dio client with connect/receive timeouts (10 s) and one place for error mapping.
- [ ] DTOs and mappers (server JSON ↔ domain entities).
- [ ] Repositories: `EmployeeRepository`, `AttendanceRepository`, `LeaveRepository`.
- [ ] `ConnectivityService` (wrap `connectivity_plus`, exposes a stream and a "is online now" check).
- [ ] `LocationService` interface with two implementations: `GeolocatorLocationService` and `SimulatedLocationService`.
- [ ] Offline reads: if the network fails, return cached data and mark it as "from cache".

**Done when:** With the mock server switched off, the repositories still return cached data. Drift tests use an in-memory database.
**Commit:** `feat(data): drift storage, dio client and repositories`

---

## Phase 4 — Sync engine (1.5 h) ⭐ most important phase

**Goal:** Pending events reach the server **in order, exactly once**, whatever the network does.

**Tasks**
- [ ] Outbox pattern: every check-in/out is **first saved locally as Pending**, then the sync engine sends it. Online and offline use the same path.
- [ ] `SyncService.syncNow()`:
  - Only one sync can run at a time (a lock).
  - Take pending events ordered by `sequence`.
  - Send one at a time. Wait for the result before sending the next.
- [ ] Result handling:
  | Server result | What the app does |
  |---|---|
  | 201 created | mark **Synced** |
  | 200 duplicate (same `clientEventId`) | mark **Synced** |
  | 409 / 422 business rejection | mark **Rejected** with the reason, then mark later dependent events Rejected too |
  | timeout / no network / 5xx | keep **Pending**, stop the loop, retry later with the **same** `clientEventId` |
- [ ] Triggers: after each local save, on app start, when connectivity returns, and the "Sync Now" button.
- [ ] After a successful sync, refresh the attendance records from the server.
- [ ] `SyncBloc` exposes: idle, syncing, pending count, last error.
- [ ] **Tests (required by the assignment):**
  - Retry does not create a duplicate (same ID sent twice, server stores one).
  - Pending events survive "restart" (close and reopen the in-memory DB file, or recreate the repository on the same database).
  - Pending events are synced in order (check-in first, then check-out).
  - Timeout after server accepted → retry → treated as Synced, not Rejected.
  - Rejected check-in also rejects the dependent check-out.

**Done when:** All sync tests are green, and a manual run against every mock scenario behaves as the README table says.
**Commit:** `feat(sync): ordered idempotent outbox sync with tests`

---

## Phase 5 — Dashboard and attendance UI (1.0 h)

**Goal:** The screens for demo steps 1 to 5.

**Tasks**
- [ ] `DashboardBloc`: loads employee, today status, balance, last 5 records. States: loading, empty, error, loaded (with `isOffline` and `isFromCache` flags).
- [ ] `AttendanceActionBloc`: handles check-in and check-out taps with a **droppable** transformer (extra taps are ignored while one is running).
- [ ] Dashboard page: employee card, today card (status, times, elapsed), leave balance card, last 5 records list, offline banner, pending-sync badge.
- [ ] Location problem messages: denied, permanently denied (with "Open Settings"), services off, unavailable, outside 200 m (show the distance).
- [ ] Sync Status page: list of events with Pending / Synced / Rejected chips, "Sync Now" button.
- [ ] Responsive layout: use `LayoutBuilder`, scrollable content, no fixed heights.
- [ ] **Widget test:** pending-sync state shows the badge and the pending chip (or loading/error state).

**Done when:** Demo steps 1–5 work end to end on an emulator.
**Commit:** `feat(ui): dashboard, attendance actions and sync status`

---

## Phase 6 — Leave feature (0.75 h)

**Tasks**
- [ ] `LeaveBloc` (or Cubit) for the list and the form.
- [ ] Leave list page with Pending / Approved / Rejected chips, cached for offline view.
- [ ] Leave form: type, start date, end date, reason, live "days requested" text.
- [ ] Use `LeaveValidator` for local checks; show errors under each field.
- [ ] Submit button disabled with a clear message when offline.
- [ ] Map server validation errors (422) to the form. Show them even when local validation passed.
- [ ] After success: refresh list and balance.

**Done when:** Demo step 6 works, including a server rejection via the `leave_rejected` scenario.
**Commit:** `feat(leave): form, validation and requests list`

---

## Phase 7 — Finish (0.5 h)

**Tasks**
- [ ] Final README: architecture, setup, assumptions, completed features, limitations, time spent, AI disclosure.
- [ ] Build the debug APK with the ngrok URL: `flutter build apk --debug --dart-define=API_BASE_URL=<url>`.
- [ ] Install the APK on a real device once and test.
- [ ] Record the 3–5 minute demo video (script below).
- [ ] Remove dead code and TODOs, run `flutter analyze` and `flutter test` one last time.
- [ ] Tag the commit: `v1.0-submission`.
- [ ] Confirm no secrets in Git history (no ngrok token, no real URLs hardcoded).

**Commit:** `docs: final README and submission notes`

### Demo video script (3–5 minutes)

1. **Dashboard loading** (30 s): show loading, then data.
2. **Online check-in** (30 s): tap check-in, show Synced.
3. **Offline action** (45 s): switch to airplane mode, check-out, show Pending Sync.
4. **Restart** (30 s): kill the app, reopen, the pending item is still there.
5. **Reconnect and sync** (45 s): turn network on, show auto-sync or tap "Sync Now", item becomes Synced.
6. **Leave** (60 s): show a local validation error, a server rejection, and a successful submission.
7. **Extra** (30 s): show the timeout scenario and say how idempotency avoids duplicates.

---

## If time runs short: the cut list

Cut from the top. **Never cut** the items marked 🔒.

1. Extra UI polish and animations
2. Month paging for attendance history
3. Debug panel extras
4. Dismiss action for Rejected events
5. 🔒 Sync engine and its tests
6. 🔒 The 4 required tests + 1 widget test
7. 🔒 README with limitations and trade-offs (the assignment says to document unfinished work)
