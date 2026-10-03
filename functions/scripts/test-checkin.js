/* eslint-disable no-console */
/**
 * End-to-end checks for the attendance functions (checkInOut, reportPresence,
 * auto check-out, correctAttendance) against the LOCAL emulators.
 * Run after `npm run emulators`:  npm run test:checkin  (re-seeds first)
 */
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error("Refusing to run: FIRESTORE_EMULATOR_HOST must point at the emulator.");
  process.exit(1);
}
initializeApp({ projectId: "royal-marble" });
const db = getFirestore();

const AUTH = "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake";
const FN_BASE = "http://127.0.0.1:5001/royal-marble/us-central1";
const OFFSET = -new Date().getTimezoneOffset();

const MARINA = { lat: 25.0800, lng: 55.1400 };
const FAR = { lat: 25.2700, lng: 55.3300 };

async function token(email) {
  const r = await fetch(AUTH, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test1234", returnSecureToken: true }),
  });
  const j = await r.json();
  if (!j.idToken) throw new Error(`sign-in failed for ${email}: ${JSON.stringify(j)}`);
  return j.idToken;
}

async function callFn(name, idToken, data) {
  const r = await fetch(`${FN_BASE}/${name}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${idToken}` },
    body: JSON.stringify({ data: { utcOffsetMinutes: OFFSET, mock: false, accuracy: 10, ...data } }),
  });
  const j = await r.json();
  return j.error ? { error: j.error.details?.reason ?? j.error.status } : { ok: j.result.status };
}
const call = (idToken, data) => callFn("checkInOut", idToken, data);
const presence = (idToken, data) => callFn("reportPresence", idToken, { kind: "project", ...data });
const correct = (idToken, data) => callFn("correctAttendance", idToken, data);

/** Runs the scheduled auto check-out as if it were [at]. */
async function autoCheckoutAt(at) {
  const r = await fetch(`${FN_BASE}/devRunAutoCheckout?now=${encodeURIComponent(at.toISOString())}`);
  return (await r.json()).closed;
}

