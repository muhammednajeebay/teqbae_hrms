# Logic Guide — Screen by Screen

Written in simple words. For each screen: **what it does**, **the logic step by step**, and **why** it is done this way.

---

## Quick glossary

| Word | Simple meaning |
|---|---|
| **Event** | One tap on Check-in or Check-out, saved as a record. |
| **Outbox** | A local list of events waiting to be sent to the server. |
| **Pending** | Saved on the phone, not yet confirmed by the server. |
| **Synced** | The server confirmed it. |
| **Rejected** | The server said no (for example, already checked in). |
| **Idempotent** | Sending the same thing twice has the same result as sending it once. |
| **Company date** | "Today" in the company's timezone, not the phone's timezone. |

---

## 0. Background logic (no screen): the Sync Engine

Every screen depends on this, so read it first.

**What it does:** Sends pending events to the server, in order, without creating duplicates.

**Logic**
1. Every check-in/check-out is saved on the phone first as **Pending**, with a unique ID (UUID) created at the moment of the tap.
2. The sync engine takes pending events, oldest first.
3. It sends **one event at a time** and waits for the answer.
4. Based on the answer:
   - Server says "created" → mark **Synced**.
   - Server says "I already have this ID" → mark **Synced** (it is the same event, a retry).
   - Server says "business rule broken" (already checked in, invalid order) → mark **Rejected**, save the reason.
   - No internet / timeout / server error → leave it **Pending**, **stop**, try again later.
5. If an event is Rejected, later events that depend on it (a check-out after a rejected check-in) are also marked Rejected with the reason "depends on a rejected event".
6. Only one sync can run at a time.
7. It starts when: an event is saved, the app opens, internet returns, or the user presses **Sync Now**.

**Why**
- *Save first, send second:* The user never loses an action because of a bad network. One path for online and offline means fewer bugs.
- *Same ID on every retry:* If a timeout happens, we do not know whether the server received it. Sending the same ID makes the retry safe.
- *One at a time, oldest first:* A check-out must not arrive before its check-in.
- *Stop on network errors:* If event 1 failed because of no internet, event 2 will fail too, and sending it first would break the order.
- *Duplicate ID = Synced:* The goal was "the server has this event". It does.

---

## 1. Dashboard screen

**What it shows:** Name, ID, department · today's status · check-in time, check-out time, elapsed time · leave balance · last 5 attendance records · Check-in / Check-out button · offline banner · pending-sync badge.

**Screen states**
| State | When | What the user sees |
|---|---|---|
| Loading | First load, nothing cached | Skeleton or spinner |
| Loaded | Data available | Full dashboard |
| Loaded (offline/cache) | No internet but cache exists | Dashboard + banner "Offline. Showing saved data. Last updated 10:42" |
| Empty | No attendance records yet | Cards show data; history says "No attendance yet" with a friendly message |
| Error | No internet **and** no cache, or server error | Message + Retry button |

**Logic**
1. On open, load the **cache first** and show it immediately.
2. In the background, ask the server for fresh data. If it works, save to cache and update the screen.
3. If the network fails and a cache exists, keep the cache and show the offline banner.
4. If the network fails and nothing is cached, show the Error state.
5. **Today's status** is worked out from the server record for today **plus** local events that are not Rejected:
   - has a check-out → *Checked Out*
   - else has a check-in → *Checked In*
   - else → *Not Checked In*
6. **Elapsed time:** if Checked In, `now − checkInTime`. If Checked Out, `checkOutTime − checkInTime`. Otherwise show "--". While Checked In, it refreshes once per minute.
7. Show the pending count badge. Tapping it opens the Sync Status screen.

**Why**
- *Cache first:* The screen opens instantly and works offline.
- *Merge local events:* If the user checked in offline, the dashboard must say "Checked In", otherwise the user will tap again and get confused.
- *Company date, not phone date:* A phone in the wrong timezone must not change what "today" means.
- *Clock is injected:* Tests can set a fixed "now", so duration logic is testable.

**Edge cases**
- Cache is old → show "Last updated" time so the user is not misled.
- App left open past midnight (company time) → the "today" status resets on the next refresh.

---

## 2. Check-in / Check-out action (on the Dashboard)

**What it does:** Records attendance only when all rules pass.

**Logic (check-in), in this order**
1. Ignore the tap if an action is already running (**droppable** event handling).
2. Check the **rules** using the local state:
   - Already checked in today? → stop with "You already checked in today."
3. Ask for **location permission** and read the current location:
   - Denied → message + "Allow" button.
   - Permanently denied → message + "Open Settings" button.
   - Location services off → message + "Turn on location".
   - Cannot get a position (timeout) → "Could not find your location. Try again."
4. Calculate the distance to the office. More than **200 m** → stop with "You are 340 m away. You must be within 200 m of the office."
5. In **one database transaction**: re-check the rules, create the event (UUID, time in UTC, company date, latitude, longitude, accuracy), save it as **Pending**.
6. Tell the sync engine to run now.
7. Show the result: "Checked in at 09:02" and either "Synced" or "Saved, will sync when online".

**Check-out** follows the same steps, but rule 2 is: "Is there a check-in today? Is there no check-out yet?" If not → "You need to check in first."

