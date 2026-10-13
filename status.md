# Royal Marble — Project Status

Living tracker for this project, kept up to date across chat sessions.
**Read this first when resuming work. Update it after every step: tick tasks, change
phase status, and add a line to the session log.**
**Every plan agreed in chat goes into "Plans log" (section 6) the same day: date, why it
was made, the steps in order, and what was decided. Later changes to a plan are added
under it, not overwritten.**

_Last updated: 2026-10-12_

---

## 0. Next session — start here (written 2026-10-11)

**Where we stopped (2026-10-11, paused by the user):** Block A (testing) is finished
and everything is committed on `revive-2026` (last code commit `d2d07e9`), **not
pushed**. Quiet hours, check-in/out, leave/return pushes, admin correction and My pay
were all verified in production (session log below).

**1. ✅ `correctAttendance` deployed** (2026-10-11 07:36 local, by the user): the server
now refuses correction times later than now, as the app does.

**2. Now: HR role + pay earned + overtime** (plan "2026-10-12 — HR role, pay earned so
far, overtime approval" in section 6 → Plans log; steps H1–H7, resume at the first
unticked one). **Block C** is done except C5 step 5 (hosting deploy, needs the user's
go-ahead) and step 6 (Google sign-in on the live site); Storage CORS rule for the web
was given to the user to run in Cloud Shell (photos on the web).

**Optional, any time:** user reviews the 2026-10-09 UI (bell/unread alerts, Active
sites overview, client map, live-map worker sheet) and the new wheel time picker;
a real-phone walk out of a site (`left_site`) and a 60-min auto check-out test with
Quiet Tester.

