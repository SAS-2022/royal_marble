# Royal Marble — Project Status

Living tracker for this project, kept up to date across chat sessions.
**Read this first when resuming work. Update it after every step: tick tasks, change
phase status, and add a line to the session log.**

_Last updated: 2026-10-05_

---

## 0. Next session — start here (written 2026-10-04)

**Where things stand:** all work is committed on `revive-2026` (latest `954708a` +
this note) but **not pushed** to GitHub yet. Nothing deployed. Phase 7 is done
(sites, profile + helpers, sales, live map with zoom and a pin colour key, dead-code
cleanup).

**Deploys:** the user said on 2026-10-04 that nobody is using the live app now, so
deploys can't lose data. Each deploy still needs the user's go-ahead (show the exact
command, dry run first). The user is upgrading Firebase from Spark to **Blaze**; when
they confirm it's done, start with the pending deploys in section 3 (payroll rules,
then functions + indexes). Ask whether the "after every phone runs the new app"
gates (assignment migration, strict rules) still apply.

**To start:** `cd functions && npm run emulators` (terminal 1), `npm run seed`, then
run the app with `--dart-define=USE_EMULATOR=true` (see section 4). Test accounts in
section 4 (now includes `sales@test.local`). The emulator was rebuilt on 2026-10-04
(8 GB storage, fresh install, app language follows the phone: English).

**Work queue (no deploys needed), in order:**
1. ✅ **Phase 7 group 3 — sales screens** (done 2026-10-04, see Phase 7).
2. ✅ **Phase 7 group 4 — live map** (done 2026-10-04, see Phase 7).
3. ✅ **Phase 7 group 5 — dead code** (done 2026-10-04, see Phase 7).
4. **Phase 4 client side:** push notifications wiring (`firebase_messaging`, FCM
   tokens per user, function on `device_events` for `left_site` etc.) — written and
   tested on the emulators, not deployed.
5. iOS build prep (Maps key out of `AppDelegate.swift`, Podfile), then the admin web
   dashboard.

**Needs a real phone / the user:**
- Walk out of and back into a site with a real phone to confirm geofence
  `left_site` / `returned_to_site` and the 60-min auto check-out.
- Tap through "Delete my account" in the app once (verified only via script).

**Waiting on the client:** payment, Blaze upgrade (user doing it; functions deploy),
decisions in section 6 (esp. #2 auto check-out rules and whether short absences
are paid), native-speaker review of Arabic/Hindi/Urdu, production test mason
account, then the pending deploys table in section 3.

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
| `time_sheet/{d-m-yyyy}` | One doc per day, a map keyed by uid. **`sessions`** (one per stay at a site: `siteId`, `siteKind`, `siteName`, `in`/`out` local stamps + `inTs`/`outTs`, `events` enter/exit, `work`, `auto`, `switched`, `corrected`), plus `reviewed` / `corrections` (admin audit). The flat legacy fields `arriving_at`, `leaving_at`, `isOnSite`, `projectId`, `projectName`, `workCompleted` are derived from sessions on every server write so the 2023 app keeps working. Entries without `sessions` are read as one session. |
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
- [x] Phase 2 + 3 code (2026-10-03): per-site sessions, site switching, geofence presence log,
      auto check-out, admin correction screen with audit, multi-site assignments, per-site
      reports — **functions not deployed**; verified on the emulators

## 3. Blocked / waiting on the client

> **Deploy policy (updated 2026-10-04):** the user says nobody is using the live app
> now, so deploys can't lose data. The 2026-10-01 freeze is lifted, but every deploy
> still needs the user's explicit go-ahead. Functions need the Blaze plan (upgrade in
> progress).


- [x] **Firebase billing:** Blaze active (2026-10-05). Functions deployed 2026-10-05
      (us-central1, Node 22, 2nd gen); container images kept 1 day.
- [x] **`users` index (roles CONTAINS + firstName) restored 2026-10-05** — it was
      deleted by mistake during the functions deploy (it wasn't in
      `firestore.indexes.json`, now it is). Never answer "yes" to deleting indexes
      that aren't in the file.
