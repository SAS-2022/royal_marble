import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { CallableRequest, HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

import {
  Entry, PresenceEvent, Session, SiteKind, autoCloseDecision, clampOffset, instant, isOpen,
  legacyFields, localClock, openSession, sessionsOf, stampToMs,
} from "./attendance";

export { notifyNewUser } from "./notify";

initializeApp();
const db = getFirestore();
// Sessions carry optional fields; let Firestore drop the unset ones.
db.settings({ ignoreUndefinedProperties: true });

/** A fix worse than this (metres) is rejected outright. */
const MAX_ACCURACY_M = 50;
/** Up to this much of the fix's accuracy radius is credited toward being on site. */
const ACCURACY_TOLERANCE_M = 30;
/** A tracked phone that hasn't reported for this long is flagged as silent. */
const SILENT_AFTER_MIN = 20;
/** Entries written before the phone sent its offset are from Dubai (UTC+4). */
const DEFAULT_OFFSET_MIN = 240;

function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const r = 6371000;
  const rad = Math.PI / 180;
  const dLat = (lat2 - lat1) * rad;
  const dLng = (lng2 - lng1) * rad;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * Math.sin(dLng / 2) ** 2;
  return 2 * r * Math.asin(Math.sqrt(a));
}

const offsetOf = (entry: Entry | undefined) =>
  entry?.utcOffsetMinutes == null ? DEFAULT_OFFSET_MIN : clampOffset(entry.utcOffsetMinutes);

const roleOf = (user: FirebaseFirestore.DocumentData) =>
  Array.isArray(user.roles) && user.roles.length ? user.roles[0] : "isNormalUser";

/** Entry fields to merge after [sessions] changed. */
function entryUpdate(sessions: Session[], extra: Record<string, unknown> = {}) {
  return { ...legacyFields(sessions), ...extra };
}

interface CheckInRequest {
  action: "in" | "out";
  kind: SiteKind;
  siteId: string;
  lat: number;
  lng: number;
  accuracy: number;
  mock: boolean;
  utcOffsetMinutes: number;
  /** Check-in only: close a session open at another site instead of refusing. */
  switchSite?: boolean;
  /** Work report for the session being closed (check-out, or a switch). */
  workType?: string;
  squareMeters?: number;
}

/**
 * Checks the caller in or out of a project/mock-up site.
 *
 * The phone supplies its GPS fix, but the distance check, the timestamp and
 * the timesheet write all happen here, so a wrong phone clock or an edited
 * app can't fake attendance. Each stay at a site is its own session; checking
 * in at a second site with `switchSite` closes the first.
 */
