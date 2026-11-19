# Decisions Log — What We Decided and Why

Simple English. Each decision has: **Decision**, **Why**, **Other options**, **Trade-off**.
If you change a decision later, do not delete the old one. Add a note with the date and the new reason.

---

## D1. State management: BLoC (with `flutter_bloc`)

- **Decision:** Use BLoC for screens with several actions, and Cubit for simple forms.
- **Why:** BLoC makes every action an explicit event, so it is easy to trace and test ("tap → event → state"). It also has event transformers, which solve the double-tap problem cleanly (`droppable()`).
- **Other options:** Riverpod, Provider, setState.
- **Trade-off:** More files and boilerplate than Cubit-only or Riverpod. We accept it for traceability and testability.

## D2. Local storage: Drift (SQLite)

- **Decision:** Store cached data and the pending-events queue in Drift.
- **Why:** The pending queue must be **ordered**, survive restarts, and change status safely. SQL handles ordering and transactions well. Drift adds type safety and an in-memory mode for tests.
- **Other options:** Hive, Isar, sqflite, shared_preferences.
- **Trade-off:** Needs code generation (`build_runner`) and has a small learning curve. Worth it because sync is the main challenge.

## D3. Mock server: Dart Shelf

- **Decision:** Write the mock API in Dart with `shelf` and `shelf_router`, inside `mock_server/`.
- **Why:** It is the language we already know, so we can explain and change every line. Reviewers who have Flutter already have Dart installed. It lets us program real behaviour (idempotency, delays, conflicts).
- **Other options:** Node + Express, json-server.
- **Trade-off:** Fewer online examples than Express. The in-memory data resets when the server restarts.

## D4. HTTP client: Dio

- **Decision:** Use Dio.
- **Why:** Easy timeouts, interceptors and clear error types. We need a clean way to tell "timeout" apart from "server said no".
- **Other options:** `http` package.
- **Trade-off:** One more dependency than `http`, but it saves custom code.

## D5. Outbox pattern: save locally first, then sync

- **Decision:** Every check-in/out is saved as a Pending event first. A sync engine sends it afterwards. Online and offline use the same path.
- **Why:** The user never loses an action. One code path means fewer bugs than "if online do A, else do B".
- **Other options:** Try the network first, and queue only when it fails.
- **Trade-off:** Even online actions go through local storage first. It adds a small step, but behaviour is consistent.

## D6. Event identity: a UUID created on the device at tap time

- **Decision:** Each event gets a `clientEventId` (UUID v4) when the user taps. It never changes, even across retries and app restarts.
- **Why:** This is how the server recognises a retry. Without a stable ID, the server cannot tell a retry from a new event.
- **Other options:** Use `employeeId + date + type` as the key, or let the server generate the ID.
- **Trade-off:** `employeeId + date + type` would also block real duplicates, but it mixes up "same event retried" with "different event, same day". The UUID separates them clearly. We still keep the business rule "once per day" as a second check.

## D7. How the server answers events (idempotency contract)

- **Decision:**
  | Case | Server response | Client action |
  |---|---|---|
  | New valid event | `201 Created` | Synced |
  | Same `clientEventId` again | `200 OK` with `duplicate: true` | Synced |
  | Different event, but that type already exists today | `409 ALREADY_EXISTS` | Rejected |
  | Invalid order (check-out without check-in) | `422 INVALID_ORDER` | Rejected |
  | Outside the allowed distance | `422 OUTSIDE_RADIUS` | Rejected |
  | Timeout, no network, 5xx | none / error | Stay Pending, retry |
- **Why:** The client must tell "this is the same event I already sent" (good) from "someone else already used the slot" (conflict).
- **Trade-off:** The assignment says we may adjust the API contract if we document it. This is that documentation.

## D7b. A timeout is not a failure

- **Decision:** On timeout, the event stays Pending and is retried with the same ID.
- **Why:** On a timeout we do not know whether the server saved it. Marking it failed or creating a new event would risk a duplicate or a lost record. With the same ID, the retry is safe either way.

## D8. Sync order: oldest first, one at a time, stop on network errors

- **Decision:** Process events by local `sequence`. Wait for each result. If the failure is a network or server error, stop the loop.
- **Why:** A check-out must not reach the server before its check-in. If event 1 fails from a lost connection, sending event 2 would break the order.
- **Trade-off:** One slow event delays the ones behind it. With at most a few events per day, this is fine.

## D9. When an event is Rejected, later dependent events are also Rejected

- **Decision:** If a check-in is rejected, a later check-out waiting behind it is marked Rejected with the reason "depends on a rejected event".
- **Why:** A check-out without a valid check-in can never succeed. Leaving it Pending would retry forever.
- **Other options:** Keep it Pending until the user acts.
- **Trade-off:** This is my assumption. Document it in the README as a decision made for the assignment.

## D10. One sync at a time (lock)

- **Decision:** `SyncService` refuses to start a second sync while one is running.
- **Why:** Triggers can overlap (app start + reconnect + button). Two syncs at once could send the same event twice at the same time.

## D11. Company timezone decides "today"

- **Decision:** "Today" and "working day" use the configurable company timezone (from the server config with a local default), not the phone's timezone.
- **Why:** The assignment says to use a configurable company timezone. A traveler's phone or a wrong phone setting must not change the working day.
- **Trade-off:** Needs the `timezone` package for correct conversions. It is worth it for correctness.

## D12. Store times in UTC; show in company time

