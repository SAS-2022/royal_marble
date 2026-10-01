# Royal Marble — Project Status

Living tracker for this project, kept up to date across chat sessions.
**Read this first when resuming work. Update it after every step: tick tasks, change
phase status, and add a line to the session log.**

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
- [x] Phase 1: Sentry → Firebase Crashlytics (verified a test report was delivered)
- [x] Phase 5 code: salary packages (admin editor, worker "My pay") — rules deploy on hold

## 3. Blocked / waiting on the client

> **Production freeze (2026-10-01):** the app is live and in use. No deploys of any
> kind (rules, functions, indexes) until the user has finalized with the client and
> explicitly approves each one. Code work continues on `revive-2026` only.


- [ ] **Firebase billing:** card expired → Cloud Functions can't deploy. Until
      `checkInOut` is deployed, check-in in the new app fails.
      Deploy: `firebase deploy --only functions,firestore:indexes ...`
- [ ] **Payment** under the contract (work paused until received)
- [ ] Rotate or restrict the Google Maps API keys (exposed in git history)
- [ ] A test mason account for end-to-end testing
- [ ] Decide: track masons 24/7 or only during working hours
- [ ] Possible duplicate accounts: "Nemichand Saini" ×2, "Rajender"/"Rajendr" Saini
- [ ] **User:** open Firebase console → Crashlytics once to switch on the dashboard
- [ ] **User:** change the password of the admin test account (it was shared in chat)

### Pending production deploys (all on hold — each needs explicit approval)
| What | Command (add `--project royal-marble --account royalmarble.uae@gmail.com`) | Safe for old app? | Needs billing? |
|---|---|---|---|
| `payroll` rules (additive) | `firebase deploy --only firestore:rules` | ✅ yes | no |
| Functions `checkInOut`, `detectSilentDevices` + index | `firebase deploy --only functions,firestore:indexes` | ✅ yes (old app never calls them) | **yes** |
| Strict role-based rules | copy `firestore.strict.rules` → `firestore.rules`, deploy | ❌ **only after every phone runs the new app** | no |

The new app's check-in depends on `checkInOut`. Old app versions still write
`time_sheet` directly, and the interim rules allow that.

### Business / contract notes
- Contract (Wisora ↔ Royal Marble, dated 01 Oct 2026, USD 1,500 one-time) was
  reviewed. Fixes suggested to the user: timeline "eight weeks (6 weeks)"
  contradiction; define "Effective Date"; client legal entity name and title; §6/§7
  conflict on store-account fees; typos; add delivery/acceptance definition; iOS
  TestFlight builds expire after 90 days; source and data ownership; worker-location
  privacy/consent (UAE PDPL); name third-party costs (Transistorsoft, Maps, Firebase).
- Data finding to share with the client: in Nov 2023, 63 of 93 mason work-days had
  no check-out, so those hours were never counted (old checkout crash).

---

## 4. How to resume (dev workflow)

- `git switch revive-2026`; read this file; `flutter pub get`.
- Devices: the user's phone **23021RAAEG** (Xiaomi, adb id `76031c77`, signed in as
  admin, connect by USB) and the emulator **Pixel_3A** (`emulator-5554`).
  If the emulator has no DNS: `emulator -avd Pixel_3A -dns-server 8.8.8.8,1.1.1.1`.
- Run with a PID file so hot reload can be triggered from scripts:
  `flutter run -d <id> --dart-define-from-file=config/env.json --pid-file /tmp/f.pid`
  then `kill -USR1 $(cat /tmp/f.pid)` (hot reload) / `-USR2` (hot restart).
- Screenshots: `adb -s <id> exec-out screencap -p > shot.png`.
- Test accounts: the user's admin account (ask the user for credentials; never store
  them). There is **no mason test account yet**, so worker flows are untested end to end.
- Functions: `cd functions && npm run build` (Node 22). Rules compile check:
  `firebase deploy --only firestore:rules --dry-run ...`.
- Key files: `lib/services/tracking_service.dart`, `lib/services/checkin_service.dart`,
  `functions/src/index.ts`, `lib/home.dart`, `lib/wrapper.dart`, `lib/core/*`,
  `lib/reports/*`, `lib/screens/*`, `firestore.rules`, `firestore.strict.rules`.

