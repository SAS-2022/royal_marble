/* eslint-disable no-console */
/**
 * Seeds the LOCAL Firebase emulators with test users, sites and pay data.
 *
 *   firebase emulators:start --project royal-marble        (terminal 1)
 *   cd functions && npm run seed                            (terminal 2)
 *
 * Refuses to run unless both emulator hosts are set, so it can never write to
 * the production project.
 */
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error("Refusing to seed: FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST " +
    "must point at the local emulators (npm run seed sets them).");
  process.exit(1);
}

initializeApp({ projectId: "royal-marble" });
const auth = getAuth();
const db = getFirestore();

const PASSWORD = "test1234";

// Dubai Marina; put the emulator here with: adb emu geo fix 55.1400 25.0800
const MARINA = { Lat: 25.0800, Lng: 55.1400, addressName: "Test Villa, Dubai Marina, Dubai" };
// ~70 m from Test Villa, so a worker standing there is inside both sites.
const TOWER = { Lat: 25.0805, Lng: 55.1405, addressName: "Marina Tower, Dubai Marina, Dubai" };
const FAR = { Lat: 25.2700, Lng: 55.3300, addressName: "Far Site, Deira, Dubai" };

const site = (id, name, address, radius) => ({ id, name, projectAddress: address, radius });

async function user(email, data) {
  let rec;
  try {
    rec = await auth.getUserByEmail(email);
  } catch {
    rec = await auth.createUser({ email, password: PASSWORD, emailVerified: true });
  }
  await db.collection("users").doc(rec.uid).set({
    emailAddress: email,
    company: "Royal Marble",
    phoneNumber: "0500000000",
    isActive: true,
    ...data,
  });
  return rec.uid;
}

async function main() {
  // Start every run from a clean attendance and alert slate (emulator only).
  for (const col of ["time_sheet", "device_events"]) {
    const docs = await db.collection(col).listDocuments();
    await Promise.all(docs.map((d) => d.delete()));
  }

  const admin = await user("admin@test.local",
    { firstName: "Test", lastName: "Admin", roles: ["isAdmin"] });
  const supervisor = await user("supervisor@test.local",
    { firstName: "Sam", lastName: "Supervisor", roles: ["isSupervisor"],
      assignedProject: [site("p_marina", "Test Villa", MARINA, 150)] });
  // mason1 uses the list shape (new app), mason2 the single map older
  // versions wrote, so both stay covered.
  const mason1 = await user("mason1@test.local",
    { firstName: "Ravi", lastName: "Mason", roles: ["isNormalUser"],
      assignedProject: [site("p_marina", "Test Villa", MARINA, 150),
        site("p_tower", "Marina Tower", TOWER, 150)],
      assignedMockup: [site("m_marina", "Marina Mock-up", MARINA, 150)] });
  const mason2 = await user("mason2@test.local",
    { firstName: "Imran", lastName: "Mason", roles: ["isNormalUser"],
      assignedProject: site("p_far", "Far Site", FAR, 150) });
  await user("pending@test.local",
    { firstName: "New", lastName: "Applicant", roles: ["isNormalUser"], isActive: false });

  const project = (name, address, workers) => ({
    projectName: name, projectDetails: "Emulator test site", selectedAddress: address,
    radius: 150, contractor: "Test Contractor", contactPerson: "Site Contact",
    phoneNumber: { phoneNumber: "+971500000000", isoCode: "AE", dialCode: "+971" },
    emailAddress: "site@test.local", projectStatus: "active", assignedWorkers: workers,
  });
  await db.collection("projects").doc("p_marina").set(project("Test Villa", MARINA, [supervisor, mason1]));
  await db.collection("projects").doc("p_tower").set(project("Marina Tower", TOWER, [mason1]));
  await db.collection("projects").doc("p_far").set(project("Far Site", FAR, [mason2]));
  await db.collection("mockup").doc("m_marina").set({
    name: "Marina Mock-up", details: "Emulator test mock-up", address: MARINA, radius: 150,
    contractor: "Test Contractor", contactPerson: "Site Contact",
    phoneNumber: { phoneNumber: "+971500000000", isoCode: "AE", dialCode: "+971" },
    emailAddress: "site@test.local", status: "active", assignedWorkers: [mason1],
  });

  await db.collection("payroll").doc(mason1).set({
    currency: "AED", payType: "monthly", basic: 1800, housing: 500, transport: 200, food: 300,
    other: [{ name: "Overtime meals", amount: 100 }],
    effectiveFrom: Timestamp.fromDate(new Date("2026-01-01")),
    notes: "Seeded for emulator testing", updatedAt: Timestamp.now(), updatedBy: admin,
  });

  console.log(`Seeded. Password for every account: ${PASSWORD}`);
  console.log("  admin@test.local, supervisor@test.local, mason1@test.local (Test Villa + Marina Tower),");
  console.log("  mason2@test.local (assigned to Far Site), pending@test.local (inactive)");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
