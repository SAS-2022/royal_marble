import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

initializeApp();
const db = getFirestore();

/** A fix worse than this (metres) is rejected outright. */
const MAX_ACCURACY_M = 50;
/** Up to this much of the fix's accuracy radius is credited toward being on site. */
const ACCURACY_TOLERANCE_M = 30;
/** A tracked phone that hasn't reported for this long is flagged as silent. */
const SILENT_AFTER_MIN = 20;

function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const r = 6371000;
  const rad = Math.PI / 180;
  const dLat = (lat2 - lat1) * rad;
  const dLng = (lng2 - lng1) * rad;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * Math.sin(dLng / 2) ** 2;
  return 2 * r * Math.asin(Math.sqrt(a));
}

const pad = (n: number, w = 2) => String(n).padStart(w, "0");

/**
 * Server time shifted into the worker's local zone. Returns the legacy
 * `d-m-yyyy` timesheet doc id and a `yyyy-MM-dd HH:mm:ss.SSS` string that
 * matches what older app versions stored (Dart's DateTime.toString()).
 */
function localClock(utcOffsetMinutes: number) {
  const local = new Date(Date.now() + utcOffsetMinutes * 60_000);
  return {
    dayId: `${local.getUTCDate()}-${local.getUTCMonth() + 1}-${local.getUTCFullYear()}`,
    stamp: `${local.getUTCFullYear()}-${pad(local.getUTCMonth() + 1)}-${pad(local.getUTCDate())} ` +
      `${pad(local.getUTCHours())}:${pad(local.getUTCMinutes())}:${pad(local.getUTCSeconds())}.` +
      `${pad(local.getUTCMilliseconds(), 3)}`,
  };
}

interface CheckInRequest {
  action: "in" | "out";
  kind: "project" | "mockup";
  siteId: string;
  lat: number;
  lng: number;
  accuracy: number;
  mock: boolean;
  utcOffsetMinutes: number;
  workType?: string;
  squareMeters?: number;
}

/**
 * Checks the caller in or out of a project/mock-up site.
 *
 * The phone supplies its GPS fix, but the distance check, the timestamp and
 * the timesheet write all happen here, so a wrong phone clock or an edited
 * app can't fake attendance.
 */