export const checkInOut = onCall(async (req: CallableRequest<CheckInRequest>) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Please sign in again.", { reason: "sign_in_again" });
  const d = req.data;
  if (!d || (d.action !== "in" && d.action !== "out") || !d.siteId ||
      typeof d.lat !== "number" || typeof d.lng !== "number" ||
      typeof d.accuracy !== "number") {
    throw new HttpsError("invalid-argument", "Missing location data.", { reason: "bad_request" });
  }
  const kind: SiteKind = d.kind === "mockup" ? "mockup" : "project";
  const offset = clampOffset(d.utcOffsetMinutes);

  const userSnap = await db.collection("users").doc(uid).get();
  const user = userSnap.data();
  if (!user || user.isActive !== true) {
    throw new HttpsError("permission-denied", "Your account is not active.", { reason: "not_active" });
  }

  // Workers may only check in at sites they are assigned to. Assignments are
  // a list, or a single map for masons assigned by older app versions.
  const assigned = kind === "mockup" ? user.assignedMockup : user.assignedProject;
  const assignedIds = (Array.isArray(assigned) ? assigned : [assigned])
    .filter((a) => a && typeof a === "object")
    .map((a) => a.id);
  if (!assignedIds.includes(d.siteId)) {
    throw new HttpsError("permission-denied", "You are not assigned to this site.",
      { reason: "not_assigned" });
  }

  if (d.mock) {
    await logEvent(uid, user, "mock_location",
      `Tried to check ${d.action} with a fake GPS location`, "critical");
    throw new HttpsError("failed-precondition",
      "A fake GPS app was detected. Turn it off to check in.", { reason: "mock_location" });
  }
  if (d.accuracy > MAX_ACCURACY_M) {
    throw new HttpsError("failed-precondition",
      `GPS signal is too weak (±${Math.round(d.accuracy)} m). ` +
      "Step outside or wait a moment and try again.",
      { reason: "weak_gps", meters: Math.round(d.accuracy) });
  }

  const siteRef = db.collection(kind === "mockup" ? "mockup" : "projects").doc(d.siteId);
  const site = (await siteRef.get()).data();
  // Projects store their pin as `selectedAddress`; mock-ups as `address`.
  const addr = site?.selectedAddress ?? site?.address;
  if (!site || typeof addr?.Lat !== "number" || typeof addr?.Lng !== "number") {
    throw new HttpsError("not-found", "This site has no location set. Contact your admin.",
      { reason: "no_site_location" });
  }
  const radius = Number(site.radius ?? 0);
  const distance = haversineMeters(d.lat, d.lng, addr.Lat, addr.Lng);
  const effective = distance - Math.min(d.accuracy, ACCURACY_TOLERANCE_M);
  if (effective > radius) {
    throw new HttpsError("out-of-range",
      `You are ${Math.round(distance - radius)} m outside the site.`,
      { reason: "out_of_range", meters: Math.round(distance - radius),
        distance: Math.round(distance), radius });
  }

  const now = Date.now();
  const nowTs = Timestamp.fromMillis(now);
  const { dayId, stamp } = localClock(now, offset);
  const sheetRef = db.collection("time_sheet").doc(dayId);
  const siteName = site.projectName ?? site.name ?? "";
  const evidence = {
    lat: d.lat, lng: d.lng, accuracy: d.accuracy,
    distance: Math.round(distance), at: nowTs,
  };
  const work = d.workType ? { workType: d.workType, squareMeters: d.squareMeters ?? null } : null;
  // Older report screens read `workCompleted`, including this misspelt key.
  const legacyWork = work ? { workCompleted: { ...work, sqaureMeters: work.squareMeters } } : {};

  return db.runTransaction(async (tx) => {
    const sheet = (await tx.get(sheetRef)).data() ?? {};
    const entry = sheet[uid] as Entry | undefined;
    const sessions = sessionsOf(entry);
    const open = openSession(sessions);
    const base = {
      firstName: user.firstName ?? "",
      lastName: user.lastName ?? "",
      roles: roleOf(user),
      utcOffsetMinutes: offset,
    };

    if (d.action === "in") {
      if (open && (open.siteId === d.siteId || !d.switchSite)) {
        throw new HttpsError("already-exists",
          `You are already checked in at ${open.siteName || "a site"}.`,
          { reason: "already_checked_in", site: open.siteName, siteId: open.siteId });
      }
      if (open) {
        open.out = stamp;
        open.outTs = nowTs;
        open.switched = true;
        if (work) open.work = work;
      }
      sessions.push({ siteId: d.siteId, siteKind: kind, siteName, in: stamp, inTs: nowTs, events: [] });
      tx.set(sheetRef, {
        [uid]: entryUpdate(sessions, {
          ...base,
          ...(open ? legacyWork : {}),
          checkInAt: entry?.checkInAt ?? FieldValue.serverTimestamp(),
          checkInEvidence: evidence,
        }),
      }, { merge: true });
      return {
        status: open ? "switched" : "checked_in", day: dayId, time: stamp,
        distance: Math.round(distance), ...(open ? { previousSite: open.siteName } : {}),
      };
    }

    if (!open) {
      throw new HttpsError("failed-precondition", "You are not checked in.",
        { reason: "not_checked_in" });
    }
    if (open.siteId !== d.siteId) {
      throw new HttpsError("failed-precondition",
        `You are checked in at ${open.siteName}. Check out from there.`,
        { reason: "checked_in_elsewhere", site: open.siteName });
    }
    open.out = stamp;
    open.outTs = nowTs;
    if (work) open.work = work;
    tx.set(sheetRef, {
      [uid]: entryUpdate(sessions, {
        ...base,
        ...legacyWork,
        checkOutAt: FieldValue.serverTimestamp(),
        checkOutEvidence: evidence,
      }),
    }, { merge: true });
    return { status: "checked_out", day: dayId, time: stamp, distance: Math.round(distance) };
  });
});

