# Coding Laws and Architecture

These are the rules for this project. If a rule must be broken, write the reason in `decisions.md`.

---

## Part 1 — Architecture

### 1.1 The three layers

```
┌─────────────────────────────────────────────┐
│ PRESENTATION   pages, widgets, BLoCs        │  "What the user sees and taps"
├─────────────────────────────────────────────┤
│ DOMAIN         entities, rules, repository  │  "The business, in plain Dart"
│                interfaces, failures         │
├─────────────────────────────────────────────┤
│ DATA           Drift DB, Dio API, DTOs,     │  "Where data comes from"
│                repository implementations   │
└─────────────────────────────────────────────┘
```

**Dependency rule (the most important one):**

```
Presentation  →  Domain  ←  Data
```

- Presentation and Data both depend on Domain.
- **Domain depends on nothing** (no Flutter, no Drift, no Dio).
- Presentation never imports Drift or Dio.
- Data never imports Flutter widgets.

**Why:** The rules are the valuable part of this app. Keeping them in plain Dart means they are quick to test, and changing the database or API does not touch them.

### 1.2 Folder structure

```
rebs_hrms/
├─ lib/
│  ├─ main.dart                  # composition root: creates and wires everything
│  ├─ app.dart                   # MaterialApp, theme, routes
│  ├─ core/
│  │  ├─ config/                 # AppConfig (API base URL, timeouts, defaults)
│  │  ├─ time/                   # Clock, CompanyCalendar
│  │  ├─ geo/                    # DistanceCalculator (Haversine)
│  │  ├─ failure/                # Failure sealed classes
│  │  ├─ network/                # Dio factory, ConnectivityService
│  │  └─ ui/                     # shared widgets, theme, spacing
│  ├─ features/
│  │  ├─ employee/
│  │  │  ├─ domain/ data/ presentation/
│  │  ├─ attendance/
│  │  │  ├─ domain/              # entities, AttendanceRules, GeofenceRule, repository interface
│  │  │  ├─ data/                # drift tables/DAOs, DTOs, repository impl, location services
│  │  │  └─ presentation/        # bloc/, pages/, widgets/
│  │  ├─ sync/
│  │  │  ├─ domain/              # SyncService (engine), SyncResult
│  │  │  ├─ data/
│  │  │  └─ presentation/        # SyncBloc, SyncStatusPage
│  │  ├─ leave/
│  │  │  ├─ domain/              # LeaveValidator, entities
│  │  │  ├─ data/
│  │  │  └─ presentation/
│  │  └─ debug/                  # debug panel
│  └─ database/                  # AppDatabase (Drift), tables shared by features
├─ test/
│  ├─ core/ · features/...       # mirrors lib/
├─ mock_server/
│  ├─ bin/server.dart
│  ├─ lib/ (handlers, scenarios, store)
│  └─ pubspec.yaml
├─ README.md · decisions.md · logic.md
├─ phase_plan.md · task_progress.md
└─ coding_laws_and_architecture.md
```

**Why feature-first:** Everything about "attendance" is in one place. It is easier to find, change and delete.

### 1.3 State management (BLoC)

| Bloc / Cubit | Owns | Notes |
|---|---|---|
| `DashboardBloc` | Dashboard load/refresh | Events: `Started`, `RefreshRequested` |
| `AttendanceActionBloc` | Check-in/out taps | `droppable()` transformer so extra taps are ignored |
| `SyncBloc` | Sync state, pending count | Listens to connectivity and to the outbox stream |
| `AttendanceHistoryBloc` | History by month | |
| `LeaveListBloc` | Leave requests list and balance | |
| `LeaveFormCubit` | Form fields, errors, submit | Simple state, so Cubit is enough |

**BLoC rules**
- A bloc depends on **repositories and domain services only**, never on Dio or Drift directly.
- States are **immutable** and use `Equatable`. Use sealed classes or a status enum plus data.
- A bloc never holds `BuildContext`. UI messages travel as state (or a one-time `effect` field), not as `ScaffoldMessenger` calls in the bloc.
- One bloc per responsibility. Do not create a "god bloc".

### 1.4 Data flow for one tap (check-in)

```
Button tap
  → AttendanceActionBloc (droppable)
    → AttendanceRules + LocationService + GeofenceRule   (domain)
    → AttendanceRepository.saveEvent()  [Drift transaction] (data)
    → SyncService.syncNow()
        → AttendanceApi.postEvent()  [Dio]
        → mark Synced / Rejected / keep Pending
  → state emitted → UI updates
```

### 1.5 Error handling

- Repositories and services return a **`Result<T>`** (sealed `Success` / `Failure`) for expected problems. No throwing for expected cases such as "outside the area".
- Raw exceptions (`DioException`, `SqliteException`) are **caught in the data layer** and converted to `Failure` types.
- Every `Failure` has a **user-friendly message**. Technical details go to logs only.
- Failure families: `LocationFailure`, `RuleFailure`, `NetworkFailure`, `ServerFailure`, `ValidationFailure`, `StorageFailure`.