export const checkInOut = onCall(async (req: CallableRequest<CheckInRequest>) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Please sign in again.");
  const d = req.data;
  if (!d || (d.action !== "in" && d.action !== "out") || !d.siteId ||
      typeof d.lat !== "number" || typeof d.lng !== "number" ||
      typeof d.accuracy !== "number") {
    throw new HttpsError("invalid-argument", "Missing location data.");
  }
  const offset = Math.max(-14 * 60, Math.min(14 * 60, Math.round(d.utcOffsetMinutes ?? 0)));

  const userSnap = await db.collection("users").doc(uid).get();
  const user = userSnap.data();
  if (!user || user.isActive !== true) {
    throw new HttpsError("permission-denied", "Your account is not active.");
  }

  if (d.mock) {
    await logEvent(uid, user, "mock_location",
      `Tried to check ${d.action} with a fake GPS location`, "critical");
    throw new HttpsError("failed-precondition",
      "A fake GPS app was detected. Turn it off to check in.");
  }
  if (d.accuracy > MAX_ACCURACY_M) {
    throw new HttpsError("failed-precondition",
      `GPS signal is too weak (±${Math.round(d.accuracy)} m). ` +
      "Step outside or wait a moment and try again.");
  }

  const siteRef = db.collection(d.kind === "mockup" ? "mockup" : "projects").doc(d.siteId);
  const site = (await siteRef.get()).data();
  // Projects store their pin as `selectedAddress`; mock-ups as `address`.
  const addr = site?.selectedAddress ?? site?.address;
  if (!site || typeof addr?.Lat !== "number" || typeof addr?.Lng !== "number") {
    throw new HttpsError("not-found", "This site has no location set. Contact your admin.");
  }
  const radius = Number(site.radius ?? 0);
  const distance = haversineMeters(d.lat, d.lng, addr.Lat, addr.Lng);
  const effective = distance - Math.min(d.accuracy, ACCURACY_TOLERANCE_M);
  if (effective > radius) {
    throw new HttpsError("out-of-range",
      `You are ${Math.round(distance - radius)} m outside the site.`,
      { distance: Math.round(distance), radius });
  }

  const { dayId, stamp } = localClock(offset);
  const sheetRef = db.collection("time_sheet").doc(dayId);
  const role = Array.isArray(user.roles) && user.roles.length ? user.roles[0] : "isNormalUser";
  const siteName = site.projectName ?? site.name ?? "";
  const evidence = {
    lat: d.lat, lng: d.lng, accuracy: d.accuracy,
    distance: Math.round(distance), at: Timestamp.now(),
  };

  return db.runTransaction(async (tx) => {
    const sheet = (await tx.get(sheetRef)).data() ?? {};
    const entry = sheet[uid] as Record<string, unknown> | undefined;
    const onSite = entry?.isOnSite === true && entry?.leaving_at == null;

    if (d.action === "in") {
      if (onSite) {
        throw new HttpsError("already-exists",
          `You are already checked in at ${entry?.projectName ?? "a site"}.`);
      }
      const firstToday = entry?.arriving_at == null || entry?.projectId !== d.siteId;
      tx.set(sheetRef, {
        [uid]: {
          firstName: user.firstName ?? "",
          lastName: user.lastName ?? "",
          projectId: d.siteId,
          projectName: siteName,
          siteKind: d.kind,
          roles: role,
          isOnSite: true,
          arriving_at: firstToday ? stamp : entry?.arriving_at,
          leaving_at: null,
          checkInAt: firstToday ? FieldValue.serverTimestamp() : entry?.checkInAt ?? null,
          checkInEvidence: evidence,
          sessions: FieldValue.arrayUnion({ in: stamp }),
        },
      }, { merge: true });
      return { status: "checked_in", day: dayId, time: stamp, distance: Math.round(distance) };
    }

    if (!onSite) {
      throw new HttpsError("failed-precondition", "You are not checked in.");
    }
    if (entry?.projectId !== d.siteId) {
      throw new HttpsError("failed-precondition",
        `You are checked in at ${entry?.projectName}. Check out from there.`);
    }
    tx.set(sheetRef, {
      [uid]: {
        isOnSite: false,
        leaving_at: stamp,
        checkOutAt: FieldValue.serverTimestamp(),
        checkOutEvidence: evidence,
        sessions: FieldValue.arrayUnion({ out: stamp }),
        ...(d.workType ? {
          workCompleted: {
            workType: d.workType,
            squareMeters: d.squareMeters ?? null,
            // Older report screens read this misspelt key.
            sqaureMeters: d.squareMeters ?? null,
          },
        } : {}),
      },
    }, { merge: true });
    return { status: "checked_out", day: dayId, time: stamp, distance: Math.round(distance) };
  });
});

async function logEvent(
  uid: string, user: FirebaseFirestore.DocumentData, type: string,
  message: string, severity: "info" | "warning" | "critical",
) {
  await db.collection("device_events").add({
    uid,
    userName: `${user.firstName ?? ""} ${user.lastName ?? ""}`.trim(),
    type, message, severity,
    at: Timestamp.now(),
    receivedAt: FieldValue.serverTimestamp(),
    source: "server",
  });
}

/**
 * Phones can't report that they went dark (switched off, no signal, app
 * force-stopped). Every 10 minutes, flag tracked users whose last report is
 * older than SILENT_AFTER_MIN, and log one event per silence.
 */
export const detectSilentDevices = onSchedule("every 10 minutes", async () => {
  const cutoff = Timestamp.fromMillis(Date.now() - SILENT_AFTER_MIN * 60_000);
  const stale = await db.collection("users")
    .where("deviceStatus.silent", "==", false)
    .where("deviceStatus.lastSeen", "<", cutoff)
    .get();

  for (const doc of stale.docs) {
    const user = doc.data();
    if (user.isActive !== true) continue;
    const lastSeen = (user.deviceStatus?.lastSeen as Timestamp | undefined)?.toDate();
    await doc.ref.update({ "deviceStatus.silent": true });
    await logEvent(doc.id, user, "silent",
      `Phone stopped reporting${lastSeen ? ` (last seen ${lastSeen.toISOString()})` : ""}. ` +
      "It may be switched off, offline, or the app was force-stopped.",
      "critical");
  }
  logger.info(`detectSilentDevices: flagged ${stale.size}`);
});