### Commits on `revive-2026`
| Commit | What |
|---|---|
| `0c9ed8c` | Toolchain revival, unified tracking, server check-in, new home UI |
| `7228a25` | UI: auth, drawer, users, user admin, site details |
| `518d741` | Removed dead code; interim rules |
| `16ceaa9` | 3-step registration |
| `8c7b585` | Reports rebuilt (attendance and sales, PDF/Excel) |
| `e840466` | This status file |
| `0a13add` | Sentry → Crashlytics |
| `1417893` | Phase 5 salary details |
| `4272c9d` | Production freeze noted |

### Known tech debt
- ~249 analyzer infos/warnings (mostly old style lints in untouched screens).
- Unused packages to remove: `location`, `flutter_speed_dial`, `latlong2`,
  `flutter_map`, `timer_builder`, `animated_text_kit` (0 imports each).
- Build warns that several plugins still apply the Kotlin Gradle Plugin (Firebase
  plugins, `location`); a future Flutter release will require plugin updates.
- iOS not built yet: the Maps key is hard-coded in `ios/Runner/AppDelegate.swift`;
  Podfile needs updating.
- `AlertsFeed` filters a single user's alerts client-side from the latest N events
  (fine now; needs an indexed query at scale).
- The `CheckInCard` reads today's timesheet by the phone's date, while the server
  uses server time plus the phone's UTC offset; this only differs if the phone clock
  is wrong.
- Remaining old screens listed under Phase 7.

---

## 5. Feature audit (requested 2026-10-01)

| # | Requirement | Current state |
|---|---|---|
| a | Workers check in/out **only at assigned sites** | ⚠️ Partly. The app only shows assigned sites, but the server function does **not** verify the assignment. |
| b | Timesheet per worker, **monitoring presence** on site | ⚠️ Partly. A daily entry records check-in/out. Presence *during* the day is not logged, and 63 of 93 mason-days in Nov 2023 had no check-out. |
| c | **Admin notified when a worker leaves** the site | ❌ Not built. Alerts exist for location off/offline/silent, but not for leaving the site, and nothing pushes to the admin's phone. |
| d | Worker on **several sites**, hours **per site** | ❌ Not supported. A mason holds one assignment, and a timesheet day holds one site per worker (a second check-in overwrites the site). |
| e | **Salary details** (basic, housing, transport, food…) | ❌ Not built. |
| f | Pay based on **worked hours**; no check-in/out → unpaid | ❌ Not built. Needs policy decisions (see Phase 6). |

---

### Audit details
- **a:** `functions/src/index.ts` `checkInOut` loads the site and checks distance, but
  never compares `siteId` with the user's `assignedProject` / `assignedMockup`.
  Today it relies only on the home screen listing assigned sites.
- **b:** `time_sheet/{day}` holds one entry per worker per day: first `arriving_at`,
  last `leaving_at`. There are no events for leaving and returning during the day.
  Nov 2023 data: masons Nemichand (10/10 days without check-out), Davaki (13/24),
  Niwas (6/13), Ram Dev (7/13), Babu Lal (7/11). The old checkout crash for masons is
  the likely cause (fixed in `0c9ed8c`).
- **c:** `device_events` + Team Status cover location off, GPS off, permission changes,
  offline, battery saver, low battery, fake GPS, tracking stopped, reboot, and
  "silent" (server). No geofence events; no push notifications (in-app only).
- **d:** `updateProjectWithWorkers` writes a single map to a mason's
  `assignedProject`, so assigning one to a new site silently moves them (the old site's
  `assignedWorkers` keeps a stale entry). Supervisors already use a list.

---

## 6. Roadmap

**Why this order:** pay (6) is only fair once attendance is trustworthy (2) and
recorded per site (3). Leaving-site alerts (4) reuse the geofences from 2. Phase 1 is
independent and needs no billing, so it goes first.

**Status key:** ⬜ not started · 🔄 in progress · ✅ done · ⛔ blocked

| Phase | Status | Blocked by |
|---|---|---|
| 1 Crashlytics | ✅ | — (open the Crashlytics page in the console once) |
| 2 Attendance correctness | ⬜ | Functions deploy (billing) |
| 3 Multi-site + per-site hours | ⬜ | Phase 2; functions deploy |
| 4 Leaving-site alerts + push | ⬜ | Phase 2; functions deploy |
| 5 Salary details | 🔄 | `payroll` rules deploy (production freeze) |
| 6 Hours-based pay | ⬜ | Phases 2, 3, 5; client decisions (below) |
| 7 Remaining UI + delivery | ⬜ | — (web dashboard after 2–4) |

### Decisions needed from the client (Phase 6 and related)
1. Standard working hours per day, and working days per month (UAE practice is often
   26 or 30 days for daily rate calculation).
