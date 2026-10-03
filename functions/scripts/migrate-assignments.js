/* eslint-disable no-console */
/**
 * Rollout migration for multi-site assignments (Phase 3). NOT RUN YET.
 *
 * 1. Masons' `assignedProject` / `assignedMockup` written by older app
 *    versions as a single map (or `{}` after removal) become a list, the
 *    shape supervisors already use and the new app writes for everyone.
 * 2. Site teams (`projects|mockup.assignedWorkers`) that still list a worker
 *    whose own assignments don't include the site are reported; older
 *    versions left these behind when they moved a mason to another site.
 *    With --apply they are removed from the site's team.
 *
 * Timesheets need no migration: the app and server read entries without
 * `sessions` as one session.
 *
 * Run it only when every phone has the new app: the 2023 app reads a mason's
 * assignment as a single map and breaks on a list.
 *
 *   Emulator:   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node scripts/migrate-assignments.js [--apply]
 *   Production: GOOGLE_APPLICATION_CREDENTIALS=<key.json> node scripts/migrate-assignments.js \
 *                 --project royal-marble [--apply]
 *
 * Without --apply it only prints what it would change.
 */
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

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

const asList = (v) => (Array.isArray(v) ? v : [v]).filter((a) => a && typeof a === "object" && a.id);

async function main() {
  console.log(`${apply ? "APPLYING to" : "Dry run on"} ${emulator ? "the emulator" : `project ${projectId}`}\n`);
  const users = await db.collection("users").get();
  const assigned = { project: new Map(), mockup: new Map() };
  let reshaped = 0;

  for (const doc of users.docs) {
    const u = doc.data();
    const name = `${u.firstName ?? ""} ${u.lastName ?? ""}`.trim() || doc.id;
    const update = {};
    for (const [field, kind] of [["assignedProject", "project"], ["assignedMockup", "mockup"]]) {
      const value = u[field];
      const list = asList(value);
      assigned[kind].set(doc.id, new Set(list.map((a) => a.id)));
      if (value !== undefined && !Array.isArray(value)) {
        update[field] = list;
        console.log(`  ${name}: ${field} map → list (${list.map((a) => a.name).join(", ") || "none"})`);
      }
    }
    if (Object.keys(update).length) {
      reshaped++;
      if (apply) await doc.ref.update(update);
    }
  }

  let stale = 0;
  for (const [col, kind, label] of [["projects", "project", "projectName"], ["mockup", "mockup", "name"]]) {
    const sites = await db.collection(col).get();
    for (const site of sites.docs) {
      const workers = site.get("assignedWorkers");
      if (!Array.isArray(workers)) continue;
      const keep = workers.filter((uid) => assigned[kind].get(uid)?.has(site.id));
      const dropped = workers.filter((uid) => !keep.includes(uid));
      if (!dropped.length) continue;
      stale += dropped.length;
      console.log(`  ${site.get(label) ?? site.id}: ${dropped.length} stale team entr${dropped.length === 1 ? "y" : "ies"} ` +
        `(${dropped.join(", ")})`);
      if (apply) await site.ref.update({ assignedWorkers: keep });
    }
  }

  console.log(`\n${reshaped} user(s) to reshape, ${stale} stale team entr${stale === 1 ? "y" : "ies"}` +
    (apply ? " — done." : ". Re-run with --apply to write."));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