interface PresenceRequest {
  kind: SiteKind;
  siteId: string;
  transition: "enter" | "exit";
  /** When the phone saw the transition (ISO 8601); events can arrive late. */
  at?: string;
  lat?: number;
  lng?: number;
  accuracy?: number;
  mock?: boolean;
  utcOffsetMinutes: number;
}

/** How far back a late-delivered geofence event is still trusted. */
const MAX_EVENT_DELAY_MS = 12 * 3600_000;

/**
 * Geofence transitions from the phone. While the worker is checked in at
 * that site, each exit/return is recorded on the open session and admins get
 * a `left_site` / `returned_to_site` alert. Anything else is ignored.
 */
export const reportPresence = onCall(async (req: CallableRequest<PresenceRequest>) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Please sign in again.", { reason: "sign_in_again" });
  const d = req.data;
  if (!d?.siteId || (d.transition !== "enter" && d.transition !== "exit")) {
    throw new HttpsError("invalid-argument", "Missing geofence data.", { reason: "bad_request" });
  }
  // A faked position says nothing about where the worker really is.
  if (d.mock) return { status: "ignored" };

  const now = Date.now();
  const offset = clampOffset(d.utcOffsetMinutes);
  const reported = Date.parse(d.at ?? "");
  const seen = Number.isFinite(reported) && reported <= now + 120_000 &&
    reported >= now - MAX_EVENT_DELAY_MS ? Math.min(reported, now) : now;
  const sheetRef = db.collection("time_sheet").doc(localClock(seen, offset).dayId);

  const result = await db.runTransaction(async (tx) => {
    const entry = (await tx.get(sheetRef)).data()?.[uid] as Entry | undefined;
    const sessions = sessionsOf(entry);
    const open = openSession(sessions);
    if (!open || open.siteId !== d.siteId || !Array.isArray(entry?.sessions)) {
      return { status: "ignored" } as const;
    }
    const last = open.events?.[open.events.length - 1];
    // The first "enter" right after check-in only confirms the worker is there.
    if ((last?.type ?? "enter") === d.transition) return { status: "ignored" } as const;

    const startMs = instant(open.inTs, open.in, offset) ?? seen;
    const atMs = Math.max(seen, startMs);
    const event: PresenceEvent = {
      type: d.transition,
      at: localClock(atMs, offset).stamp,
      atTs: Timestamp.fromMillis(atMs),
      ...(typeof d.lat === "number" ? { lat: d.lat, lng: d.lng, accuracy: d.accuracy } : {}),
    };
    open.events = [...(open.events ?? []), event];
    tx.set(sheetRef, { [uid]: entryUpdate(sessions) }, { merge: true });
    return { status: "recorded", siteName: open.siteName, entry } as const;
  });
  if (result.status !== "recorded") return { status: result.status };

  const names = result.entry ?? {};
  await logEvent(uid, names, d.transition === "exit" ? "left_site" : "returned_to_site",
    d.transition === "exit"
      ? `Left ${result.siteName || "the site"} while checked in`
      : `Returned to ${result.siteName || "the site"}`,
    d.transition === "exit" ? "warning" : "info", { site: result.siteName });
  return { status: "recorded" };
});

