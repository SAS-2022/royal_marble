/* eslint-disable no-console */
/**
 * One-off: copies the working hours of every existing pay package to
 * `work_hours/{uid}` (the `mirrorWorkHours` function does this for every
 * later change). Run once after deploying the functions; safe to repeat.
 *
 *   Emulator:   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node scripts/backfill-work-hours.js [--apply]
 *   Production: GOOGLE_APPLICATION_CREDENTIALS=<key.json> node scripts/backfill-work-hours.js \
 *                 --project royal-marble [--apply]
 *
 * Without --apply it only prints what it would write.
 */
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { workHoursOf } = require("../lib/pay");

const args = process.argv.slice(2);
const apply = args.includes("--apply");
const projectArg = args[args.indexOf("--project") + 1];
const emulator = !!process.env.FIRESTORE_EMULATOR_HOST;
if (!emulator && (!args.includes("--project") || !projectArg)) {
  console.error("Not pointed at the emulator: pass --project <id> to confirm the target.");
  process.exit(1);
}
const projectId = emulator ? "royal-marble" : projectArg;
initializeApp({ projectId });
const db = getFirestore();

async function main() {
  console.log(`${apply ? "APPLYING to" : "Dry run on"} ${emulator ? "the emulator" : `project ${projectId}`}\n`);
  const packages = await db.collection("payroll").get();
  for (const doc of packages.docs) {
    const hours = workHoursOf(doc.data());
    console.log(`  ${doc.id}: ${JSON.stringify(hours)}`);
    if (apply) await db.collection("work_hours").doc(doc.id).set(hours);
  }
  console.log(`\n${packages.size} package(s)${apply ? " copied" : " would be copied"}.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