const dayId = (d = new Date()) => `${d.getDate()}-${d.getMonth() + 1}-${d.getFullYear()}`;
async function entryOf(uid) {
  return (await db.collection("time_sheet").doc(dayId()).get()).data()?.[uid];
}
async function uidOf(email) {
  const snap = await db.collection("users").where("emailAddress", "==", email).get();
  return snap.docs[0].id;
}
const pad = (n) => String(n).padStart(2, "0");
const localStamp = (h, m) => {
  const d = new Date();
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(h)}:${pad(m)}:00.000`;
};

let failures = 0;
function expect(name, got, want) {
  const pass = JSON.stringify(got) === JSON.stringify(want);
  if (!pass) failures++;
  console.log(`${pass ? "PASS" : "FAIL"}  ${name}${pass ? "" : `\n      got  ${JSON.stringify(got)}\n      want ${JSON.stringify(want)}`}`);
}

async function main() {
  const m1 = await token("mason1@test.local");
  const m2 = await token("mason2@test.local");
  const pending = await token("pending@test.local");
  const at = (pos, extra = {}) => ({ kind: "project", ...pos, ...extra });

  expect("outside the radius is rejected",
    await call(m1, { action: "in", siteId: "p_marina", ...at({ lat: 25.0900, lng: 55.1400 }) }),
    { error: "out_of_range" });
  expect("unassigned site is rejected",
    await call(m1, { action: "in", siteId: "p_far", ...at(FAR) }), { error: "not_assigned" });
  expect("fake GPS is rejected",
    await call(m1, { action: "in", siteId: "p_marina", ...at(MARINA), mock: true }),
    { error: "mock_location" });
  expect("weak GPS is rejected",
    await call(m1, { action: "in", siteId: "p_marina", ...at(MARINA), accuracy: 80 }),
    { error: "weak_gps" });
  expect("check-out before check-in is rejected",
    await call(m1, { action: "out", siteId: "p_marina", ...at(MARINA) }), { error: "not_checked_in" });
  expect("check-in inside the site works",
    await call(m1, { action: "in", siteId: "p_marina", ...at(MARINA) }), { ok: "checked_in" });
  expect("second check-in is rejected",
    await call(m1, { action: "in", siteId: "p_marina", ...at(MARINA) }), { error: "already_checked_in" });
  expect("check-in at another assigned site while on site is rejected",
    await call(m1, { action: "in", siteId: "m_marina", kind: "mockup", ...MARINA }),
    { error: "already_checked_in" });
  expect("check-out works",
    await call(m1, { action: "out", siteId: "p_marina", ...at(MARINA), workType: "Installing Tiles", squareMeters: 12 }),
    { ok: "checked_out" });
  expect("assigned mock-up check-in works",
    await call(m1, { action: "in", siteId: "m_marina", kind: "mockup", ...MARINA }), { ok: "checked_in" });
  expect("another mason at their own site works",
    await call(m2, { action: "in", siteId: "p_far", ...at(FAR) }), { ok: "checked_in" });
  expect("inactive account is rejected",
    await call(pending, { action: "in", siteId: "p_marina", ...at(MARINA) }), { error: "not_active" });

  // ── Several sites a day (Phase 3) ──
  const m1Id = await uidOf("mason1@test.local");
  const m2Id = await uidOf("mason2@test.local");
  expect("switching to another assigned site closes the open session",
    await call(m1, { action: "in", siteId: "p_marina", ...at(MARINA), switchSite: true,
      workType: "Installing System", squareMeters: 4 }), { ok: "switched" });
  let e = await entryOf(m1Id);
  expect("the day holds one session per stay, one of them open",
    e.sessions.map((s) => [s.siteId, !!s.out]),
    [["p_marina", true], ["m_marina", true], ["p_marina", false]]);
  expect("the switched-away session keeps its work report",
    [e.sessions[1].switched, e.sessions[1].work?.workType], [true, "Installing System"]);
  expect("legacy fields follow the open session",
    [e.projectId, e.isOnSite, e.leaving_at, e.arriving_at === e.sessions[0].in],
    ["p_marina", true, null, true]);

  // ── Presence while checked in (Phase 2) ──
  expect("an enter right after check-in is ignored",
    await presence(m1, { siteId: "p_marina", transition: "enter" }), { ok: "ignored" });
  expect("leaving the site is recorded",
    await presence(m1, { siteId: "p_marina", transition: "exit", ...MARINA }), { ok: "recorded" });
  expect("a repeated exit is ignored",
    await presence(m1, { siteId: "p_marina", transition: "exit" }), { ok: "ignored" });
  expect("coming back is recorded",
    await presence(m1, { siteId: "p_marina", transition: "enter" }), { ok: "recorded" });
  expect("a geofence for a site the worker isn't checked in at is ignored",
    await presence(m1, { siteId: "m_marina", kind: "mockup", transition: "exit" }), { ok: "ignored" });
  expect("a faked position is ignored",
    await presence(m1, { siteId: "p_marina", transition: "exit", mock: true }), { ok: "ignored" });
  const alerts = await db.collection("device_events").where("uid", "==", m1Id).get();
  const types = alerts.docs.map((d) => d.get("type"));
  expect("admins get left-site and returned alerts",
    [types.includes("left_site"), types.includes("returned_to_site")], [true, true]);

  // ── Auto check-out ──
  const exitAt = new Date();
  expect("leaving again is recorded",
    await presence(m1, { siteId: "p_marina", transition: "exit", at: exitAt.toISOString() }),
    { ok: "recorded" });
  await autoCheckoutAt(new Date(exitAt.getTime() + 30 * 60_000));
  e = await entryOf(m1Id);
  expect("30 min away keeps the session open", e.isOnSite, true);
  await autoCheckoutAt(new Date(exitAt.getTime() + 61 * 60_000));
  e = await entryOf(m1Id);
  const last = e.sessions[e.sessions.length - 1];
  expect("over an hour away closes it at the exit time",
    [e.isOnSite, last.auto, Math.abs(last.outTs.toMillis() - exitAt.getTime()) < 2000, e.autoCheckout],
    [false, "left_site", true, true]);

  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(2, 0, 0, 0);
  await autoCheckoutAt(tomorrow);
  e = await entryOf(m2Id);
  expect("a session still open after the day ends is closed for review",
    [e.isOnSite, e.sessions[0].auto, !!e.leaving_at], [false, "end_of_day", true]);

  // ── Admin correction ──
  const admin = await token("admin@test.local");
  const fixed = [{ siteId: "p_far", siteKind: "project", siteName: "Far Site",
    in: localStamp(7, 0), out: localStamp(16, 30), from: 0 }];
  expect("a worker can't correct attendance",
    await correct(m1, { day: dayId(), uid: m2Id, sessions: fixed }), { error: "not_admin" });
  expect("overlapping sessions are rejected",
    await correct(admin, { day: dayId(), uid: m2Id, sessions: [...fixed,
      { siteId: "p_far", siteKind: "project", siteName: "Far Site", in: localStamp(16, 0), out: localStamp(17, 0) }] }),
    { error: "bad_sessions" });
  expect("an admin can fix the times",
    await correct(admin, { day: dayId(), uid: m2Id, sessions: fixed, note: "Forgot to check out" }),
    { ok: "saved" });
  e = await entryOf(m2Id);
  expect("the fix is applied and the previous version kept",
    [e.leaving_at, e.sessions[0].corrected, e.sessions[0].auto, e.corrections.length,
      e.corrections[0].note, e.corrections[0].before[0].auto, !!e.reviewed],
    [localStamp(16, 30), true, "end_of_day", 1, "Forgot to check out", "end_of_day", true]);

  console.log(failures ? `\n${failures} check(s) failed` : "\nAll checks passed");
  process.exit(failures ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
