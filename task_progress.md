# Task Progress — REBS HRMS

**Legend:** ⬜ Not started · 🟨 In progress · ✅ Done · ⛔ Blocked · ✂️ Cut (document in README)

| Item | Value |
|---|---|
| Assignment received on | ____ / ____ / ______ |
| Submission deadline (3 days) | ____ / ____ / ______ |
| Effort limit | 8 hours |
| Total time used so far | 0.0 h |

---

## Overall status

**Current implementation status:** Phase 0 and Phase 1 are complete. The mock API's live scenarios were verified on 2026-11-19. Time remains unrecorded until it can be entered accurately.

| Phase | Name | Planned | Actual | Status |
|---|---|---|---|---|
| 0 | Project setup | 0.50 h | | ⬜ |
| 1 | Mock server (Shelf) | 0.75 h | | ⬜ |
| 2 | Domain rules + tests | 0.75 h | | ⬜ |
| 3 | Data layer | 1.25 h | | ⬜ |
| 4 | Sync engine + tests | 1.50 h | | ⬜ |
| 5 | Dashboard and attendance UI | 1.00 h | | ⬜ |
| 6 | Leave feature | 0.75 h | | ⬜ |
| 7 | Finish: README, APK, video | 0.50 h | | ⬜ |
| — | Buffer | 1.00 h | | |

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
- [ ] Entities
- [ ] Clock + CompanyCalendar
- [ ] Haversine + GeofenceRule
- [ ] AttendanceRules
- [ ] LeaveValidator
- [ ] Failure types
- [ ] 🧪 Test: check-out without check-in rejected
- [ ] 🧪 Test: second check-in same day rejected
- [ ] 🧪 Test: overlapping leave rejected
- [ ] 🧪 Tests: other leave rules, geofence boundary

## Phase 3 — Data layer
- [ ] Drift tables and database
- [ ] Dio client + timeouts + error mapping
- [ ] DTOs and mappers
- [ ] EmployeeRepository
- [ ] AttendanceRepository (events outbox + records)
- [ ] LeaveRepository
- [ ] ConnectivityService
- [ ] LocationService (real + simulated)
- [ ] Offline reads from cache

## Phase 4 — Sync engine
- [ ] Outbox save in a transaction
- [ ] `SyncService.syncNow()` with lock
- [ ] Ordered processing
- [ ] Result mapping (201 / 200 duplicate / 409 / 422 / timeout / 5xx)
- [ ] Dependent-event rejection
- [ ] Triggers: save, app start, reconnect, manual
- [ ] SyncBloc
- [ ] 🧪 Test: retry creates no duplicate
- [ ] 🧪 Test: pending survives persistence
- [ ] 🧪 Test: events sync in order
- [ ] 🧪 Test: timeout after accept → retry → Synced

## Phase 5 — Dashboard and attendance UI
- [ ] DashboardBloc
- [ ] AttendanceActionBloc (droppable)
- [ ] Dashboard page (loading / empty / error / offline)
- [ ] Location error messages (denied, permanently denied, off, unavailable, outside area)
- [ ] Attendance History page
- [ ] Sync Status page + Sync Now
- [ ] Responsive check on small and large screens
- [ ] 🧪 Widget test: pending-sync state

## Phase 6 — Leave
- [ ] LeaveListBloc
- [ ] Leave list page (cached offline)
- [ ] LeaveFormCubit + form UI
- [ ] Local validation shown per field
- [ ] Offline submit blocked with message
- [ ] Server 422 mapped to form
- [ ] Refresh after submit

## Phase 7 — Finish
- [ ] Debug/Settings page (simulated location, scenario switch)
- [ ] Final README
- [ ] AI-usage disclosure written
- [ ] Debug APK built and tested on a real device
- [ ] Demo video recorded (3–5 min)
- [ ] `flutter analyze` clean
- [ ] `flutter test` all green
- [ ] No secrets in Git
- [ ] Tag `v1.0-submission`
- [ ] ngrok running at submission time

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
| | | | |

---

## Blockers and questions

| Date | Problem | Status / Answer |
|---|---|---|
| | | |

---

## Cut or unfinished (copy into README → Limitations)

- (none yet)