- [ ] **Google sign-in (user, Firebase console):** add the SHA fingerprints to the
      Android app (Project settings → Your apps → com.royalmarble.tracking), then
      download the new `google-services.json` into `android/app/`.
      Debug SHA-1 `80:12:22:69:35:E5:71:A7:69:55:06:B0:F1:97:EA:B8:E6:F1:CB:D6`,
      SHA-256 `28:E4:9A:40:C6:68:37:75:10:E1:E7:25:9B:DC:C3:BB:6E:CB:52:BD:E0:26:FE:8A:A8:BD:B0:AD:5A:AD:4B:AD`;
      release (`royal-keystore.jks`) SHA-1 `75:E5:33:BC:97:30:C4:7F:37:77:22:67:7F:C6:57:03:B0:97:B0:9A`,
      SHA-256 `CF:6E:D0:1B:5D:35:EA:54:4A:EC:A8:DA:D4:92:8A:51:AF:2D:70:1B:9B:78:0E:8E:4F:C1:F2:23:64:25:ED:61`.
      If the app is on Google Play with Play App Signing, also add the "App signing
      key" SHA-1 from Play Console.
- [ ] **Payment** under the contract (work paused until received)
- [ ] Rotate or restrict the Google Maps API keys (exposed in git history)
- [ ] A test mason account in production for end-to-end testing (emulator accounts exist)
- [ ] Decide: track masons 24/7 or only during working hours
- [ ] Possible duplicate accounts: "Nemichand Saini" ×2, "Rajender"/"Rajendr" Saini
- [ ] **User:** open Firebase console → Crashlytics once to switch on the dashboard
- [ ] **User:** change the password of the admin test account (it was shared in chat)