/**
 * Closes sessions the worker forgot to check out of (see [autoCloseDecision]).
 * Only entries written by `checkInOut` are touched, never ones the 2023 app
 * manages. Returns how many sessions were closed.
 */
async function runAutoCheckout(nowMs: number): Promise<number> {
  // Every timezone's "today" is within a day of UTC's.
  const dayIds = new Set([-1, 0, 1].map((k) => localClock(nowMs + k * 86400_000, 0).dayId));
  let closed = 0;
  for (const dayId of dayIds) {
    const ref = db.collection("time_sheet").doc(dayId);
    const snap = await ref.get();
    for (const [uid, value] of Object.entries(snap.data() ?? {})) {
      if (!value || typeof value !== "object" || !Array.isArray(value.sessions)) continue;
      if (!openSession(sessionsOf(value))) continue;
      const lastSeen = ((await db.collection("users").doc(uid).get())
        .get("deviceStatus.lastSeen") as Timestamp | undefined)?.toMillis() ?? null;

      const done = await db.runTransaction(async (tx) => {
        const entry = (await tx.get(ref)).data()?.[uid] as Entry | undefined;
        const sessions = sessionsOf(entry);
        const s = openSession(sessions);
        if (!s) return null;
        const offset = offsetOf(entry);
        const decision = autoCloseDecision(s, dayId, offset, nowMs, lastSeen);
        if (!decision) return null;
        s.out = localClock(decision.outMs, offset).stamp;
        s.outTs = Timestamp.fromMillis(decision.outMs);
        s.auto = decision.reason;
        tx.set(ref, { [uid]: entryUpdate(sessions) }, { merge: true });
        return { s, entry: entry ?? {} };
      });
      if (!done) continue;
      closed++;
      await logEvent(uid, done.entry, "auto_checkout",
        `Checked out automatically from ${done.s.siteName} at ${done.s.out?.slice(11, 16)} ` +
        (done.s.auto === "left_site" ? "(left the site and did not return)" : "(no check-out by end of day)"),
        "warning", { site: done.s.siteName, reason: done.s.auto });
    }
  }
  return closed;
}

export const autoCheckout = onSchedule("every 15 minutes", async () => {
  logger.info(`autoCheckout: closed ${await runAutoCheckout(Date.now())}`);
});

// Lets the emulator tests run the scheduled job at a chosen time. Firebase
// discovers functions without FUNCTIONS_EMULATOR set, so this is never deployed.
if (process.env.FUNCTIONS_EMULATOR === "true") {
  exports.devRunAutoCheckout = onRequest(async (req, res) => {
    const now = req.query.now ? Date.parse(String(req.query.now)) : Date.now();
    res.json({ closed: await runAutoCheckout(now) });
  });
}

interface CorrectedSession {
  siteId: string;
  siteKind: SiteKind;
  siteName: string;
  in: string;
  out: string | null;
  /** Index of the session this one edits, to keep its events and work report. */
  from?: number | null;
}

interface CorrectionRequest {
  day: string;
  uid: string;
  sessions: CorrectedSession[];
  note?: string;
}

/**
 * Admin correction of one worker's day: replace the sessions (fix times, add
 * a forgotten day, remove a mistake) or approve them unchanged. Every save is
 * kept in the entry's `corrections` list with who, when, why and the previous
 * sessions.
 */
