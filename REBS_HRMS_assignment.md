# Flutter Developer Assignment: REBS HRMS

## Challenge: Build an Offline-Capable Employee Workspace

REBS is a business automation platform with HRMS, CRM, and Accounts modules.

Build a Flutter application that allows an employee to view their attendance, check in and out, and apply for leave. The app must remain usable when connectivity is unavailable and handle synchronization reliably.

**Target platform:** Android/iOS
**Effort limit:** 8 hours
**Submission deadline:** Within 3 days of receiving the assignment

Prioritize working core functionality and clear engineering decisions. Document unfinished features and trade-offs.

---

## 1. Employee Dashboard

Display:

- Employee name, ID, and department.
- Today's attendance status: Not Checked In, Checked In, or Checked Out.
- Check-in time, check-out time, and elapsed working duration.
- Available leave balance.
- The latest five attendance records.

Provide loading, empty, error, and offline states.

For this assignment, use one preconfigured employee. Login is outside the scope.

---

## 2. Attendance Check-In and Check-Out

Implement attendance with the following rules:

- An employee can check in once per working day.
- Check-out is permitted only after check-in.
- Repeated taps must not create duplicate attendance events.
- Capture the timestamp and current GPS coordinates.
- Permit attendance only within **200 metres** of the configured office location.
- Handle denied location permission, permanently denied permission, and unavailable location.
- Display a meaningful message when the employee is outside the permitted area.

Keep office coordinates configurable. Include a documented way for reviewers to simulate locations.

For simplicity, assume one attendance session per day, no overnight shifts, and a configurable company timezone.

**Important:** Device-side validation improves the user experience; explain which checks a production server must repeat.

---

## 3. Offline Storage and Synchronization

This is the main engineering challenge.

- Cache the dashboard and attendance history for offline viewing.
- Allow valid check-in and check-out actions to be saved locally when offline.
- Clearly distinguish Pending Sync, Synced, and Rejected events.
- Preserve pending events after the app closes and reopens.
- Provide a manual "Sync Now" action.
- Attempt synchronization when connectivity returns.
- Preserve check-in/check-out ordering.
- Handle a server response that rejects an event because attendance already exists.
- Handle a timeout where the server may have accepted the event before the client received a response.

Retries must not produce duplicate server records. Explain your approach to event identity and idempotency.

Background execution while the app is terminated is outside the scope.

---

## 4. Leave Application

Create a leave form containing:

- Leave type: Casual or Sick.
- Start date.
- End date.
- Reason.

Validation rules:

- Start date cannot be before the current company date.
- End date cannot be before the start date.
- Reason must contain at least 10 non-whitespace characters.
- Requested days cannot exceed the available balance.
- Dates cannot overlap an existing Pending or Approved request.

For this assignment, all calendar days count as leave days; ignore weekends and holidays.

Display the employee's leave requests with Pending, Approved, and Rejected statuses. Leave submission requires connectivity, but previously loaded requests must remain viewable offline.

The server must also validate submissions. Handle server validation errors even when local validation passes.

---

## 5. API Integration

Use a local mock HTTP API. No production REBS credentials or backend access is required.

Suggested endpoints:

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/employee/me` | Employee and office configuration |
| GET | `/attendance?month=YYYY-MM` | Attendance history |
| POST | `/attendance/events` | Submit a check-in or check-out event |
| GET | `/leave/balance` | Available leave balance |
| GET | `/leave/requests` | Existing leave requests |
| POST | `/leave/requests` | Submit a leave application |

You may adjust the contract if you document your reasoning.

Provide repeatable mock scenarios for:

1. Successful responses.
2. Slow responses and timeouts.
3. Server errors.
4. Duplicate attendance conflicts.
5. Leave validation rejection.

The Flutter app must use an HTTP client rather than returning hardcoded data directly from widgets.

---

## 6. Technical Expectations

- Use Flutter and Dart with null safety.
- Choose and justify your state management approach.
- Separate presentation, business rules, API access, and local persistence.
- Use persistent storage suitable for cached data and pending events.
- Avoid business logic inside widget build methods.
- Keep dependencies reasonable and explain significant choices.
- Make the interface usable on different Android screen sizes.
- Do not commit credentials or secrets.
- Visual polish matters, but correctness and reliability carry more weight.

---

## 7. Required Tests

Include meaningful automated tests covering at least:

1. Check-out without check-in is rejected.
2. Repeated submission or retry does not create duplicate attendance.
3. Pending attendance survives persistence and can be synchronized in order.
4. Overlapping leave dates are rejected.

Include one widget test covering a loading, error, or pending-sync state.

---

## 8. Deliverables

Submit:

- Git repository or source archive.
- Installable debug APK.
- Mock API and setup instructions.
- README covering architecture, setup, assumptions, completed features, limitations, and time spent.
- A short demonstration video, approximately 3–5 minutes.

The demonstration should show:

1. Dashboard loading.
2. Online check-in.
3. Offline attendance action.
4. App restart with the pending action preserved.
5. Synchronization after reconnecting.
6. Leave validation and submission.

**Note:** Disclose AI tools or generated code used. You must be able to explain and modify everything submitted.

**Please keep your ngrok running while submitting the report.**