### 1.6 Testing strategy

| What | How | Why |
|---|---|---|
| Domain rules | Plain unit tests | Fast, most valuable |
| Repositories and sync | Unit tests with **in-memory Drift** and a fake API | Real database behaviour, no device needed |
| Blocs | `bloc_test` + `mocktail` | Checks state sequences |
| Widgets | One focused widget test (pending-sync state) | Required by the assignment |

Required tests (from the assignment) → file names:
1. `attendance_rules_test.dart`: check-out without check-in is rejected.
2. `sync_service_test.dart`: retry does not create a duplicate.
3. `sync_service_test.dart`: pending events survive persistence and sync in order.
4. `leave_validator_test.dart`: overlapping dates are rejected.
5. `sync_status_page_test.dart`: widget test for the pending-sync state.

---

## Part 2 — Coding Laws

### A. Dart and Flutter

1. **Null safety, always.** No `!` unless you can write a comment explaining why it is safe. Prefer `?`, `??` and early returns.
2. **No business logic in `build()`.** `build()` only describes the UI from the state it is given.
3. **Widgets are small.** If a `build` method is longer than about 60 lines, split it into smaller widgets (classes, not helper methods that return widgets).
4. **Use `const`** wherever possible.
5. **Never use `BuildContext` across an `await`** without checking `context.mounted`.
6. **Use package imports** (`package:rebs_hrms/...`), not long relative paths.
7. **No `print`.** Use a small logger wrapper.
8. **Dispose** controllers, streams and subscriptions.
9. **Responsive by default:** no fixed pixel heights for text containers, use `Flexible`, `Expanded`, `LayoutBuilder`, scrollable bodies.
10. **No magic numbers or strings.** Radius (200), timeouts, and URLs live in `AppConfig`.

### B. Architecture

11. **Domain stays pure.** If you are about to import `flutter`, `drift` or `dio` in a domain file, stop.
12. **Time goes through `Clock`.** Never call `DateTime.now()` outside the `Clock` implementation.
13. **Store time in UTC;** convert to company time only for display and for the "company date".
14. **Repositories hide the source.** A bloc does not know if data came from the cache or the network, except through an explicit `isFromCache` flag.
15. **One place for each rule.** For example, the 200 m rule exists only in `GeofenceRule`.
16. **Events are never edited after creation** except for status, attempts and error fields. The `clientEventId` never changes.
17. **Writes that must be consistent use a transaction.**

### C. Naming and style

18. Files: `snake_case.dart`. Classes: `PascalCase`. Variables and methods: `camelCase`.
19. Names say what it is: `AttendanceEventStatus.pending`, not `status1`.
20. Booleans read like questions: `isOffline`, `hasPendingEvents`, `canCheckIn`.
21. Comments explain **why**, not what. The code already shows what.
22. Keep functions short and focused (aim for under 30 lines).

### D. Dependencies

23. Each new package needs a one-line reason in `decisions.md` or the README. If the Flutter SDK or Dart can do it, do not add a package.
24. Pin versions with `^` and commit `pubspec.lock`.

### E. Security and secrets

25. **No secrets in Git:** no ngrok token, no keys, no real credentials. The API URL comes from `--dart-define`.
26. Add anything sensitive to `.gitignore` before the first commit.
27. Do not log full coordinates or tokens in release builds.

### F. Git and GitHub

28. **Small, focused commits.** One idea per commit.
29. **Commit message format:** `type(scope): short message`
    - Types: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`.
    - Example: `feat(sync): preserve event order when syncing`
30. **Branches:** work on `feature/<phase>-<name>` and merge into `main` after the phase's "Done when" is met. (If this feels heavy for a solo 8-hour task, at least commit per phase on `main`.)
31. **Never commit** build outputs, `.dart_tool/`, IDE files, or `.env`.
32. **Never commit broken code** to `main`: `flutter analyze` and `flutter test` must pass first.
33. Tag the final submission: `v1.0-submission`.
34. Keep the README honest: document what is not finished.

### G. Definition of done (for every task)

A task is done only when:
- [ ] It works on the emulator.
- [ ] It has a test if it contains a business rule.
- [ ] `flutter analyze` shows no issues.
- [ ] Loading, error, empty and offline states are handled where they apply.
- [ ] It is committed with a clear message.
- [ ] `task_progress.md` is updated.

---

## Part 3 — Mock server rules (Dart Shelf)

1. The mock server is **not** part of the app and shares no code with the app's UI.
2. State is **in memory**. `POST /__reset` returns the seed data.
3. Every scenario is **switchable at runtime** and **repeatable**.
4. It must act like a strict server: it validates order, once per day, distance, and idempotency. This proves the client handles real rejections.
5. The scenario endpoints (`/__scenario`, `/__reset`) are only for testing and are documented as such.