export const correctAttendance = onCall(async (req: CallableRequest<CorrectionRequest>) => {
  const callerId = req.auth?.uid;
  if (!callerId) throw new HttpsError("unauthenticated", "Please sign in again.", { reason: "sign_in_again" });
  const caller = (await db.collection("users").doc(callerId).get()).data();
  if (!caller || caller.isActive !== true || !caller.roles?.includes("isAdmin")) {
    throw new HttpsError("permission-denied", "Only admins can correct attendance.", { reason: "not_admin" });
  }
  const d = req.data;
  const day = /^(\d{1,2})-(\d{1,2})-(\d{4})$/.exec(d?.day ?? "");
  if (!day || !d.uid || !Array.isArray(d.sessions)) {
    throw new HttpsError("invalid-argument", "Missing correction data.", { reason: "bad_request" });
  }
  const datePart = `${day[3]}-${day[2].padStart(2, "0")}-${day[1].padStart(2, "0")}`;
  const bad = (why: string) => new HttpsError("invalid-argument", why, { reason: "bad_sessions" });

  const incoming = d.sessions.map((s) => ({ ...s, out: s.out || null }))
    .sort((a, b) => a.in.localeCompare(b.in));
  for (const [i, s] of incoming.entries()) {
    if (!s.siteId || stampToMs(s.in, 0) == null || !s.in.startsWith(datePart)) {
      throw bad("Each session needs a site and a start time on that day.");
    }
    if (s.out && (stampToMs(s.out, 0) == null || s.out <= s.in)) throw bad("End time must be after start time.");
    if (!s.out && i !== incoming.length - 1) throw bad("Only the last session can be left open.");
    if (i > 0 && (incoming[i - 1].out ?? "") > s.in) throw bad("Sessions overlap.");
  }

  const worker = (await db.collection("users").doc(d.uid).get()).data();
  if (!worker) throw new HttpsError("not-found", "Unknown worker.", { reason: "bad_request" });
  const sheetRef = db.collection("time_sheet").doc(d.day);

  return db.runTransaction(async (tx) => {
    const entry = (await tx.get(sheetRef)).data()?.[d.uid] as Entry | undefined;
    const before = sessionsOf(entry);
    const offset = offsetOf(entry);
    const ts = (stamp: string | null) => {
      const ms = stampToMs(stamp, offset);
      return ms == null ? null : Timestamp.fromMillis(ms);
    };
    const after: Session[] = incoming.map((s) => {
      const prev = s.from != null ? before[s.from] : undefined;
      const sameIn = prev?.in === s.in;
      const sameOut = (prev?.out ?? null) === s.out;
      return {
        ...(prev ?? {}),
        siteId: s.siteId,
        siteKind: s.siteKind === "mockup" ? "mockup" : "project",
        siteName: s.siteName ?? "",
        in: s.in,
        inTs: sameIn ? prev?.inTs ?? ts(s.in) : ts(s.in),
        out: s.out,
        outTs: sameOut ? prev?.outTs ?? ts(s.out) : ts(s.out),
        noCheckout: false,
        ...(prev && sameIn && sameOut ? {} : { corrected: true }),
      };
    });
    if (after.filter(isOpen).length > 1) throw bad("Only one session can be open.");

    const by = `${caller.firstName ?? ""} ${caller.lastName ?? ""}`.trim();
    const record = {
      by: callerId, byName: by, at: Timestamp.now(), note: d.note ?? "",
      before: before.map((s) => ({ siteName: s.siteName, in: s.in, out: s.out ?? null, auto: s.auto ?? null })),
    };
    tx.set(sheetRef, {
      [d.uid]: entryUpdate(after, {
        firstName: entry?.firstName ?? worker.firstName ?? "",
        lastName: entry?.lastName ?? worker.lastName ?? "",
        roles: entry?.roles ?? roleOf(worker),
        utcOffsetMinutes: offset,
        reviewed: { by: callerId, byName: by, at: record.at },
        corrections: FieldValue.arrayUnion(record),
      }),
    }, { merge: true });
    return { status: "saved", sessions: after.length };
  });
});

async function logEvent(
  uid: string, user: FirebaseFirestore.DocumentData, type: string,
  message: string, severity: "info" | "warning" | "critical",
  extra: Record<string, unknown> = {},
) {
  await db.collection("device_events").add({
    uid,
    userName: `${user.firstName ?? ""} ${user.lastName ?? ""}`.trim(),
    type, message, severity,
    ...extra,
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
