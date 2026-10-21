import { getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onDocumentWritten } from "firebase-functions/v2/firestore";

/** Package fields that say when a worker's day ends; no pay amounts. */
const WORK_HOURS_FIELDS = ["weeklyHours", "dayEndMinutes", "weeklyOffDay"];

/** Just the working hours of a pay package, for `work_hours/{uid}`. */
export function workHoursOf(pkg: FirebaseFirestore.DocumentData): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const f of WORK_HOURS_FIELDS) if (pkg[f] !== undefined) out[f] = pkg[f];
  return out;
}

/**
 * Copies each pay package's working hours to `work_hours/{uid}`, so people
 * who decide on overtime without the Payroll page can tell when a worker's
 * day ends without reading their pay.
 */
export const mirrorWorkHours = onDocumentWritten("payroll/{uid}", async (event) => {
  const ref = getFirestore().collection("work_hours").doc(event.params.uid);
  const after = event.data?.after.data();
  await (after ? ref.set(workHoursOf(after)) : ref.delete());
});

/**
 * An overtime approval saved without a rate (the approver can't see pay)
 * gets the worker's overtime rate from their pay package, as HR's approvals
 * do in the app.
 */
export const fillOvertimeRate = onDocumentWritten("overtime/{id}", async (event) => {
  const after = event.data?.after;
  const d = after?.data();
  if (!after || !d || d.status !== "approved" || d.rate != null || typeof d.uid !== "string") return;
  const pkg = (await getFirestore().collection("payroll").doc(d.uid).get()).data();
  const rate = typeof pkg?.overtimeRate === "number" ? pkg.overtimeRate : 0;
  // Only if nobody changed the decision in the meantime.
  await getFirestore().runTransaction(async (tx) => {
    const now = (await tx.get(after.ref)).data();
    if (now?.status !== "approved" || now.rate != null) return;
    tx.update(after.ref, { rate });
  });
  logger.info("overtime rate filled", { id: event.params.id, rate });
});