**Test data is kept until go-live** (user's decision): delete the list below just
before real users start.

**Devices now:** admin signed in on the Xiaomi `76031c77` (USB) and the Motorola
`ZY22MC9B2M`; the emulator (`emulator-5554`) is signed in as the test worker
**Quiet Tester** (`quiet.tester@royalmarble.test`, uid `LdEsCrk0…`, assigned to Test
Site, pay package set; password only in the 2026-10-11 chat). Test Site is at
25.07978, 55.13976 (radius 200 m). To fake a walk on the emulator, send `adb emu geo
fix <lng> <lat>` steps ~2 s apart (a single jump doesn't wake tracking).

### Earlier notes (2026-10-05)

**Where things stand:** all work is committed on `revive-2026` but **not pushed**.
Production now runs the new backend: Blaze is active, and all functions, the indexes
and the `payroll` rules are deployed (section 3). Nobody uses the live app yet, so
deploys can't lose data; each one still needs the user's go-ahead (dry run first).
Running `firebase deploy` from here works when the user has said to deploy; writing
to production directly (e.g. the Auth/Firestore REST APIs) is blocked by the
permission check, so test accounts are made through the app.

**Done on 2026-10-05:**
- Functions `checkInOut`, `reportPresence`, `autoCheckout`, `correctAttendance`,
  `detectSilentDevices` + `notifyNewUser` live in us-central1 (Firestore is `nam5`).
  Scheduled ones ran cleanly; callables refuse unsigned calls.
- `users` index (roles CONTAINS + firstName) was deleted by mistake during the first
  deploy and restored the same day. **Always answer "No" when the CLI offers to delete
  indexes that aren't in `firestore.indexes.json`.**
- Google sign-in (Android) works on a real phone; Apple sign-in coded, iOS only.
- Registration: mobile = 05 + 8 digits only; company locked to "Royal Marble".
- Push: admins/supervisors save FCM tokens; a new inactive profile notifies every
  active admin (in their language) — `notifyNewUser`. Serious worker alerts
  (`left_site`, `auto_checkout`, `silent`, `location_off`, `precise_off`,
  `tracking_stopped`, `mock_location`, downgraded permission) go to active admins and
  supervisors who share a site with the worker, max one per worker+type per 15 min
  (`push_throttle/{uid}_{type}`) — `notifyAlert`. **Verified in production:**
  foreground snack bar + "Details" opens the worker's page; a locked phone shows a
  system notification.
- Admin dashboard reworked: 2×2 tappable counts (on site / outside / phone
  problems / pending) that jump to lists — waiting for approval, outside the site,
  phone problems, on site now — each person opens their page.
- Notifications use a white status-bar icon (`ic_stat_notify`, gold tint) and a
  high-importance "alerts" channel created in `MainActivity` (manifest defaults).

**Next, in order:**
1. Check with the app fully closed (swiped away) that a notification still arrives
   and tapping it opens the person's page.
2. `left_site` push needs a real phone walked out of a site (the emulator never
   reports exits). The test mason on the emulator is still checked in at Test Site.
3. ✅ Notification settings (which alerts, quiet hours) — done 2026-10-09.
4. Ask the user: apply the same mobile/company limits on **My profile**?
5. End-to-end attendance test in production with the test mason (check-in, refused
   check-in from far away, leave/return, check-out, admin correction).
6. Clean up production test data afterwards (list below).
7. ✅ iOS build prep (2026-10-07/09: Podfile, `GoogleService-Info.plist`, Maps key in
   git-ignored `ios/Flutter/Secrets.xcconfig`, Google client id + URL scheme, Sign in
   with Apple capability). Left: TestFlight build, Apple key for token revocation.
   Then the admin web dashboard.

**Production test data — keep until go-live, then delete (user's call, 2026-10-11):** `quiet.tester@royalmarble.test`
("Quiet Tester", registered 2026-10-11 on the emulator, approved, no site; password in
that day's chat) and its `profile_images/` photo; logins + `users` docs +
`profile_images/` photos for `mason.test@royalmarble.test` (approved, assigned to a
site), the user's Google account sign-up (pending/approved), and the second test
account the user registered on 2026-10-05; the test site the user created and its
`time_sheet` entries. Test mason password is in the 2026-10-05 chat, not stored here.

**Devices:** Motorola edge 60 stylus `ZY22MC9B2M` (USB; the link drops now and then —
replug, keep unlocked, "File transfer"), signed in as admin with the latest build.
The Xiaomi is away. The emulator `Pixel_3A` can't do Google sign-in (Play services
22.50 from 2022, no Google account; updating it would touch the shared emulator).
When driving the emulator, check Royal Marble is in front before each tap (a stray
tap opened the Camera app on 2026-10-05).

**Known small issues:**
- On sign-out the old profile listener logs a harmless `permission-denied` (Wrapper's
  stream outlives the login for a moment); could be silenced.
- `firebase-functions` 6.x shows an "outdated" warning; upgrading has breaking
  changes — do it deliberately, not before a deploy.
- Build warns about the Kotlin Gradle Plugin (Firebase plugins); needs plugin updates
  before a future Flutter release.

**To start:** `cd functions && npm run emulators` (terminal 1), `npm run seed`, then
run the app with `--dart-define=USE_EMULATOR=true` (see section 4). Without that flag
the app talks to **production**.

**Waiting on the client:** payment; decisions in section 6 (esp. #2 auto check-out
rules and whether short absences are paid); native-speaker review of Arabic/Hindi/
Urdu; whether the "after every phone runs the new app" gates (assignment migration,
strict rules) still apply now that nobody uses the old app.

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

### Plans log
Newest first. Each plan: when, why, the steps, and decisions. Tick steps as they finish.

#### 2026-10-13 — Payroll approve and lock (Phase 6, part 2)
**Why:** before the Play Store update (the app is already on Google Play, so it ships as an
update), the user asked to finish H6 and add approving and locking each worker's monthly
pay, so approved pay can't change underneath the office.

**Decisions (user, 2026-10-13):** per worker (plus "Approve all ready"); HR or admin
approves; approved overtime is its own line on the payslip and part of the total, and
overtime still waiting must be approved or rejected first (Claude's reading of the
user's answer, told to the user); only a month that has ended can be approved; an
admin can reopen with a reason (kept), then HR re-approves.

- [x] **P1 Data + rules** (2026-10-13; both files dry-run compiled) — `payslips/{uid}_{m-yyyy}`: snapshot (package, rate, regular
      and overtime minutes and pay, total, days), `status` locked/reopened, who/when,
      `reopened` list (who, when, reason). Rules: HR/admin create locked; only an admin
      changes locked → reopened; nobody deletes; worker reads own by id. `overtime`
      writes refused while that worker's month is locked.
- [x] **P2 Server** (2026-10-13) — `correctAttendance` refuses days in a locked month
      (`reason: month_locked`), translated in the app.
- [x] **P3 Payroll screen** (2026-10-13) — status per worker (approved / ready / overtime waiting /
      no pay details), locked lines use the payslip numbers; payslip page (breakdown,
      Approve and lock, admin Reopen with reason); "Approve all ready"; Excel gets a
      Status column.
- [x] **P4 Other screens** (2026-10-13; reopen reasons hidden from the worker) — overtime and attendance correction show the month is
      locked and don't offer changes; My pay shows the worker's approved payslips.
- [x] **P5 Tests** (2026-10-13) — 8 unit tests (`test/payslip_test.dart`, 57 pass); 14
      emulator scenarios (48 pass): lock, refused correction/overtime, worker reads own only,
      HR can't reopen or edit a locked slip, nobody deletes, admin reopens, re-approve. Web
      on the emulators as HR and admin: approve one, Approve all ready, locked overtime and
      correction screens, reopen with reason, Excel (Status column, slip numbers), My pay's
      Approved pay. **Bugs fixed:** `setState(() => _x = future)` threw in debug builds
      (Payroll/Overtime month chips, HR home overtime count after leaving Overtime).
- [ ] **P6 Worker check on a phone** (with H6): My pay as Quiet Tester.
- [ ] **P7 Deploy (user)** — rules + `correctAttendance`, then hosting.

#### 2026-10-12 — HR role, pay earned so far, overtime approval (Phase 6, part 1)
**Why:** after checking the web dashboard against production the user asked for (1) a new
**HR** user who monitors timing, check-ins/outs and pay, (2) workers seeing **how much of
their pay they have earned so far**, from their pay package and set working hours
(e.g. 48 h/week), and (3) **overtime** (time after 5 PM) listed separately for HR to
**approve or reject**, paid at an **hourly overtime rate HR sets**. This answers part of
the client decisions for Phase 6 (#1 hours, #3 overtime, #7 who approves).

**Decisions (user, 2026-10-12, all the recommended options):**
- HR = attendance + pay: sees everyone's check-ins/outs and reports, can correct
  attendance, sets pay packages, working hours and overtime rates, approves/rejects
  overtime. Cannot approve sign-ups, manage sites or change roles (admin only). Uses
  the phone app and the web dashboard. Role key `isHR`.
- Earned so far = hourly rate × regular hours worked this month + approved overtime.
  Hourly rate = monthly total (basic + allowances) ÷ expected monthly hours
  (weekly hours × 52 ÷ 12; 48 h → 208 h). Shown to the worker (My pay) and to HR.
- Overtime = time checked in after the worker's day-end time (default 17:00) each day.
  Pending until HR approves or rejects; only approved overtime is paid.
- Overtime rate = per worker, AED per hour, on the pay package (set by HR/admin).

**Still open (ask the client later):** weekends/public holidays, days without a
check-out, daily/hourly pay types (planned: hourly uses basic as the rate; daily uses
basic ÷ (weekly hours ÷ 6)), whether allowances are pro-rated (planned: yes, inside
the hourly rate), what happens to overtime changed after approval (planned: flagged
for HR to re-check).

- [x] **H1 HR role** (2026-10-12) — `AppRole.hr` (`isHR`) with `managesPay`,
      `isTracked`, `inField` in `roles.dart` (HR: not tracked, no live map/alerts, left
      out of field lists); label in 4 languages; role chip (admins only can give HR or
      Admin); HR home (greeting + today's attendance; overtime/pay cards come in H4/H5);
      menu Users + Reports (corrections allowed); user page for HR viewers: Work + Pay
      (edit), no alerts, role, access or helper changes; web dashboard allows HR.
      Server: `correctAttendance` accepts HR (2 emulator scenarios, all pass); seed has
      `hr@test.local` ("Hana HR"). Rules (both files, dry-run compiled): `managesPay()`
      for `payroll`, new `overtime` collection (HR/admin write, worker reads own);
      strict: HR reads `users`. Checked on the web dashboard as HR (emulators).
      **Not deployed** (H7).
- [x] **H2 Pay settings** (2026-10-12) — `SalaryPackage.weeklyHours` (default 48),
      `dayEndMinutes` (default 17:00 = 1020), `overtimeRate` (per hour); old packages
      read with the defaults. Editor section "Working hours and overtime" (day end via
      the time wheel); summary line "48 h a week · day ends 17:00 · overtime AED 15 /
      hour". 2 unit tests (38 pass). Saved as HR on the emulators (rules allow it).
- [x] **H3 Calculation** (2026-10-12) — `lib/models/pay_calc.dart`: `hourlyRate`
      (monthly: total ÷ (weekly h × 52 ÷ 12); daily: basic ÷ (weekly h ÷ 6) +
      allowances/h; hourly: basic + allowances/h), `dayPay` (worked vs overtime =
      time after the day end, on the day the stay started; open stay today counts to
      now; a past stay never closed counts 0 until corrected), `paySoFar` (regular pay
      + approved overtime at the rate saved with the approval; changed-after-approval
      → pending), `OvertimeDecision` + `overtimeDocId` (`{uid}_{d-m-yyyy}`). 11 unit
      tests (`test/pay_calc_test.dart`). Time outside the site (lunch) is not
      deducted — client decision #2 still open.
- [x] **H4 Overtime review** (2026-10-12) — `lib/services/pay_service.dart` (days of a
      period from `time_sheet`, all packages, decisions by day range or by id, `decide`)
      and `lib/screens/overtime_screen.dart` (This month / Last month; Waiting /
      Approved / Rejected; worth at the worker's rate or "no overtime rate set";
      reject asks for an optional note; decided days can be switched; changed-after-
      decision flag). Menu "Overtime" for admin + HR; HR home card "Overtime waiting:
      N". Rule fix: workers read their own decision **by id** (a missing doc would be
      refused by a `resource.data` rule). Checked on the web as HR with emulator days
      (approve Ravi 1h30 → AED 22.5; reject Imran with a note).
      **Bug found and fixed:** dialogs that closed with the screen's context instead of
      their own closed the *page* inside the web sidebar layout (overtime reject,
      deleting a user, sign-out) — now use the dialog's context.
- [x] **H5 Earned so far** (2026-10-12) — `lib/widgets/earned_so_far.dart` (month so
      far: total, regular time, approved overtime, overtime waiting "not paid yet",
      rejected, hourly-rate note): top card in **My pay** (worker) and inside the pay
      card on the worker's page (HR/admin). `lib/screens/payroll_screen.dart` (menu
      "Payroll", admin + HR): everyone tracked with a package or attendance, this/last
      month, tap → worker page, Excel export (`payrollXlsx`, English). `money()` moved
      to `core/format.dart` (an import loop made the web dev server serve a stale
      module). Checked on the web as HR: Ravi AED 273.46 = 18 h × 13.94 + 1.5 h × 15,
      Excel matches. Worker access checked on the emulator with mason1's token: own
      decision 200, own undecided day 404, other's decision 403, writing own 403,
      other's pay 403.
- [ ] **H6 Tests** — done so far: 13 new unit tests (49 pass), 2 HR emulator scenarios
      (34 pass), rules dry-run (both files), all HR screens on the web dashboard, worker
      data access via REST. Production, admin on the Xiaomi (2026-10-13): Quiet Tester's
      pay card shows Earned so far AED 52.06 = 2h58m × 17.55 (3,650 ÷ 208) ✔. **Left:** My
      pay as the worker (needs the user to sign in as Quiet Tester).
- [ ] **H7 Deploy (user's approval)** — rules + `correctAttendance`; then the user
      makes an HR account (role picker) and tries it.

#### 2026-10-12 — Block C: admin web dashboard (detailed plan)
**Why:** the user chose Block C after Block A (it needs nothing from the client). Findings
before planning: `web/` exists and `flutter build web` already compiles (53 s); no
Firebase **web app** is registered (only Android/iOS); the app starts Firebase without
options (fine on phones, not on the web); Crashlytics, background tracking, push and
check-in are phone-only; photo upload and PDF/Excel export use `dart:io` files;
`firebase.json` hosting points at an old `public/` folder.

**Decisions (defaults, change if the user says so):** one codebase (the same app runs on
the web with `kIsWeb` guards, no second project); **admins only** on the web (others see
"use the phone app"); hosted at `royal-marble.web.app` (custom domain later); built and
tested against the local emulators first, production only at C5.

- [x] **C1 Web foundation** (2026-10-12) — `lib/core/web_config.dart` (web Firebase options
      from `WEB_API_KEY` / `WEB_APP_ID`, placeholders on the emulators; `MAPS_API_KEY_WEB`),
      Maps script loaded at start-up (`lib/core/web/maps_loader*.dart`), no
      Crashlytics/tracking/push on the web (`kIsWeb` guards in `main.dart`, services,
      `ErrorReporter`), admins-only gate in `Wrapper` (`_WebAdminsOnly`), no sign-up link
      on the web, Google sign-in by popup on the web, Apple check without `dart:io`, maps
      show `MapUnavailable` until a web key exists, new `web/index.html` (bootstrap, no
      service worker) and manifest. Verified headless in Chrome on the emulators: admin
      home loads with no errors; `mason1` gets the admins-only screen.
      Also fixed (phones too): `CircleAvatar` assertion when a person has no photo (5 places).
- [x] **C2 Wide layout** (2026-10-12) — `lib/widgets/web_shell.dart`: browser windows
      ≥ 1000 px get the menu as a permanent sidebar (`ProfileDrawer(onOpen:, current:)`,
      new "Dashboard" item, current page highlighted); pages open beside it in a nested
      navigator, content max 1200 px; menu pages replace each other (no back arrow),
      deeper pages keep one. Admin count tiles in one row of four. Narrow windows and
      phones unchanged (checked at 800 px). All 9 menu pages open with no errors.
      **Dropped:** tables instead of cards — the card lists read well at this width;
      revisit only if the user asks.
- [x] **C3 Screen fixes for the browser** (2026-10-12) — Excel export downloads in the
      browser (`save_launch_file.dart` now picks `_io` / `_web`; PDF already did via
      `printing`), both checked with real rows (emulator data from `test:checkin`); My
      profile photo works from bytes (`putData`, `MemoryImage`; no `dart:io`, phones
      too; the browser goes straight to its file chooser); time wheel works in the
      browser incl. mouse-wheel scrolling and the 12-hour AM/PM wheel. Google sign-in on
      the web is coded (popup) but can only be tested at C5 (needs the real web app).
      Not changed: sign-up (`register.dart`) still uses `dart:io` — not reachable on the
      web.
- [x] **C4 Test** (2026-10-12, local part) — every admin menu page opened in headless
      Chrome on the emulators with no errors (English); dashboard and Reports in Arabic
      (sidebar on the right, RTL correct); exports and the time wheel checked in C3.
      The read-only production check moves into C5 (it needs the real web app).
- [ ] **C5 Go live (user steps + one deploy)** — prepared 2026-10-12: `firebase.json`
      hosting now serves `build/web` (old `public/` placeholder removed). Steps:
      1. [x] (2026-10-12, by the user: "Royal Marble Web", appId `…:web:9a504f…`; keys in
         `config/env.json`) Register a Firebase **web app** (console → Project settings → Add app → Web,
         or `firebase apps:create web "Royal Marble dashboard"` with the user's OK);
         put its `apiKey` / `appId` in `config/env.json` as `WEB_API_KEY` / `WEB_APP_ID`.
      2. [x] (2026-10-12, by the user; restricted to the two Firebase domains + localhost;
         key in `config/env.json`) Google Cloud console: enable **Maps JavaScript API**; create a browser key
         restricted to that API and to `https://royal-marble.web.app/*`,
         `https://royal-marble.firebaseapp.com/*`, `http://localhost:*/*`; put it in
         `config/env.json` as `MAPS_API_KEY_WEB`.
      3. [x] (2026-10-12) `flutter build web --release --dart-define-from-file=config/env.json`
      4. [x] (2026-10-12: the user reports the website works like the app) Read-only check against production in Chrome (`flutter run -d chrome
         --dart-define-from-file=config/env.json`), signed in as admin.
      5. [x] (2026-10-12, by the user; new logo favicon live) `firebase deploy --only hosting --project royal-marble --account
         royalmarble.uae@gmail.com` (user's approval) → https://royal-marble.web.app
      **Found during step 4:** profile photos don't load in the browser (Firebase Storage
      blocks cross-site image downloads: bucket has no CORS rule) — fix pending, user to
      choose: CORS rule on the bucket (production setting) or a code workaround. Fixed:
      PDF exports dropped the "–" in date ranges (Helvetica has no glyph) → hyphens.
      6. [ ] Google sign-in on the live site (`royal-marble.web.app` and
         `firebaseapp.com` are authorised by default; check in Auth → Settings).

#### 2026-10-11 — Blocks A–D (finish the remaining phases)
**Why:** after the quiet-hours test the user asked to see the remaining phases and how
to divide them. Claude listed what's left per phase (Phases 2–8) and grouped the work
by what it waits on: nothing (testing, web dashboard), the user's store accounts
(release builds), or the client's answers (pay rules, rollout, translations). Blocks
that need nobody else go first. The user chose Block A first.

- **Block A — finish testing** (no client input; ~1 session) — ✅ **done 2026-10-11**
  - [x] Production attendance test with Quiet Tester on the emulator: far check-in
        refused, check-in, leave/return pushes, check-out with work sheet
  - [x] Admin correction (user, Xiaomi) — found future times allowed → fixed
  - [x] Salary: package set by the admin, visible in My pay (other-user check by rule
        reading only)
  - [ ] Auto check-out after 60 min — skipped (the correction closed the stay); optional
  - [ ] Real-phone walk out of a site — optional (emulator walk already worked)
  - [x] Cleanup — **decided: keep test data until go-live**, then delete (user)
  - Extra from the test: push token survived admin sign-out → fixed; the user asked
    for a scroll-wheel time picker instead of the clock dial → built.
- **Block B — store builds** (needs the user's Play Console / App Store Connect; ~1 session)
  - [ ] Small fixes first: `firebase-functions` upgrade, Kotlin/Gradle plugin warnings,
        sign-out `permission-denied` log, rotate/restrict Maps keys
  - [ ] Android release build (`royal-keystore.jks`), Play listing, location-privacy text
  - [ ] iOS TestFlight build + Sign in with Apple key (token revocation)
- **Block C — admin web dashboard** (no client input; ~2–3 sessions) — **suggested next**
  - [ ] Flutter web build of the app with admin screens only: live map, team status and
        alerts, attendance reports with corrections, users and sites
  - [ ] Wide-screen layout (side menu, tables instead of cards)
  - [ ] Firebase Hosting (one deploy, needs the user's approval)
- **Block D — after the client answers**
  - [ ] Phase 6 pay from worked hours (client decisions #1–7)
  - [ ] Phase 3 rollout once every phone runs the new app: migration dry run → apply →
        strict rules
  - [ ] Fixes from the native-speaker translation review (Phase 8)

Status 2026-10-12: Block A done and `correctAttendance` deployed; **the user chose Block C** (plan above).

#### 2026-10-01 — Current agenda (below)
**Why:** billing was expired and production frozen, so the agenda was work that needs no
deploys: localization, a local test backend, Phase 2+3 code, remaining screens, push,
tech debt, web dashboard. Items 1–5 are done or superseded by the Blocks plan above.

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
5. 🔄 **Phase 4 client side:** push wiring and new-sign-up notification live (2026-10-05); leaving-site etc. pushes next.
6. **Tech debt:** remove unused packages, iOS build prep.
7. **Admin web dashboard** (Flutter web), developed locally.

**Status key:** ⬜ not started · 🔄 in progress · ✅ done · ⛔ blocked

| Phase | Status | Blocked by |
|---|---|---|
| 1 Crashlytics | ✅ | — (open the Crashlytics page in the console once) |
| 2 Attendance correctness | 🔄 code ✅ | Functions deploy (billing); client decision #2 |
| 3 Multi-site + per-site hours | 🔄 code ✅ | Functions deploy; migration at rollout |
| 4 Leaving-site alerts + push | 🔄 | `left_site` alerts in-app; push live for new sign-ups; other alert pushes next |
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
- [x] Geofence exit/return verified on the emulator 2026-10-11 by feeding a walk of
      `geo fix` points (2 s apart). A real phone walk is still worth doing once.
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
- [x] Push wiring (2026-10-05): `firebase_messaging`, `lib/services/push_service.dart`
      (tokens for admins/supervisors, snack bar in the foreground, tap opens the
      screen), `functions/src/notify.ts` (`pushToUser`, `notifyNewUser`).
- [x] Background / closed-app delivery verified (Motorola locked 2026-10-05; iPhone
      swiped away 2026-10-08).
- [x] Check-in/out/switch, returned-to-site, permission-back-to-Always pushes;
      per-worker mutes per viewer (2026-10-08). Mute switches not yet tested live.
- [x] Cloud Function on `device_events` that pushes critical types (`left_site`,
      `silent`, `auto_checkout`) to admins and the site's supervisor.
- [x] Notification settings: per-kind switches, per-worker mutes, quiet hours (2026-10-09).

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
- [x] Verify on device (2026-10-11): admin set a package on the Xiaomi, Quiet Tester sees it
      in My pay. "Another user can't" checked by reading the deployed rule only (live read
      blocked by the permission check).

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
- **2026-10-05 (cont.)** — Registration: mobile limited to 05 + 8 digits, company
  fixed to "Royal Marble". SHA fingerprints added and new `google-services.json` in
  place; **Google sign-in works on a real phone** (Motorola edge 60 stylus,
  `ZY22MC9B2M`). Fixed: a first-time Google user was stuck on the spinner because
  `watchUser` waited for a server event that never comes when the profile is missing
  (now asks the server once). The emulator can't do Google sign-in (Play services
  22.50 from 2022, no Google account).
- **2026-10-05 (end of session)** — Push notifications started: `firebase_messaging`,
  `PushService` (tokens for admins/supervisors in `users/{uid}.fcmTokens`, removed on
  sign-out; foreground messages as a snack bar; tapping opens the user's admin page)
  and `notifyNewUser` (Firestore trigger on `users/{uid}` create). Deployed by Claude
  with the user's go-ahead (first try failed while Eventarc permissions propagated;
  retry after 4 min worked). Verified in the foreground on the Motorola: the user
  registered a test account and got the snack bar; function log "1 phone(s) of 3
  admin(s)". Background/closed-app delivery not yet verified. Paused by the user;
  plan in section 0.
- **2026-10-05 (afternoon)** — `notifyAlert` deployed (worker alerts → admins and
  same-site supervisors, 15-min throttle); tested first on the emulators (Test Villa
  leave → admin + supervisor; repeat throttled; info not pushed; Far Site → admin
  only). In production: test mason checked in at Test Site via `checkInOut`;
  switching the emulator's location off (user approved) sent "Location services
  turned OFF" to the locked Motorola as a system notification, and in the
  foreground as a snack bar whose "Details" opens the worker's page. Admin dashboard
  reworked per the user (counts that jump to lists of sign-ups, outside the site,
  phone problems, on site). Fixed the blank notification icon (white vector icon)
  and added a high-importance Alerts channel. An accidental `flutter run -d all`
  built macOS and rewrote `macos/` files — reverted; use explicit `-d` ids.
- **2026-10-07** — iOS set up and running on the user's iPhone ("Wiss", iOS 26.2,
  wireless): `ios/Runner/GoogleService-Info.plist` (iOS app already registered in
  Firebase), entitlements (push `aps-environment`, Sign in with Apple), background
  `remote-notification`, iOS 15 target, fresh `Podfile.lock`, static pods
  (Transistorsoft ships static xcframeworks). Google sign-in on iOS not possible
  yet: the iOS config has no CLIENT_ID (enable/regenerate in Firebase). APNs:
  Apple's 2-key limit was reached, so the existing team-scoped key `45J423HW4P`
  (Sandbox & Production) was uploaded to Firebase Cloud Messaging by the user.
  Test run on the emulator (mason) with admin on iPhone + Motorola: location off/on
  → push; battery saver → in-app only (no push, by design); check-in/out at Test
  Site OK; internet cut 04:50 → "silent" push at 05:11. After the APNs key both
  admin phones got the pushes ("2 phone(s)"). Pending: deploy of the notification
  switches + per-token failure logging (`526491c`); Sign in with Apple key for
  token revocation before App Store review; the emulator still has battery saver on.
- **2026-10-08** — The user deployed the functions (notification switches + per-token
  failure logging; Claude's deploy was blocked by the permission check, dry run was
  clean). Test: mason on the emulator checked in at Test Site 07:27, location off →
  `location_off` → "2 phone(s) of 3 recipient(s)", no token failures; **the iPhone got
  it with the app swiped away.** Tapping it showed a white screen: expected for an iOS
  debug build launched without Xcode/`flutter run`; re-check the tap on a release /
  TestFlight build. Emulator battery saver is off, location back on. The test mason is
  still checked in at Test Site (end-of-day auto check-out at 22:00 will close it).
- **2026-10-08 (cont.)** — Per the user: check-in, check-out and site switch now push
  (from `checkInOut`, not throttled), as do `returned_to_site` and permission back to
  "Always" (`permission_always`). All worker pushes go through `pushWorkerAlert`
  (`notify.ts`). New per-worker mutes on the worker's page, **per viewer** (user's
  choice): `users/{viewer}.notifyAbout.{workerUid}.{group}` with groups `checkInOut`,
  `presence` (left/returned/auto check-out), `location`, `connection` (silent),
  `phoneSettings`; missing = on (check-ins on by default, user's choice). Notifications
  screen got a global "Check-ins and check-outs" switch. 31 emulator scenarios pass.
  Functions deployed by the user. Live test: emulator mason checked out 08:40 →
  "check_out → 2 phone(s) of 3 recipient(s)"; the Motorola (app open) showed the
  snack bar, "Details" opened the worker's page. iPhone: two wireless launches failed
  ("mDNS query failed", debugger never attached), so the Motorola (USB) was used.
  Paused by the user before the mute test (plan in section 0).
- **2026-10-09** — Mute test done (user confirmed): `location_off` with Location muted →
  "0 phone(s) of 3 recipient(s)", nothing on iPhone or Motorola (both are the user's
  admin account; mutes are per account). Built: **unread alerts** — bell counts
  warning/critical alerts newer than `users/{viewer}.alertsSeenAt` (server time;
  compared with each event's `receivedAt`), opens on the Alerts tab, unseen rows tinted
  with a gold dot, opening the tab marks them seen, tapping an alert opens the worker.
  **Alert retention 3 days:** scheduled `pruneOldAlerts` (every 6 h, by `receivedAt`;
  emulator trigger `devPruneAlerts`) — dry run clean, **deploy pending (user runs it)**.
  **Admin home sites:** one "Active sites" section (projects + mock-ups): a lite map
  with every site (green = someone there; tap opens Live map) and compact rows sorted
  by who is there (● on site, ▲ outside), top 5 + "Show N more", "All sites" link;
  potential projects only on All sites (sales home keeps them as compact rows)
  (`lib/widgets/sites_overview.dart`). **Client details** show a map of the pin (tap →
  directions; `MapSnapshot` widget). **Live map worker sheet:** today's stays, phone
  grid (battery/charging, last report, internet, location, GPS accuracy, permission,
  precise, battery saver, tracking; red when bad), "Open profile". Avatars fall back
  quietly when the photo can't load (a DNS blip logged long traces). 24 strings ×
  4 languages; 33 tests pass; analyzer 16 old notes. Committed `1cfbc9f`.
- **2026-10-09 (cont.)** — **Quiet hours** (Phase 4 remainder): Notifications screen
  switch + From/To (default 22:00–07:00), saved as `users/{uid}.quietHours =
  {on, from, to, offsetMin}` (local minutes + the phone's UTC offset). `pushToUser`
  sends silently inside the window (Android channel `quiet`, IMPORTANCE_LOW, created
  in `MainActivity`; iOS `interruption-level: passive`), so alerts still land in the
  tray and the app. `inQuietHours` checked for overnight/daytime/off cases. Needs a
  functions deploy **and** a new app build (the channel). Server tests: 2 auto
  check-out checks fail only because they ran at 23:41 (known after-22:00 issue).
- **2026-10-09 (late)** — iOS: Maps key moved from `AppDelegate.swift` into a
  git-ignored `ios/Flutter/Secrets.xcconfig` (template `Secrets.example.xcconfig`)
  (`b2400ca`); Google sign-in client id and reversed URL scheme (`e37c666`).
- **2026-10-11** — Checked production: functions deployed by the user, `pruneOldAlerts`
  runs every 6 h (deleted 20, 14, then 0). No pushes since the deploy, so quiet hours
  are untested; no device connected.
- **2026-10-11 (cont.)** — New build on the Motorola: `alerts` (importance 4) and
  `quiet` (importance 2) channels present. Registered test worker "Quiet Tester" on
  the emulator (production); the user approved it. Quiet hours on for the user's admin
  account (22:00–07:00): `notifyNewUser` and then `location_off` (emulator location off
  at 06:37) both logged "quiet hours, sent silently" → 2 phone(s); the Motorola (app in
  background) showed "Quiet Tester — Location services turned OFF" on the `quiet`
  channel with no sound or vibration. In the foreground the push still shows as the
  snack bar. One stale admin token (`registration-token-not-registered`) is logged on
  each push; harmless.
- **2026-10-11 (cont.)** — Block A, production, Quiet Tester on the emulator, admin on the
  Xiaomi (`76031c77`): check-in from 18.6 km refused ("You are 18619 m outside the
  site"); check-in 07:02 → push; walking 1.3 km away (40 `geo fix` steps) → geofence
  exit → `left_site` push; walking back → `returned_to_site`; check-out with work sheet
  07:09 → push. Admin correction and salary done by the user; My pay shows the package.
  Auto check-out not tested (the correction closed that stay).
  **Fixed:** an admin's push token came back right after sign-out (stop() edits the
  profile → Wrapper rebuilds → start() saved it again), so a worker on that phone got
  the admin's alerts. `PushService` now ignores the signing-out user, and phones of
  people who don't get alerts delete their token once (the server drops it as dead on
  the next send) — verified: 4 → 3 phones, stray token removed.
  **Fixed:** a correction could set times later than now (user saved 07:11 → 10:09 at
  07:23). App and `correctAttendance` refuse it (`errFutureTime`, 4 languages); server
  scenario added (32 pass). Server part needs a deploy.
  **New:** scroll-wheel time picker (`lib/widgets/time_wheel_picker.dart`) replaces the
  Android clock dial in attendance correction, quiet hours and the visit time (user's
  request): big readout, hour/minute wheels, AM/PM on 12-hour phones, LTR in RTL
  languages. Checked on the Xiaomi; 3 widget tests; 36 app tests pass.
- **2026-10-12** — Per the user: every plan is now logged in section 6 "Plans log" (date,
  why, steps, decisions); added the Blocks A–D plan of 2026-10-11 and the 2026-10-01
  agenda's origin. Rule added to the top of this file.
  `correctAttendance` deploy confirmed in the logs (2026-10-11 07:36 local).
- **2026-10-12 (cont.)** — The user chose Block C. Web build checked (compiles); no Firebase
  web app yet. Plan C1–C5 logged in the Plans log. Starting C1.
- **2026-10-12 (cont.)** — C1 done (see Plans log). How to run the web dashboard locally:
  `cd functions && npm run emulators`, `npm run seed`, then `flutter run -d chrome
  --dart-define-from-file=config/env.json --dart-define=USE_EMULATOR=true` (or `-d
  web-server --web-port 8099`). Claude drives it with headless Chrome (puppeteer-core in
  the session scratchpad, not in the repo). Note for scripted tests: puppeteer's
  `keyboard.press('Enter')` adds a stray character in Flutter text fields; send a raw
  Enter or click the button. Next: C2 wide layout.
- **2026-10-12 (cont.)** — C2 done (sidebar shell, see Plans log). Headless testing note:
  start each run with a fresh browser profile — a saved Firebase session is restored
  before the app switches to the emulators and goes to Google's real endpoint with the
  placeholder key (refused; no data reached). Next: C3 browser fixes (exports, photo
  upload, Google sign-in).
- **2026-10-12 (cont.)** — C3 done (exports, profile photo, wheel in the browser). Next: C4.
- **2026-10-12 (cont.)** — C4 local tests done (English + Arabic). C5 prepared: hosting serves
  `build/web`, old `public/` placeholder removed. Waiting on the user for the Firebase web
  app and a web Maps key (C5 steps 1–2).
- **2026-10-12 (cont.)** — User registered the Firebase web app and created the web Maps key;
  production check running in Chrome. Found: profile photos blocked in the browser (no
  CORS on the Storage bucket); PDF "–" missing (fixed).
- **2026-10-12 (cont.)** — User: the website works like the app. New request: HR role, pay
  earned so far, overtime approval with HR-set hourly rate. Decisions taken (all
  recommended options); plan H1–H7 logged. Starting H1.
- **2026-10-12 (cont.)** — H1 done (HR role). Next: H2 pay settings (weekly hours, day end,
  overtime rate).
- **2026-10-12 (cont.)** — H2 done (working hours and overtime rate on the pay package).
  Next: H3 calculation.
- **2026-10-12 (cont.)** — H3 done (pay calculation + tests). Next: H4 overtime review.
- **2026-10-12 (cont.)** — H4 done (overtime review). Next: H5 earned-so-far card + month list.
- **2026-10-12 (cont.)** — H5 done (earned so far, payroll list + Excel). H6 mostly done.
  Next: H7 deploy (rules, `correctAttendance`, hosting) with the user's go-ahead.
- **2026-10-12 (cont.)** — Web favicon and PWA icons (`web/favicon.png`, `web/icons/*`)
  replaced with the app's logo (from the iOS 1024 icon; maskable ones padded for the safe
  zone) and copied into `build/web`. Hosting dry run clean; deploy pending (user runs it).
- **2026-10-13** — Checked: hosting is live (site favicon matches the new logo). Phase 6
  part 1 left: H7 rules + `correctAttendance` deploy (not confirmed yet), then H6 My pay on
  a phone, HR account test; C5 step 6 Google sign-in on the live site; photo CORS.
- **2026-10-13 (cont.)** — User deployed rules + `correctAttendance` (H7 deploy part;
  `correctAttendance` seen in `functions:list`). Icons committed. Next: H6 My pay as a
  worker on a phone, HR account test by the user.
- **2026-10-13 (cont.)** — Current build on the Xiaomi (debug, over the old one; admin
  still signed in). Admin view of Quiet Tester's pay on production correct (AED 52.06).
  Worker My pay check waits on the user signing in as Quiet Tester.
- **2026-10-13 (cont.)** — Plan "Payroll approve and lock" (P1–P7) logged; P1–P5 done
  (see Plans log). Not deployed. Next: P7 deploy (rules + `correctAttendance` + hosting, user
  runs it), then P6/H6 worker check on the Xiaomi as Quiet Tester, then Block B (Play Store
  update: the app is already on Google Play).
