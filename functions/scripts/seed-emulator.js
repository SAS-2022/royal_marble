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
  for (const col of ["time_sheet", "device_events", "helper"]) {
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
  await db.collection("helper").doc("h_suresh").set(
    { firstName: "Suresh", lastName: "Kumar", mobileNumber: "0501112233" });
  await db.collection("helper").doc("h_anil").set(
    { firstName: "Anil", lastName: "Verma", mobileNumber: "0504445566" });

  const mason1 = await user("mason1@test.local",
    { firstName: "Ravi", lastName: "Mason", roles: ["isNormalUser"],
      assignedProject: [site("p_marina", "Test Villa", MARINA, 150),
        site("p_tower", "Marina Tower", TOWER, 150)],
      assignedMockup: [site("m_marina", "Marina Mock-up", MARINA, 150)],
      assignedHelpers: ["h_suresh"] });
  const mason2 = await user("mason2@test.local",
    { firstName: "Imran", lastName: "Mason", roles: ["isNormalUser"],
      assignedProject: site("p_far", "Far Site", FAR, 150) });
  await user("pending@test.local",
    { firstName: "New", lastName: "Applicant", roles: ["isNormalUser"], isActive: false });

  const project = (name, address, workers) => ({
    projectName: name, projectDetails: "Emulator test site", selectedAddress: address,
    radius: 150, contractor: "Test Contractor", contactPerson: "Site Contact",
    phoneNumber: { phoneNumber: "+971500000000", isoCode: "AE", dialCode: "+971" },
    emailAddress: "site@test.local", status: "active", assignedWorkers: workers,
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

  // Sales: a salesperson with two clients (one saved the 2023 way, without a
  // phone) and visits today and earlier this week.
  const sales = await user("sales@test.local",
    { firstName: "Sara", lastName: "Sales", roles: ["isSales"] });
  for (const col of ["clientVisits", "projectVisits"]) {
    const docs = await db.collection("users").doc(sales).collection(col).listDocuments();
    await Promise.all(docs.map((d) => d.delete()));
  }
  await db.collection("clients").doc("c_noor").set({
    clientName: "Al Noor Interiors", contactPerson: "Omar Haddad",
    phoneNumber: { phoneNumber: "+971501234567", isoCode: "AE", dialCode: "+971" },
    emailAddress: "omar@alnoor.test", userId: sales,
    clientAddress: { addressName: "Al Quoz Industrial 3, Dubai", Lat: 25.1360, Lng: 55.2280 },
  });
  await db.collection("clients").doc("c_gulf").set({
    clientName: "Gulf Stone Trading", contactPerson: "Priya Nair", userId: sales,
  });
  const ago = (days, h, m) => {
    const d = new Date();
    d.setDate(d.getDate() - days);
    d.setHours(h, m, 0, 0);
    return Timestamp.fromDate(d);
  };
  const visits = db.collection("users").doc(sales);
  await visits.collection("clientVisits").add({
    uid: "c_noor", name: "Al Noor Interiors", contact: "Omar Haddad",
    visitPurpose: "Quotation follow up", userId: sales, visitTime: ago(0, 10, 15),
    visitDetails: "Went through the Carrara quotation; they want a revised price for 120 m2.",
  });
  await visits.collection("clientVisits").add({
    uid: "c_gulf", name: "Gulf Stone Trading", contact: "Priya Nair",
    visitPurpose: "Collecting payment", userId: sales, visitTime: ago(2, 15, 40),
    visitDetails: "Collected the cheque for invoice 2291; next order expected in November.",
    managerComments: "Good. Follow up on the November order in two weeks.",
  });
  await visits.collection("projectVisits").add({
    uid: "p_tower", name: "Marina Tower", contact: "Site Contact",
    visitPurpose: "Project discussion", userId: sales, visitTime: ago(1, 9, 0),
    visitDetails: "Met the contractor about the lobby flooring and the mock-up date.",
  });

  await db.collection("payroll").doc(mason1).set({
    currency: "AED", payType: "monthly", basic: 1800, housing: 500, transport: 200, food: 300,
    other: [{ name: "Overtime meals", amount: 100 }],
    effectiveFrom: Timestamp.fromDate(new Date("2026-01-01")),
    notes: "Seeded for emulator testing", updatedAt: Timestamp.now(), updatedBy: admin,
  });

  console.log(`Seeded. Password for every account: ${PASSWORD}`);
  console.log("  admin@test.local, supervisor@test.local, mason1@test.local (Test Villa + Marina Tower),");
  console.log("  mason2@test.local (assigned to Far Site), pending@test.local (inactive),");
  console.log("  sales@test.local (2 clients, 3 visits this week)");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
