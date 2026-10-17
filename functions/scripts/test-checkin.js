/* eslint-disable no-console */
/**
 * End-to-end checks for the attendance functions (checkInOut, reportPresence,
 * auto check-out, correctAttendance) and the pay/leave security rules against
 * the LOCAL emulators.
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

/** Firestore REST as a signed-in user, so the security rules apply. */
const FS = "http://127.0.0.1:8080/v1/projects/royal-marble/databases/(default)/documents";
const fsValue = (v) => {
  if (v === null) return { nullValue: null };
  if (typeof v === "number") return { integerValue: String(v) };
  if (typeof v === "boolean") return { booleanValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(fsValue) } };
  if (typeof v === "object") {
    return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, fsValue(x)])) } };
  }
  return { stringValue: String(v) };
};
async function fsReq(method, idToken, path, fields, mask) {
  const q = mask ? "?" + mask.map((f) => `updateMask.fieldPaths=${f}`).join("&") : "";
  const r = await fetch(`${FS}/${path}${q}`, {
    method,
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${idToken}` },
    body: fields ? JSON.stringify({ fields: Object.fromEntries(
      Object.entries(fields).map(([k, v]) => [k, fsValue(v)])) }) : undefined,
  });
  return r.status;
}

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
  // The payroll checks below end with this month locked; unlock it for a rerun.
  const today = new Date();
  await db.collection("payslips")
    .doc(`${await uidOf("mason2@test.local")}_${today.getMonth() + 1}-${today.getFullYear()}`).delete();

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
    in: localStamp(0, 10), out: localStamp(0, 40), from: 0 }];
  expect("a worker can't correct attendance",
    await correct(m1, { day: dayId(), uid: m2Id, sessions: fixed }), { error: "not_admin" });
  expect("overlapping sessions are rejected",
    await correct(admin, { day: dayId(), uid: m2Id, sessions: [...fixed,
      { siteId: "p_far", siteKind: "project", siteName: "Far Site", in: localStamp(0, 30), out: localStamp(0, 50) }] }),
    { error: "bad_sessions" });
  expect("a check-out later than now is rejected",
    await correct(admin, { day: dayId(), uid: m2Id, sessions: [{ ...fixed[0], out: localStamp(23, 59) }] }),
    { error: "bad_sessions" });
  expect("an admin can fix the times",
    await correct(admin, { day: dayId(), uid: m2Id, sessions: fixed, note: "Forgot to check out" }),
    { ok: "saved" });
  e = await entryOf(m2Id);
  expect("the fix is applied and the previous version kept",
    [e.leaving_at, e.sessions[0].corrected, e.sessions[0].auto, e.corrections.length,
      e.corrections[0].note, e.corrections[0].before[0].auto, !!e.reviewed],
    [localStamp(0, 40), true, "end_of_day", 1, "Forgot to check out", "end_of_day", true]);

  // ── HR correction ──
  const hr = await token("hr@test.local");
  expect("HR can correct attendance too",
    await correct(hr, { day: dayId(), uid: m2Id, note: "HR check",
      sessions: [{ ...fixed[0], out: localStamp(0, 45) }] }),
    { ok: "saved" });
  e = await entryOf(m2Id);
  expect("HR's fix is applied and recorded with their name",
    [e.leaving_at, e.corrections.length, e.corrections[1].byName], [localStamp(0, 45), 2, "Hana HR"]);

  // ── Payroll lock ──
  const adm = await token("admin@test.local");
  const now = new Date();
  const slipId = `${m2Id}_${now.getMonth() + 1}-${now.getFullYear()}`;
  const slip = { uid: m2Id, name: "Mason Two", year: now.getFullYear(), month: now.getMonth() + 1,
    status: "locked", total: 100 };
  await db.collection("payslips").doc(slipId).delete();
  expect("HR can approve and lock a worker's month",
    await fsReq("PATCH", hr, `payslips/${slipId}`, slip), 200);
  expect("a correction in a locked month is refused",
    await correct(hr, { day: dayId(), uid: m2Id, note: "late fix",
      sessions: [{ ...fixed[0], out: localStamp(0, 50) }] }),
    { error: "month_locked" });
  const otId = `${m2Id}_${dayId()}`;
  expect("an overtime decision in a locked month is refused",
    await fsReq("PATCH", hr, `overtime/${otId}`, { uid: m2Id, status: "approved", minutes: 30 }), 403);
  expect("the worker reads their own payslip",
    await fsReq("GET", m2, `payslips/${slipId}`), 200);
  expect("another worker can't read it",
    await fsReq("GET", m1, `payslips/${slipId}`), 403);
  expect("a worker can't approve pay",
    await fsReq("PATCH", m1, `payslips/${await uidOf("mason1@test.local")}_1-2000`,
      { ...slip, uid: await uidOf("mason1@test.local") }), 403);
  expect("HR can't reopen a locked month",
    await fsReq("PATCH", hr, `payslips/${slipId}`, { ...slip, status: "reopened" }), 403);
  expect("HR can't change a locked payslip's numbers",
    await fsReq("PATCH", hr, `payslips/${slipId}`, { ...slip, total: 999 }), 403);
  expect("nobody deletes a payslip (admin)",
    await fsReq("DELETE", adm, `payslips/${slipId}`), 403);
  expect("an admin reopens it",
    await fsReq("PATCH", adm, `payslips/${slipId}`, { status: "reopened", uid: m2Id }, ["status", "uid"]), 200);
  expect("once reopened, corrections work again",
    await correct(hr, { day: dayId(), uid: m2Id, note: "late fix",
      sessions: [{ ...fixed[0], out: localStamp(0, 50) }] }),
    { ok: "saved" });
  expect("and overtime decisions too",
    await fsReq("PATCH", hr, `overtime/${otId}`, { uid: m2Id, status: "approved", minutes: 30 }), 200);
  expect("HR approves it again",
    await fsReq("PATCH", hr, `payslips/${slipId}`, slip), 200);
  expect("a decision for another worker's id is refused",
    await fsReq("PATCH", hr, `overtime/${otId}x`, { uid: "someone_else", status: "approved" }), 403);

  // ── Leave requests ──
  const leaveIds = ["l_annual", "l_other", "l_approved", "l_sick_none", "l_sick", "l_sick_theirs",
    "l_long", "l_hr", "l_locked", "l_no_travel_answer", "l_travel_blank", "l_travel", "l_sick_two",
    "l_sick_six"];
  await Promise.all(leaveIds.map((id) => db.collection("leave_requests").doc(id).delete()));
  // 2–4 March 2001 (local midnight); far from any payslip the tests lock.
  const day = (y, m, d) => new Date(y, m - 1, d);
  const leave = (extra = {}) => ({ uid: m1Id, name: "Mason One", type: "annual",
    from: day(2001, 3, 2), to: day(2001, 3, 4), days: 3, months: ["3-2001"], reason: "",
    reports: [], travel: null, status: "pending", paid: false, ...extra });
  expect("a worker asks for their own leave",
    await fsReq("PATCH", m1, "leave_requests/l_annual", leave()), 200);
  expect("not for someone else",
    await fsReq("PATCH", m1, "leave_requests/l_other", leave({ uid: m2Id })), 403);
  expect("not already approved",
    await fsReq("PATCH", m1, "leave_requests/l_approved", leave({ status: "approved" })), 403);
  expect("sick leave without a report is refused",
    await fsReq("PATCH", m1, "leave_requests/l_sick_none", leave({ type: "sick" })), 403);
  const report = (uid, i = 0) => ({ path: `leave_reports/${uid}/1_${i}_report.pdf`, name: "report.pdf",
    contentType: "application/pdf" });
  const reports = (n, uid = m1Id) => Array.from({ length: n }, (_, i) => report(uid, i));
  expect("sick leave with their own report",
    await fsReq("PATCH", m1, "leave_requests/l_sick", leave({ type: "sick", reports: reports(1) })), 200);
  expect("sick leave with two files",
    await fsReq("PATCH", m1, "leave_requests/l_sick_two", leave({ type: "sick", reports: reports(2) })), 200);
  expect("not more than five files",
    await fsReq("PATCH", m1, "leave_requests/l_sick_six", leave({ type: "sick", reports: reports(6) })), 403);
  expect("not with a report from another worker's folder",
    await fsReq("PATCH", m1, "leave_requests/l_sick_theirs",
      leave({ type: "sick", reports: [report(m1Id), report(m2Id, 1)] })), 403);
  const { travel: _omit, ...noTravelAnswer } = leave();
  expect("annual leave must answer the travel question",
    await fsReq("PATCH", m1, "leave_requests/l_no_travel_answer", noTravelAnswer), 403);
  expect("travel needs from and to",
    await fsReq("PATCH", m1, "leave_requests/l_travel_blank",
      leave({ travel: { from: "", to: "Kathmandu", companyTicket: true } })), 403);
  expect("annual leave with travel details",
    await fsReq("PATCH", m1, "leave_requests/l_travel",
      leave({ from: day(2001, 3, 10), to: day(2001, 3, 12),
        travel: { from: "Dubai", to: "Kathmandu", companyTicket: true } })), 200);
  expect("more than 60 days is refused",
    await fsReq("PATCH", m1, "leave_requests/l_long",
      leave({ to: day(2001, 5, 2), months: ["3-2001", "4-2001", "5-2001"] })), 403);
  expect("the worker reads their own request",
    await fsReq("GET", m1, "leave_requests/l_annual"), 200);
  expect("another worker can't",
    await fsReq("GET", m2, "leave_requests/l_annual"), 403);
  expect("HR can",
    await fsReq("GET", hr, "leave_requests/l_annual"), 200);
  expect("a worker can't approve their own leave",
    await fsReq("PATCH", m1, "leave_requests/l_annual", { status: "approved" }, ["status"]), 403);
  expect("HR approves it as paid",
    await fsReq("PATCH", hr, "leave_requests/l_annual",
      { status: "approved", paid: true, byName: "Hana HR" }, ["status", "paid", "byName"]), 200);
  expect("the worker can't cancel approved leave",
    await fsReq("PATCH", m1, "leave_requests/l_annual", { status: "cancelled" }, ["status"]), 403);
  expect("the worker cancels a pending one",
    await fsReq("PATCH", m1, "leave_requests/l_sick", { status: "cancelled", at: new Date() },
      ["status", "at"]), 200);
  expect("HR records leave for a worker",
    await fsReq("PATCH", hr, "leave_requests/l_hr", leave({ status: "approved", paid: false })), 200);
  // Mason Two's current month was approved and locked above.
  expect("no leave in a locked month",
    await fsReq("PATCH", hr, "leave_requests/l_locked", leave({ uid: m2Id, from: day(now.getFullYear(),
      now.getMonth() + 1, 1), to: day(now.getFullYear(), now.getMonth() + 1, 1),
    months: [`${now.getMonth() + 1}-${now.getFullYear()}`] })), 403);
  expect("nobody deletes a leave request (admin)",
    await fsReq("DELETE", adm, "leave_requests/l_annual"), 403);

  // Hospital reports in Storage.
  const ST = "http://127.0.0.1:9199/v0/b/royal-marble.appspot.com/o";
  // Multipart on the Firebase API, as the SDK sends it: a plain POST arrives
  // without a content type, and the GCS-style /upload API skips the rules.
  const upload = async (idToken, path, type = "application/pdf") => {
    const meta = JSON.stringify({ name: path, contentType: type });
    const body = `--B\r\nContent-Type: application/json\r\n\r\n${meta}\r\n` +
      `--B\r\nContent-Type: ${type}\r\n\r\n%PDF-1.4 test\r\n--B--`;
    return (await fetch(`${ST}?name=${encodeURIComponent(path)}`, { method: "POST", body,
      headers: { "Content-Type": "multipart/related; boundary=B", "X-Goog-Upload-Protocol": "multipart",
        Authorization: `Firebase ${idToken}` },
    })).status;
  };
  const read = async (idToken, path) => (await fetch(`${ST}/${encodeURIComponent(path)}`,
    { headers: { Authorization: `Firebase ${idToken}` } })).status;
  const own = `leave_reports/${m1Id}/${Date.now()}_report.pdf`;
  expect("a worker uploads their own report", await upload(m1, own), 200);
  expect("not into another worker's folder",
    await upload(m1, `leave_reports/${m2Id}/${Date.now()}_x.pdf`), 403);
  expect("only images or PDFs",
    await upload(m1, `leave_reports/${m1Id}/${Date.now()}_x.txt`, "text/plain"), 403);
  expect("it can't be replaced", await upload(m1, own), 403);
  expect("the worker reads it", await read(m1, own), 200);
  expect("HR reads it", await read(hr, own), 200);
  expect("another worker can't", await read(m2, own), 403);

  console.log(failures ? `\n${failures} check(s) failed` : "\nAll checks passed");
  process.exit(failures ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
