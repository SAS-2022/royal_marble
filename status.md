# Royal Marble — Project Status

Living tracker for this project, kept up to date across chat sessions.
**Read this first when resuming work; update it at the end of every session.**

_Last updated: 2026-10-01_

---

## 1. Overview

Workforce app for **Royal Marble** (marble/tiling contractor, Dubai). Workers' phones
track location; workers check in/out of assigned sites within a radius; admins and
supervisors see attendance, alerts and reports.

- **Client:** Royal Marble (Ihab Daou). **Developer:** Wisora Softwares LLC.
- **Contract:** one-time USD 1,500 — fix and redesign the app, plus an admin web
  version. Android release, iOS via TestFlight (2 users).
- **Branch:** all work is on `revive-2026`. `master` still holds the 2023 code.

### Roles (`users/{uid}.roles`)
| Key | Label | Home screen |
|---|---|---|
| `isAdmin` | Admin | Dashboard (stats, attendance, alerts, projects) |
| `isSupervisor` | Supervisor | Own sites + check-in + team roster |
| `isSales` | Sales | Visits shortcuts + projects |
| `isSiteEngineer` | Site Engineer | Same as worker |
| `isNormalUser` | **Mason** (worker) | Status banner + check-in cards |

### Stack
- Flutter 3.47 / Dart 3.13, Android Gradle 9.3 / AGP 9.1 / Kotlin 2.4 (Kotlin DSL)
- Firebase project `royal-marble` (Auth, Firestore, Storage, Functions)
- CLI deploys: `--project royal-marble --account royalmarble.uae@gmail.com`
- Background location: Transistorsoft `flutter_background_geolocation` 4.18 (paid
  licence in AndroidManifest; debug builds work without it)
- Run: `flutter run --dart-define-from-file=config/env.json` (VS Code launch config
  already does this). `config/env.json` and `android/local.properties` hold API keys
  and are git-ignored.

### Firestore collections
| Collection | Purpose |
|---|---|
| `users/{uid}` | Profile, roles, `isActive`, `assignedProject` (a map for masons, a list for supervisors), `assignedMockup`, `deviceStatus`, `currentLocation`, `distanceToProject` (distance from the site edge; ≤ 0 means inside) |
| `users/{uid}/location/current` | Latest raw background-location fix |
| `users/{uid}/clientVisits`, `/projectVisits` | Sales visit logs |
| `projects`, `mockup` | Sites (`selectedAddress` / `address` = `{addressName, Lat, Lng}`, `radius`, `assignedWorkers`) |
| `time_sheet/{d-m-yyyy}` | One doc per day, a map keyed by uid: `arriving_at`, `leaving_at` (local-time strings), `isOnSite`, `roles`, `projectId`, `workCompleted` |
| `device_events` | Phone status changes (location off, offline, silent, fake GPS…) |
| `clients`, `helper` | Sales clients; masons' helpers |

---

## 2. Done

- [x] Revived toolchain (Dart 3, current packages, Gradle 9); app builds and runs
- [x] Unified `TrackingService` (foreground and headless), device-status reporting and
      a transition log in `device_events`
- [x] Server-side `checkInOut` function (accuracy check, fake-GPS rejection, server
      timestamps) — **written, not deployed**
- [x] `detectSilentDevices` scheduled function — **written, not deployed**
- [x] Bug fixes: `role`/`roles` field mismatch, checkout crash, on-site
      miscalculation, team save error, endless loading for workers
- [x] New theme; redesigned home (all roles), sign-in, password reset, registration
      (3 steps), drawer, users list, user admin, site details and team management,
      team status and alerts, reports (attendance and sales, PDF/Excel)
- [x] Removed ~4k lines of dead code
- [x] **Interim Firestore rules deployed** (2026-10-01): location data needs sign-in,
      `testing` collection closed, `device_events` added
- [x] Strict role-based rules written in `firestore.strict.rules` (deploy after rollout)
- [x] API keys moved out of source

## 3. Blocked / waiting on the client

- [ ] **Firebase billing:** card expired → Cloud Functions can't deploy. Until
      `checkInOut` is deployed, check-in in the new app fails.
      Deploy: `firebase deploy --only functions,firestore:indexes ...`
- [ ] **Payment** under the contract (work paused until received)
- [ ] Rotate or restrict the Google Maps API keys (exposed in git history)
- [ ] A test mason account for end-to-end testing
- [ ] Decide: track masons 24/7 or only during working hours
- [ ] Possible duplicate accounts: "Nemichand Saini" ×2, "Rajender"/"Rajendr" Saini

---

## 4. Feature audit (requested 2026-10-01)

