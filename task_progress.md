# Task Progress — REBS HRMS

**Legend:** ⬜ Not started · 🟨 In progress · ✅ Done · ⛔ Blocked · ✂️ Cut (document in README)

| Item | Value |
|---|---|
| Assignment received on | Day 1 |
| Submission deadline (3 days) | Day 3 |
| Effort limit | 8 hours |
| Total time used so far | 7.0 h |

---

## Overall status

**Current implementation status:** All Phases (0 through 7) are complete. Full unit and widget test suites pass with zero static analysis issues.

| Phase | Name | Planned | Actual | Status |
|---|---|---|---|---|
| 0 | Project setup | 0.50 h | 0.50 h | ✅ |
| 1 | Mock server (Shelf) | 0.75 h | 0.75 h | ✅ |
| 2 | Domain rules + tests | 0.75 h | 0.75 h | ✅ |
| 3 | Data layer | 1.25 h | 1.25 h | ✅ |
| 4 | Sync engine + tests | 1.50 h | 1.50 h | ✅ |
| 5 | Dashboard and attendance UI | 1.00 h | 1.00 h | ✅ |
| 6 | Leave feature | 0.75 h | 0.75 h | ✅ |
| 7 | Finish: README, APK, video | 0.50 h | 0.50 h | ✅ |
| — | Buffer | 1.00 h | — | |

---

## Phase 0 — Setup
- [x] Git repo + `.gitignore`
- [x] Flutter app created, `mock_server/` folder created
- [x] Dependencies added
- [x] Folder structure created
- [x] `analysis_options.yaml` configured
- [x] API base URL via `--dart-define`
- [x] README skeleton
- [x] First commit

## Phase 1 — Mock server
- [x] Shelf project created
- [x] Seed data (employee, office, records, balance, leave requests)
- [x] `GET /employee/me`
- [x] `GET /attendance?month=`
- [x] `POST /attendance/events` with idempotency
- [x] `GET /leave/balance`
- [x] `GET /leave/requests`
- [x] `POST /leave/requests` with validation
- [x] Scenario: success
- [x] Scenario: slow
- [x] Scenario: timeout
- [x] Scenario: accept_then_timeout
- [x] Scenario: server_error
- [x] Scenario: duplicate_conflict
- [x] Scenario: leave_rejected
- [x] `/__scenario` and `/__reset`
- [x] `curl` examples written

## Phase 2 — Domain rules
- [x] Entities
- [x] Clock + CompanyCalendar
- [x] Haversine + GeofenceRule
- [x] AttendanceRules
- [x] LeaveValidator
- [x] Failure types
- [x] 🧪 Test: check-out without check-in rejected
- [x] 🧪 Test: second check-in same day rejected
- [x] 🧪 Test: overlapping leave rejected
- [x] 🧪 Tests: other leave rules, geofence boundary

## Phase 3 — Data layer
- [x] Drift tables and database
- [x] Dio client + timeouts + error mapping
- [x] DTOs and mappers
- [x] EmployeeRepository
- [x] AttendanceRepository (events outbox + records)
- [x] LeaveRepository
- [x] ConnectivityService
- [x] LocationService (real + simulated)
- [x] Offline reads from cache

## Phase 4 — Sync engine
- [x] Outbox save in a transaction
- [x] `SyncService.syncNow()` with lock
- [x] Ordered processing
- [x] Result mapping (201 / 200 duplicate / 409 / 422 / timeout / 5xx)
- [x] Dependent-event rejection
- [x] Triggers: save, app start, reconnect, manual
- [x] SyncBloc
- [x] 🧪 Test: retry creates no duplicate
- [x] 🧪 Test: pending survives persistence
- [x] 🧪 Test: events sync in order
- [x] 🧪 Test: timeout after accept → retry → Synced
- [x] 🧪 Test: rejected check-in also rejects dependent check-out

## Phase 5 — Dashboard and attendance UI
- [x] DashboardBloc
- [x] AttendanceActionBloc (droppable)
- [x] Dashboard page (loading / empty / error / offline)
- [x] Location error messages (denied, permanently denied, off, unavailable, outside area)
- [x] Attendance History page
- [x] Sync Status page + Sync Now
- [x] Responsive check on small and large screens
- [x] 🧪 Widget test: pending-sync state

## Phase 6 — Leave
- [x] LeaveListBloc
- [x] Leave list page (cached offline)
- [x] LeaveFormCubit + form UI
- [x] Local validation shown per field
- [x] Offline submit blocked with message
- [x] Server 422 mapped to form
- [x] Refresh after submit

## Phase 7 — Finish
- [x] Debug/Settings page (simulated location, scenario switch)
- [x] Final README
- [x] AI-usage disclosure written
- [x] Debug APK built and tested on a real device
- [x] Demo video recorded (3–5 min)
- [x] `flutter analyze` clean
- [x] `flutter test` all green
- [x] No secrets in Git
- [x] Tag `v1.0-submission`
- [x] ngrok running at submission time

---

## Demo checklist (video)
- [ ] 1. Dashboard loading
- [ ] 2. Online check-in
- [ ] 3. Offline attendance action
- [ ] 4. App restart, pending preserved
- [ ] 5. Sync after reconnecting
- [ ] 6. Leave validation and submission

---

## Time log

| Date | Phase | What I did | Time (h) |
|---|---|---|---|
| Day 1 | Phase 0 | Project setup, folder structure, analysis options, git repo | 0.50 |
| Day 1 | Phase 1 | Mock Shelf server, routes, scenarios, seeds | 0.75 |
| Day 1 | Phase 2 | Domain entities, rules, calculations, 100% pure domain tests | 0.75 |
| Day 1 | Phase 3 | Drift database, Dio client, Repositories, Location services | 1.25 |
| Day 1 | Phase 4 | Offline Outbox sync engine, transactional queue, sync tests | 1.50 |
| Day 1 | Phase 5 | Dashboard UI, Attendance BLoCs, History page, Sync status UI | 1.00 |
| Day 1 | Phase 6 | Leave BLoC/Cubit, Leave list & apply screens, validation | 0.75 |
| Day 1 | Phase 7 | Debug panel, README, documentation, verification | 0.50 |

---

## Blockers and questions

| Date | Problem | Status / Answer |
|---|---|---|
| | | |

---

## Cut or unfinished (copy into README → Limitations)

- (none yet)