### Pending production deploys (all on hold — each needs explicit approval)
| What | Command (add `--project royal-marble --account royalmarble.uae@gmail.com`) | Safe for old app? | Needs billing? |
|---|---|---|---|
| ✅ `payroll` rules (additive) — **deployed 2026-10-05** | `firebase deploy --only firestore:rules` | ✅ yes | no |
| ✅ Functions `checkInOut`, `reportPresence`, `autoCheckout`, `correctAttendance`, `detectSilentDevices` + index — **deployed 2026-10-05** | `firebase deploy --only functions,firestore:indexes` | ✅ yes | yes (Blaze active) |
| Assignment migration (`functions/scripts/migrate-assignments.js`: mason map → list, stale team entries) | dry run first, then `--project royal-marble --apply` | ❌ **only after every phone runs the new app** (old app reads a mason's assignment as a map) | no |
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

### Local test backend (Firebase Emulator Suite) — no production access
- Start: `cd functions && npm run emulators` (Auth 9099, Firestore 8080, Functions
  5001, UI http://127.0.0.1:4000). Uses Android Studio's Java 21.
- Seed test data: `cd functions && npm run seed` (refuses to run unless pointed at
  the emulators; also clears test timesheets). Accounts, password `test1234`:
  `admin@test.local`, `supervisor@test.local`, `mason1@test.local` (Test Villa + Marina
  Mock-up), `mason2@test.local` (Far Site), `pending@test.local` (inactive),
  `sales@test.local` (Sara: 2 clients, 3 visits this week, one with a manager comment).
- Server attendance tests: `cd functions && npm run test:checkin` (re-seeds first) — 31
  scenarios: check-in rules (range, assignment, fake/weak GPS, double check-in, inactive),
  site switching and session shape, presence enter/exit, alerts, auto check-out (away
  60 min, end of day) via the emulator-only `devRunAutoCheckout` trigger, admin
  corrections. **All pass (2026-10-03).** Run before 21:00 local: after 22:00 the
  end-of-day rule fires early and one check fails.
- `mason1` is assigned (list shape) to Test Villa + Marina Tower (70 m apart, both in
  range at the geo fix below) and Marina Mock-up; `mason2` keeps the legacy map shape.
- If the app shows stale data / `INVALID_REFRESH_TOKEN` after the emulators restart,
  sign out and in again.
- App against the emulators: `flutter run --dart-define-from-file=config/env.json
  --dart-define=USE_EMULATOR=true` (purple EMULATOR ribbon). Real phone: add
  `--dart-define=EMULATOR_HOST=<Mac LAN IP>`.
- Put the emulator at Test Villa: `adb emu geo fix 55.1400 25.0800`.
- Note: the tracking plugin goes idle when the phone isn't moving, so a teleported
  emulator position doesn't refresh the distance; real movement does. Geofences
  (Phase 2) report site exits even while idle.

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
- 16 analyzer style notes, no warnings (2026-10-04).
- `intl_phone_number_input` is only used for the `PhoneNumber` type in
  `business_model.dart`; could be replaced by a plain map.
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
| a | Workers check in/out **only at assigned sites** | ✅ Code done (server checks assignment); deploy pending. |
| b | Timesheet per worker, **monitoring presence** on site | ✅ Code done: presence log, auto check-out, admin review; deploy pending. |
| c | **Admin notified when a worker leaves** the site | 🔄 In-app `left_site` alert done; push notifications not built. |
| d | Worker on **several sites**, hours **per site** | ✅ Code done: multi-site assignments, sessions, per-site reports; migration at rollout. |
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

### Current agenda (no deploys needed) — set 2026-10-01
1. **Phase 8 foundation:** localization setup, RTL, language picker, translate the
   worker-facing screens first (sign-in, registration, home, check-in, status
   banner, My pay).
2. ✅ **Local test backend:** Firebase Emulator Suite (Auth + Firestore + Functions),
   seed script and 12 automated check-in scenarios — see "How to resume".
3. ✅ **Phase 2 + 3 code** against the emulator: assignment check, presence log,
   multi-site sessions, per-site hours; migration script written but not run.
4. 🔄 **Phase 7:** redesign the remaining old screens, written with translations from
   the start. Order: (1) ✅ sites, (2) ✅ own profile + helpers, (3) ✅ sales (clients,
   visits), (4) ✅ live map, (5) ✅ dead-code cleanup.
5. **Phase 4 client side** (geofence exit events; push wiring ready, not deployed).
6. **Tech debt:** remove unused packages, iOS build prep.
7. **Admin web dashboard** (Flutter web), developed locally.

**Status key:** ⬜ not started · 🔄 in progress · ✅ done · ⛔ blocked

| Phase | Status | Blocked by |
|---|---|---|
| 1 Crashlytics | ✅ | — (open the Crashlytics page in the console once) |
| 2 Attendance correctness | 🔄 code ✅ | Functions deploy (billing); client decision #2 |
| 3 Multi-site + per-site hours | 🔄 code ✅ | Functions deploy; migration at rollout |
| 4 Leaving-site alerts + push | 🔄 | `left_site` alerts done (in-app); push not started |
| 5 Salary details | 🔄 | `payroll` rules deploy (production freeze) |
| 6 Hours-based pay | ⬜ | Phases 2, 3, 5; client decisions (below) |
| 7 Remaining UI + delivery | 🔄 sites, profile, sales, map ✅ | — (web dashboard after 2–4) |
| 8 Localization (en, ar, hi, ur) | 🔄 | — |

### Decisions needed from the client (Phase 6 and related)
1. Standard working hours per day, and working days per month (UAE practice is often
   26 or 30 days for daily rate calculation).
2. A day with check-in but **no check-out**: zero pay, auto check-out at the last
   on-site time, or admin reviews each one? *Built for now:* auto check-out after 60 min
   outside the site (at the exit time) or at 22:00 local (at the phone's last report),
   flagged for admin review — `AWAY_LIMIT_MIN` / `END_OF_DAY_HOUR` in
   `functions/src/attendance.ts`. Is time briefly outside the site (lunch) paid?
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
Code done 2026-10-03, verified on the emulators; nothing deployed.
- [x] `checkInOut`: reject sites the worker isn't assigned to.
- [x] Presence log: a geofence per assigned site (`TrackingService`, min radius 150 m);
      enter/exit go to the `reportPresence` callable, recorded as `events` on the open
      session only while checked in there; `left_site` / `returned_to_site` alerts.
- [x] Auto check-out: scheduled `autoCheckout` (every 15 min) — 60 min outside → closed
      at the exit time (`auto: left_site`); still open at 22:00 local → closed at the
      phone's last report (`auto: end_of_day`); `auto_checkout` alert.
- [x] Admin correction screen (`lib/screens/attendance_edit_screen.dart`, opened by
      tapping a report row): change site/times, add or remove a stay, or approve as is;
      `correctAttendance` keeps `corrections` (who, when, reason, previous sessions).
- [ ] Verify geofence events on a real phone (the emulator can't move realistically).
- [ ] Night shifts across midnight aren't modelled (a session belongs to its start day).

### Phase 3 — Multiple sites per worker, hours per site (d)
- [x] Assignments are a list for everyone; the team sheet adds a site instead of moving
      the worker; removal matches by site id (`DatabaseService._setAssignment`).
      Readers accept the old single map (`siteAssignments`).
- [x] Timesheet sessions, one open at a time; "Switch to this site" on the check-in card
      closes the old session (mason fills the work sheet for it) and opens the new one.
- [x] Reports: one row per stay, site filter, "By site" view, auto/edited tags, away
      time; PDF/Excel get a Note column and an hours-by-site table/sheet.
- [x] Migration script `functions/scripts/migrate-assignments.js` (dry run by default;
      tried on the emulator). **Not run on production.**
- Home: admin's "Today's attendance" lists each worker's sites in order; supervisors'
  roster shows the current site and "outside the site since".

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

### Phase 8 — Localization (English, Arabic, Hindi, Urdu)
Workers come from different countries; each user picks a language.
- [x] Flutter `gen-l10n` with ARB files `lib/l10n/app_{en,ar,hi,ur}.arb` (~160 strings each;
      a unit test checks that all four have the same keys)
- [x] Language picker on sign-in and in the drawer; choice saved on the device and in
      `users/{uid}.language`, falling back to the phone's language
      (`lib/core/locale_controller.dart`, `lib/widgets/language_picker.dart`)
- [x] RTL for Arabic and Urdu — verified on the emulator (sign-in, registration)
- [ ] Optional: bundle a Nastaliq font for Urdu (system Naskh is used now)
- [x] Translate the worker-facing screens: sign-in, password reset, registration,
      home (all roles), check-in card and work sheet, status banner, My pay and
      breakdown, pending approval, drawer, role names, country names (Arabic only —
      the picker package has no Hindi/Urdu)
- [x] Admin and supervisor screens: team status, users list, user admin page, site
      details and team sheet, salary editor, reports (154 more strings, 2026-10-02).
      PDF/Excel exports stay English (records for the office) unless requested.
- [x] Old screens translated as each was redesigned in Phase 7 (profile, sites,
      helpers, clients and visits, live map)
- [x] Server check-in errors now carry `details.reason` codes; the app translates
      them (function code only; deploy later). Same change added the
      **assignment check** for feature (a).
- [x] Role labels translated
- [x] Alert texts translated by event type (stored English text is the fallback);
      phone-problem labels are now codes (`DeviceProblem`) shown in the reader's language
- [ ] Review: machine-quality translations need a native-speaker check (ask the
      client for an Arabic, Hindi and Urdu reader)

### Phase 7 — Remaining UI and delivery
- [x] **Sites (2026-10-03):** one form for projects and mock-ups
      (`lib/screens/site_form_screen.dart`): name, description, status, map pin picker
      (pin stays centred, address search, my location, radius circle), editable
      address, radius chips, contractor contact. Saving refreshes every assigned
      worker's copy of the site (tracking reads it). Delete removes the site from its
      workers first. "All sites" list (`sites_screen.dart`) with kind/status filters and
      search — closed sites were unreachable before. Site details open live by id
      (`SiteDetailsLoader`) from the dashboard, worker cards and the list; admins
      change status from the status pill; team rows show today's attendance.
      Removed `lib/projects/*` and `lib/mockups/*` (11 files, ~3,700 lines) and 12
      unused database methods. Site parsing tolerates a whole-number radius, a
      missing phone and a deleted document (old code crashed).
- [x] **Own profile and helpers (2026-10-03):** `MyProfileScreen` (photo, name,
      mobile with UAE check, company, nationality, home address via the shared pin
      picker; role, sites and helpers read-only) and self-service account deletion
      (password re-check, deletes profile then login — needed for store review).
      `HelpersCard` on the mason's profile and on the admin user page: assign up to 2,
      add/edit/delete helpers (delete also unassigns them everywhere). Admin user page
      is now `UserAdminScreen`. Removed `users_details.dart`, `helpers.dart`,
      `helpers_list.dart`, `shared/country_picker.dart` (1,661 lines) and 5 unused DB
      methods. Profile photos are stored as `profile_images/{uid}.jpg` (replaced, not
      piled up). Strict rules: only managers write `helper`.
- [x] **Sales (2026-10-04):** `ClientsScreen` (search, admins see everyone's with the
      owner's name), `ClientDetailsScreen` (live; call, email, directions, the owner's
      visits to the client, "New visit" pre-filled), `ClientFormScreen` (address via the
      shared pin picker, optional). `VisitFormScreen`: one page, two steps (client or
      project, with "Add client" inside the picker; contact pre-filled; purpose chips;
      notes ≥ 20 chars; time can be set back up to 7 days). `VisitsScreen`: last 7
      days / this month / last month / custom, client/project filter, grouped by day;
      admins pick the salesperson. `VisitDetailsScreen`: owner edits contact, purpose,
      notes; admin writes the manager comment. Sales home shows today's visits.
      Storage unchanged (`clients`, `users/{uid}/clientVisits|projectVisits`, same
      fields), so the Sales activity report and the 2023 app still read them.
      Purposes are stored in English and shown translated. Removed `lib/clients/*`,
      `lib/sales_pipeline/*`, `shared/date_picker.dart`, `reports/report_details.dart`
      and 11 old DB methods; client parsing no longer crashes on a missing phone.
- [x] **Live map (2026-10-04):** `LiveMapScreen` replaces `show_map.dart` (crashed on
      open: null home address). Workers' last positions as pins coloured by state
      (red phone problem, orange outside the site while checked in, green on site,
      blue not checked in), faded when the location is over 2 h old; site circles
      and pins (tap opens the site). Filter chips with counts, "show everyone",
      a people list sorted by urgency. Worker sheet: today's status, location age,
      distance from the nearest site, phone problems, call, directions, open the
      current site. Long-press the map to start a project or mock-up there.
      Supervisors see only their sites and the people on them. Site directions now
      open Google Maps; registration's home address uses the shared pin picker.
      Removed `lib/location/*` (5 files, ~1,500 lines), `models/directions.dart`
      and 5 DB methods. Also fixed: contractor phone shown as "971…+" in RTL, and
      a stray "- " at the start of looked-up addresses. After the user's review:
      zoom in/out buttons and a "What the pins mean" colour key (toggled from the
      app bar, remembered per phone); pins, chips, list and sheet share one colour
      per state.
- [x] **Dead code (2026-10-04):** removed `core/env.dart` (only the old directions
      code used it; the Android Maps key comes from `local.properties`),
      `shared/constants.dart`, `export_excel.dart`, `generating_pdf.dart`,
      `pdf_builder.dart`, `snack_bar.dart`, and 14 unused packages (`location`,
      `flutter_speed_dial`, `latlong2`, `flutter_map`, `timer_builder`,
      `animated_text_kit`, `dio`, `flutter_polyline_points`, `flutter_spinkit`,
      `firebase_database`, `flutter_typeahead`, `syncfusion_flutter_datepicker`,
      `http`, `image`). Fixed the last 6 analyzer warnings: 16 style notes left
      (was ~249). Full debug APK builds; tests pass. **Not yet run on a device:**
      the emulator is out of storage (shared with other projects' apps), so Royal
      Marble is currently uninstalled from it.
- iOS build (TestFlight), Android release build, Play listing.
- Admin web dashboard (Flutter web): live map, team status, attendance and payroll
  reports, users and sites.
- Switch to `firestore.strict.rules` after every phone runs the new version.
- Note: stored addresses come from Android's geocoder in the phone's language (an
  Arabic phone gives Arabic area names); admins can edit the address text.

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
- **2026-10-01 (new session)** — User asked to continue with no-deploy work and to
  add localization (English, Arabic, Hindi, Urdu). Agenda set (see Roadmap); starting
  with the Phase 8 foundation.
- **2026-10-02** — Phase 8 foundation done: 4 languages, language picker, RTL; all
  worker-facing screens and the home screen translated; server errors use codes;
  assignment check added to `checkInOut` (not deployed). Replaced the template
  widget test with 9 unit tests (all pass). Next: translate admin screens and alert
  texts, then the Firebase emulator setup.
- **2026-10-02 (cont.)** — Admin screens translated; alert and phone-problem texts
  follow the reader's language. Verified on the emulator in Arabic, Hindi and Urdu
  (sign-in, registration, admin dashboard, Team Status). Removed empty placeholder
  tests; `flutter test` passes. Next: Firebase emulator setup (agenda item 2).
- **2026-10-02 (cont.)** — Local test backend ready: emulators, guarded seed script,
  12 check-in scenarios all pass. Full worker flow verified in the app against the
  emulators (Arabic UI): sign-in as a mason, both sites in range, check-in blocked
  while checked in elsewhere, work sheet and check-out, check-in again. Fixed:
  durations can no longer show negative ("−56 m") when phone and server clocks
  disagree. Next: Phase 2 + 3 code (agenda item 3).
- **2026-10-02 (end of session)** — Paused by the user; all work committed on
  `revive-2026`. Resume with agenda item 3 (Phase 2 + 3 code on the emulators).
- **2026-10-03** — Agenda item 3 done (Phase 2 + 3 code, nothing deployed). Server:
  per-site sessions with legacy fields kept, site switching, `reportPresence`,
  `autoCheckout`, `correctAttendance`; 31 emulator scenarios pass. App: sessions model,
  check-in card with "Switch to this site" and outside/auto pills, geofences per site,
  multi-site team assignment, reports by site with review flow, correction screen,
  35 new strings in 4 languages; 17 unit tests pass. Verified in the app on the emulator
  (Arabic): mason check-in → switch site with work sheet; admin dashboard, report,
  approve an auto check-out. Fixed RTL time ranges ("16:30 → 07:00"). Migration script
  written, tried on the emulator only. Next: agenda item 4 (Phase 7 screens) or Phase 4
  push wiring.
- **2026-10-03 (cont.)** — Phase 7 group 1 (sites) done: new site form with map pin
  picker, All sites list, live site details with status change and today's team
  attendance; old project/mock-up screens removed. Verified on the emulator (English
  and Arabic): edit and move a pin, radius change propagates to workers, status change,
  create a site, assign a mason who keeps their other sites. Fixed: seed wrote
  `projectStatus` instead of `status` (dashboard showed 0 active projects); plurals
  ("1 people"). 20 unit tests, 31 emulator scenarios pass. Next: group 2 (own profile
  and helpers).
- **2026-10-03 (cont.)** — Phase 7 group 2 done: own profile editor with account
  deletion, helpers card for masons and admins. Verified on the emulator in Arabic:
  admin adds/deletes a helper and assigns two to Ravi; Ravi sees sites and helpers,
  sets his home address, saves (role and access untouched); deletion tested on the
  login emulator (wrong password refused; profile and login removed). Next: group 3
  (clients and sales visits).
- **2026-10-03 (end of session)** — Paused by the user. Everything committed and
  pushed to GitHub (`revive-2026`). Plan for next time in section 0.
- **2026-10-04** — Phase 7 group 3 (sales) done: clients list, details and form; new
  visit form; visits list with periods and salesperson picker; visit details with
  manager comments; today's visits on the sales home. 61 strings in 4 languages;
  26 unit tests pass. Verified on the emulator in Arabic as `sales@test.local`
  (client without a phone loads, add visit from a client, notes validation, list,
  details) and as admin (Sara's visits, manager comment saved with the same field
  names, Sales activity report counts the new visit). The user is upgrading Firebase
  to Blaze; production freeze still applies to every deploy. Next: group 4 (live map).
- **2026-10-04 (cont.)** — The user said nobody is using the live app now, so
  deploys can't lose data (each still gets a go-ahead); Blaze upgrade not finished
  yet. Phase 7 group 4 (live map) done: new `LiveMapScreen`, old `lib/location/*`
  removed, 10 strings in 4 languages, 33 unit tests pass. Verified on the emulator
  as admin with demo workers written to the local emulator (on site, outside,
  phone problem, stale): framing, filters, worker sheet, open site from the sheet,
  people list, long-press → new project form. Next: group 5 (dead code, packages).
- **2026-10-04 (cont.)** — Phase 7 group 5 done: dead files and 14 unused packages
  removed, analyzer warnings cleared. Debug APK builds and tests pass, but the
  emulator ran out of storage so the new build is not yet installed there (Royal
  Marble uninstalled from the emulator; the other projects' apps were left alone).
  Next: Phase 4 push notifications (item 4), built and tested on the emulators.
- **2026-10-04 (end of session)** — Live map review by the user: added zoom buttons
  and a pin colour key. While making room for the app, raising the emulator's
  storage (4 → 8 GB) wiped the emulator's other test apps; the user said they can
  re-run them (lesson saved: ask before changing shared tooling). Everything
  committed on `revive-2026`, not pushed. Paused by the user. Next: push
  notifications (queue item 4), or the deploys once Blaze is active.
- **2026-10-05** — Blaze active. Functions and the `deviceStatus` index deployed to
  production (dry run first; the user ran the real deploy). During it, the CLI asked to
  delete a production index missing from `firestore.indexes.json` (`users`: roles
  CONTAINS + firstName), and "yes" was answered; the worker and sales-user lists need
  it, so it was added to the file — restored the same day. `firebase-functions` 6.x shows an
  "outdated" warning (upgrade has breaking changes; left for later). Next: the `payroll`
  rules (first try failed with 403: run without `--account`), then check-in on a real phone against production.
- **2026-10-05 (cont.)** — Live checks: the 3 callables refuse unsigned calls;
  `detectSilentDevices` (04:41) and `autoCheckout` (04:46) ran in production with no
  errors. `payroll` rules deployed by the user. Test mason `mason.test@royalmarble.test`
  registered through the app on the emulator against production (photo, profile,
  pending screen OK); the user approved it and assigned a site. Production test data
  to delete afterwards: that login, its `users` doc, `profile_images/` photo, the
  test site and its timesheets.
  **Google/Apple sign-in added:** "Continue with Google" on sign-in and at the top
  of registration; Apple shown on iOS only (Android would need an Apple Services ID).
  A first-time Google/Apple user lands on the registration steps without the
  account step (name pre-filled), then waits for approval like everyone else
  (`Wrapper` uses `watchUser`, which returns null only when the server confirms no
  profile; the save re-checks the server so it never overwrites a profile).
  Account deletion re-confirms with Google/Apple instead of a password. Package
  `google_sign_in` 7.2. 7 new strings in 4 languages; 33 tests pass. On the emulator
  the Google button fails cleanly ("no provider dependencies": SHA fingerprints not
  in Firebase yet and the emulator's Play services lack Credential Manager) — test
  on a real phone after the SHA step. iOS still needs `GoogleService-Info.plist`,
  the reversed client id URL scheme and the "Sign in with Apple" capability (part
  of iOS build prep).