- **Decision:** `occurredAt` is saved in UTC. The `companyDate` is calculated and saved with each event.
- **Why:** UTC has no daylight-saving problems. Saving the company date avoids recalculating it with a different timezone later.

## D13. Time comes from a `Clock` class

- **Decision:** No direct `DateTime.now()` in the logic. Use an injected `Clock`.
- **Why:** Tests can set "now" to any value, so "once per day", elapsed time and leave dates can be tested.

## D14. Business rules are plain Dart classes in the domain layer

- **Decision:** `AttendanceRules`, `GeofenceRule`, `LeaveValidator` have no Flutter, Drift or Dio imports.
- **Why:** Fast tests. One place for each rule. The UI cannot accidentally change a rule.

## D15. Distance: our own Haversine formula

- **Decision:** Calculate distance in a small pure Dart class.
- **Why:** Easy to unit test with known coordinates, and it removes the need for a platform call in tests.
- **Other options:** `Geolocator.distanceBetween`.
- **Trade-off:** A few more lines of code, but testable without a device.

## D16. Double-tap protection in three layers

- **Decision:** (1) Disable the button while running, (2) `droppable()` on the bloc event, (3) re-check the rules inside a database transaction before saving.
- **Why:** The UI can fail (slow frame, two fast taps). The database check is the final guarantee.

## D17. Location: do not block on "mocked location", only record it

- **Decision:** Save `isMockedLocation` on the event, but do not block the action.
- **Why:** Reviewers must be able to simulate locations. Blocking would break their testing. The server should use this flag in production.
- **Trade-off:** Fake GPS is possible from the client. That is why the server must repeat the checks. We say so in the README.

## D18. Simulated location through a debug panel

- **Decision:** `LocationService` is an interface. A `SimulatedLocationService` is used when the debug switch is on. Presets: "At office", "500 m away", "Unavailable".
- **Why:** The assignment asks for a documented way to simulate locations. It is faster and clearer than relying on emulator GPS tools alone. Emulator tools are also documented as an alternative.

## D19. Offline dashboard: cache first, then refresh

- **Decision:** Show the cached data immediately and refresh in the background. Display "Last updated" and an offline banner.
- **Why:** Fast opening, and honest about how old the data is.

## D20. Today's status = server record + local events that are not Rejected

- **Decision:** Combine them to compute Not Checked In / Checked In / Checked Out.
- **Why:** If the user checked in offline, the dashboard must reflect it immediately, or the user will tap again.

## D21. Leave submission needs internet

- **Decision:** No offline queue for leave. The submit button explains why when offline. The list and balance are cached.
- **Why:** The assignment says so. The server owns the balance and overlap checks.
- **Trade-off:** Less convenient offline, but it avoids a second sync system and many conflicts.

## D22. Leave day counting: inclusive calendar days

- **Decision:** `days = end − start + 1`. Weekends and holidays count.
- **Why:** The assignment says all calendar days count.

## D23. Leave overlap check ignores Rejected requests

- **Decision:** Overlap is checked against Pending and Approved only, with `newStart <= existingEnd && newEnd >= existingStart`.
- **Why:** It follows the assignment. A Rejected request does not occupy the dates.

## D24. Leave balance: treat the server's "available balance" as final

- **Decision:** Compare requested days with the available balance from the server. Do not subtract Pending requests a second time.
- **Why:** The assignment does not say whether the balance already accounts for Pending requests. The server is the source of truth, so the app trusts it.
- **Trade-off:** This is an **assumption**. If the real server doesn't reserve days for Pending requests, the server must reject the over-balance case (our client also handles that error).

## D25. Dependency injection by hand (composition root in `main.dart`)

- **Decision:** Create and pass objects through constructors. No `get_it`.
- **Why:** One less dependency, and the wiring is easy to read and explain in an interview.
- **Trade-off:** `main.dart` grows a little. Acceptable at this size.

## D26. Extra packages kept small and each justified

| Package | Why |
|---|---|
| `flutter_bloc`, `bloc_concurrency`, `equatable` | State management, droppable events, value equality |
| `drift`, `drift_flutter` / `sqlite3_flutter_libs`, `drift_dev`, `build_runner` | Local database |
| `dio` | HTTP client |
| `geolocator` | Location and permission handling (also provides settings shortcuts) |
| `connectivity_plus` | Detect when the network returns |
| `uuid` | Event IDs |
| `intl` | Date formatting |
| `timezone` | Correct company timezone conversion |
| Dev: `bloc_test`, `mocktail` | Testing |

## D27. Debug panel included in the app

- **Decision:** A small debug screen with simulated location and scenario switching.
- **Why:** Reviewers can test every case without editing code. In production it would be hidden.

## D28. Git workflow

- **Decision:** One commit per finished phase (at least), `type(scope): message`, final tag `v1.0-submission`.
- **Why:** Reviewers can read the history as a story of the work. It also shows good Git habits.

---

## Decisions still open (confirm before coding)

| # | Question | My suggestion |
|---|---|---|
| O1 | Should Rejected events have a "Dismiss" button? | Yes if time allows, otherwise list it as a limitation |
| O2 | Show the user a warning if GPS accuracy is poor (for example, above 100 m)? | Show a small warning only, do not block |
| O3 | Which months are cached for offline? | Current month + previous month |
| O4 | Is the 10-second Dio timeout right? | Yes, and the mock `timeout` scenario waits longer than that |
