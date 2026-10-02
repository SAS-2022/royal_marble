/* eslint-disable no-console */
/**
 * End-to-end checks for the checkInOut callable against the LOCAL emulators.
 * Run after `npm run emulators` and `npm run seed`:  npm run test:checkin
 */
const AUTH = "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake";
const FN = "http://127.0.0.1:5001/royal-marble/us-central1/checkInOut";

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

async function call(idToken, data) {
  const r = await fetch(FN, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${idToken}` },
    body: JSON.stringify({ data: { utcOffsetMinutes: -new Date().getTimezoneOffset(),
      mock: false, accuracy: 10, ...data } }),
  });
  const j = await r.json();
  return j.error ? { error: j.error.details?.reason ?? j.error.status } : { ok: j.result.status };
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

  console.log(failures ? `\n${failures} check(s) failed` : "\nAll checks passed");
  process.exit(failures ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