| # | Requirement | Current state |
|---|---|---|
| a | Workers check in/out **only at assigned sites** | ⚠️ Partly. The app only shows assigned sites, but the server function does **not** verify the assignment. |
| b | Timesheet per worker, **monitoring presence** on site | ⚠️ Partly. A daily entry records check-in/out. Presence *during* the day is not logged, and 63 of 93 mason-days in Nov 2023 had no check-out. |
| c | **Admin notified when a worker leaves** the site | ❌ Not built. Alerts exist for location off/offline/silent, but not for leaving the site, and nothing pushes to the admin's phone. |
| d | Worker on **several sites**, hours **per site** | ❌ Not supported. A mason holds one assignment, and a timesheet day holds one site per worker (a second check-in overwrites the site). |
| e | **Salary details** (basic, housing, transport, food…) | ❌ Not built. |
| f | Pay based on **worked hours**; no check-in/out → unpaid | ❌ Not built. Needs policy decisions (see Phase 6). |

---

## 5. Roadmap

### Phase 1 — Crashlytics instead of Sentry
- Remove `sentry_flutter`; add `firebase_crashlytics` and the Gradle plugin.
- One `ErrorReporter.record(error, stack)` helper replaces the 64 `Sentry.*` calls in
  `database.dart`, `auth.dart`, `tracking_service.dart`, `checkin_service.dart` and
  `show_map.dart`.
- Catch Flutter and async errors in `main.dart`; record user id and role as keys.
- Verify with a test crash in debug; check the Crashlytics console.
- Works on the free plan (no billing needed).

### Phase 2 — Attendance correctness (a, b)
- `checkInOut`: reject sites the worker isn't assigned to (projects and mock-ups).
- Presence log: a geofence for each assigned site; record enter/exit while checked in
  as `presence` events on the day's entry (time inside vs. outside).
- Missing check-outs: auto check-out at the last on-site time when the worker leaves
  the site area or at a set end of day, marked `autoCheckout: true` so admins can see it.
- Admin correction screen: fix or approve an entry, with an audit trail.
- Needs functions deployed (billing).

### Phase 3 — Multiple sites per worker, hours per site (d)
- Data model: masons get `assignments: [{id, kind, name, address, radius}]`
  (a list, like supervisors); keep reading the old single map during migration.
- Timesheet: per-site **sessions** (`{siteId, in, out}`) under each worker's daily
  entry; one open session at a time; switching site closes the previous session.
- Migration script for existing users and the timesheet shape (old reports keep working).
- Reports: hours per site and per worker; site filter.
- Manage-team sheet: stop moving masons off other sites; add instead.

### Phase 4 — Admin alerts when a worker leaves (c)
- Geofence exit while checked in → `device_events` type `left_site` (plus return).
- Push notifications: `firebase_messaging`, save FCM tokens per user, and a Cloud
  Function on `device_events` that notifies admins and the site's supervisor for
  critical types.
- Notification settings (which alerts, quiet hours).

### Phase 5 — Salary details (e)
- New `payroll/{uid}` collection (admin-only; the worker can read their own):
  basic, housing, transport, food, other allowances (name + amount), currency (AED),
  pay type (monthly / daily / hourly), effective date, history.
- Admin: salary section on the user admin page. Worker: "My pay" screen.
- Strict rules: only admins write; the worker reads only their own document.

### Phase 6 — Hours-based pay (f)
- Monthly calculation from attended hours (Phase 2–3 data) against the salary
  package (Phase 5).
- **Decisions needed from the client before building:** standard hours/day and
  days/month, how missing check-outs and auto check-outs count, overtime rate,
  weekends/holidays, whether allowances are pro-rated or fixed.
- Worker view: month to date — hours, days, expected pay, unpaid gaps with reasons.
- Admin view: payroll summary per month with export (Excel), and a lock/approve step.
- ⚠️ Pay deductions must follow UAE labour law and the WPS (Wage Protection System) —
  the app calculates; the employer approves the final payroll.

### Phase 7 — Remaining UI and delivery
- Redesign the remaining old screens: own profile, project/mock-up create/edit and
  map picker, live map, clients, sales visits, helpers, workers' current state.
- iOS build (TestFlight), Android release build, Play listing.
- Admin web dashboard (Flutter web): live map, team status, attendance and payroll
  reports, users and sites.
- Switch to `firestore.strict.rules` after every phone runs the new version.

---

## 6. Session log

- **2026-10-01** — Revived the project, rebuilt tracking and check-in, redesigned
  major screens and reports, deployed interim rules. Found Firebase billing expired.
  Feature audit (a–f) and this roadmap created. Waiting on the client's payment and
  billing.