**Why**
- *Rules before location:* Do the cheap check first. No need to wait for GPS if the action is not allowed anyway.
- *Re-check inside a transaction:* Two quick taps could both pass the check. The transaction closes that gap, so duplicates are impossible even if the UI guard fails.
- *Droppable taps:* The button is not the only protection, but it gives instant feedback.
- *Separate permission messages:* Each situation needs a different action from the user.
- *Store accuracy and the "mocked location" flag:* The server can use them for its own checks. We record them but do not block on them, so reviewers can simulate locations.

**Important note for the README:** These device checks are for a good user experience. The server must repeat them (see README → "What the server must repeat").

---

## 3. Attendance History screen

**What it shows:** Records for the month, newest first, each with date, check-in, check-out, total hours, and a sync chip when local events are involved.

**Logic**
1. Load the cached records for the selected month, then refresh from the server.
2. Local Pending events for that month are shown **on top of** the server records with a "Pending Sync" chip.
3. Month picker (previous/next). Only the loaded months are available offline; other months show "Not available offline."
4. Empty month → "No records for this month."

**Why**
- *Show pending items here too:* The user should see their own action immediately, not only after sync.
- *Be honest about offline limits:* We cached only what was loaded. Saying so is better than showing a wrong empty list.

---

## 4. Sync Status screen

**What it shows:** All local events with status chips, a **Sync Now** button, last sync time and error text.

| Chip | Meaning | Extra |
|---|---|---|
| Pending Sync (orange) | Waiting to be sent | Shows attempts count |
| Synced (green) | Server confirmed | |
| Rejected (red) | Server refused | Shows the reason |

**Logic**
1. Read all events from the local database (a stream, so the list updates live).
2. **Sync Now** is disabled while a sync is running or while offline, and shows a spinner when running.
3. When sync ends, show a small message: "2 synced, 1 rejected" or "Could not reach the server. Will retry."
4. Rejected items stay visible, so the user knows why they failed. They are not retried automatically.

**Why**
- *Users need to see what happened:* This screen is also the reviewer's best way to confirm the sync logic works.
- *Manual button:* The assignment requires it, and users trust a visible control.
- *No automatic retry of Rejected:* A business "no" will not change by itself. Retrying only wastes requests.

---

## 5. Leave Requests screen

**What it shows:** The list of leave requests with Pending / Approved / Rejected chips, plus the balance and an "Apply" button.

**Logic**
1. Show cached requests and balance first, then refresh.
2. Offline: show the cached list with an offline banner. The "Apply" button stays visible but shows "You need internet to apply" when tapped.
3. Empty list → "No leave requests yet."

**Why**
- *Apply needs internet:* The assignment says so. The server owns the balance and overlap checks, so allowing offline submissions would cause many conflicts later.
- *Cached list:* The assignment requires old requests to stay viewable.

---

## 6. Apply Leave screen (form)

**Fields:** Leave type (Casual/Sick), Start date, End date, Reason.

**Local validation (in the `LeaveValidator` class, not in the widget)**
1. Start date must **not be before today's company date**.
2. End date must **not be before the start date**.
3. Reason must have **at least 10 non-whitespace characters** ("          hi" is not enough).
4. Requested days must **not exceed the balance**. Days are counted **inclusive**: 1 Jan to 3 Jan = 3 days.
5. Dates must **not overlap** a Pending or Approved request.
   Overlap formula: `newStart <= existingEnd && newEnd >= existingStart`.
   Rejected requests are ignored.

**Submit logic**
1. Validate locally. If anything fails, show the error under that field and do not call the server.
2. If offline, show "You need internet to submit."
3. Disable the button while submitting (prevents double submit).
4. Send to the server.
   - Success → show a message, refresh list and balance, go back.
   - Server validation error (422) → map to the matching field, or show a general error at the top.
   - Network or server error → "Could not submit. Please try again." The form keeps the user's input.

**Why**
- *Validator is a pure class:* Easy to unit test. Widgets only show what it returns.
- *Inclusive days and trimmed reason:* Exactly what the assignment's rules say.
- *Still handle server errors:* Local data can be old. Another device may have created a request already, so the server has the final say.
- *Keep user input on failure:* Nobody wants to retype a reason.

---

## 7. Debug / Settings screen

**What it does:** Helps reviewers (and you) test.

**Contains**
- Current API base URL (read-only, set at build time).
- **Simulated location** switch with presets: "At office", "500 m away", "Location unavailable".
- Current mock scenario (reads `GET /__scenario`) and buttons to change it (only works if the mock server is reachable).
- "Sync Now".

**Logic**
1. When "Simulated location" is on, the app uses `SimulatedLocationService` instead of the real GPS.
2. All other logic is the same. Only the source of coordinates changes.

**Why**
- *Reviewers cannot always move to your office coordinates.* The assignment asks for a documented way to simulate location.
- *Same code path:* Because only the location source is swapped, what they test is what real users get.
- *Clearly marked debug:* In a production build, this screen would be hidden.

---

## Summary: how each screen protects the user

| Risk | Where it is handled |
|---|---|
| Double tap | Droppable bloc event + transaction re-check |
| Wrong order | Sync engine processes by sequence, stops on failure |
| Duplicate on retry | Same `clientEventId`, server is idempotent |
| Lost data on app close | Events saved in Drift before anything else |
| Stale data shown as fresh | Offline banner + "Last updated" time |
| Wrong "today" | Company timezone calendar |
| Bad location | Separate messages for each problem + distance shown |