2. A day with check-in but **no check-out**: zero pay, auto check-out at the last
   on-site time, or admin reviews each one?
3. Overtime: paid? At what rate (UAE labour law sets 125%, or 150% at night or on rest days)?
4. Weekends, public holidays, sick and annual leave: how are they recorded and paid?
5. Allowances (housing, transport, food): fixed monthly, or reduced for absent days?
6. Pay type per worker: monthly salary, daily rate, or hourly?
7. Who approves the monthly payroll before it is final (admin only, or supervisor
   first)?
8. Should masons be tracked 24/7 or only during working hours (privacy and battery)?

> ⚠️ Deductions must follow UAE labour law and WPS. The app produces a **suggested**
> payroll; the employer reviews and approves it. Unpaid gaps are shown with the reason
> so they can be challenged and corrected.

### Phase 1 — Crashlytics instead of Sentry
Works on the free plan (no billing needed).
- [x] Add `firebase_crashlytics` 5.4 + Gradle plugin `com.google.firebase.crashlytics` 3.0.6
- [x] `lib/core/error_reporter.dart`: `ErrorReporter.record(error, stack)` and
      `ErrorReporter.message(text)`
- [x] Replace the 64 `Sentry.*` calls (`database.dart` 49, `auth.dart` 10,
      `tracking_service.dart` 3, `checkin_service.dart` 1, `show_map.dart` 1)
- [x] `main.dart`: remove Sentry init; route `FlutterError.onError` and
      `PlatformDispatcher.onError` to Crashlytics; off in debug unless forced
- [x] Set user id and role keys on sign-in (`wrapper.dart`); clear on sign-out (drawer)
- [x] Remove `sentry_flutter` from pubspec; build passes
- [x] Verify: test non-fatal sent from the emulator 2026-10-01 ("report successfully
      enqueued"). To repeat: `flutter run --dart-define-from-file=config/env.json
      --dart-define=CRASHLYTICS_DEBUG=true --dart-define=CRASHLYTICS_TEST=true`
- [ ] **User:** open Firebase console → Crashlytics once to enable the dashboard
      (settings report `firebase_crashlytics_enabled: false` until then)
- Notes: debug builds don't report unless `CRASHLYTICS_DEBUG=true`. If the emulator
  can't resolve hosts, start it with `-dns-server 8.8.8.8`.

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
Data: `payroll/{uid}` = `{currency, payType, basic, housing, transport, food,
other: [{name, amount}], effectiveFrom, notes, updatedAt, updatedBy}`; each save also
writes a snapshot to `payroll/{uid}/history/{auto}`.
- [x] Model `lib/models/salary.dart` (`SalaryPackage`, `PayType`, `Allowance`, totals)
- [x] Service `lib/services/payroll_service.dart` (stream, batched save with history)
- [x] Admin: Pay section on the user admin page (admins only, not supervisors) +
      editor (`lib/screens/salary_screens.dart`)
- [x] Worker: "My pay" in the drawer for all non-admin roles (read-only)
- [x] Rules written in `firestore.rules` and `firestore.strict.rules` (compile OK)
- [ ] **Deploy the `payroll` rules** — on hold (production freeze). Purely additive:
      existing rules are unchanged and current app versions never touch `payroll`.
      Until deployed, the Pay card shows "not available yet" (seen on the emulator)
- [ ] Verify on device: admin sets a package, the worker sees it, another user can't

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

## 7. Session log

- **2026-10-01** — Revived the project, rebuilt tracking and check-in, redesigned
  major screens and reports, deployed interim rules. Found Firebase billing expired.
  Feature audit (a–f) and this roadmap created. Waiting on the client's payment and
  billing.
- **2026-10-01 (cont.)** — Phase 1 done: Sentry removed, Crashlytics added and
  verified (test report delivered). Next: Phase 5 (salary details) and Phase 7 UI can
  proceed without billing; Phases 2–4 wait on functions deploy.
- **2026-10-01 (cont.)** — Phase 5 built: salary model, service, admin editor, worker
  "My pay". Signed in on the emulator with the admin test account (credentials are
  not stored anywhere). Confirmed the deployed `device_events` rule works (the alerts
  feed loads). Payroll rules need deploying before the feature can be tested end to end.
- **2026-10-01 (cont.)** — Production freeze: the user will finalize with the client
  before any deploy. Payroll rules are ready but on hold.
- **2026-10-01 (end of session)** — Paused by the user. Everything is committed on
  `revive-2026`. Next session: Phase 7 UI (no deploys needed) unless the client has
  signed off; then the pending deploys table above.
