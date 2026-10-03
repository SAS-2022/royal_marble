import { Timestamp } from "firebase-admin/firestore";

/**
 * Shape of one worker's day in `time_sheet/{d-m-yyyy}.{uid}`.
 *
 * `sessions` is the source of truth: one entry per stay at a site, at most
 * one of them open. The flat legacy fields (`arriving_at`, `leaving_at`,
 * `isOnSite`, `projectId`, `projectName`) are derived from it on every write
 * so the 2023 app and older screens keep reading something sensible.
 */

export type SiteKind = "project" | "mockup";

/** Why a session was closed by the system rather than by the worker. */
export type AutoReason = "left_site" | "end_of_day";

export interface PresenceEvent {
  type: "enter" | "exit";
  /** Local wall-clock stamp, same format as `in`/`out`. */
  at: string;
  atTs: Timestamp;
  lat?: number;
  lng?: number;
  accuracy?: number;
}

export interface Session {
  siteId: string;
  siteKind: SiteKind;
  siteName: string;
  /** Local `yyyy-MM-dd HH:mm:ss.SSS` stamps, as older app versions stored. */
  in: string;
  inTs?: Timestamp | null;
  out?: string | null;
  outTs?: Timestamp | null;
  /** Legacy day that was closed without a check-out (old checkout crash). */
  noCheckout?: boolean;
  /** Set when the system closed the session. */
  auto?: AutoReason | null;
  /** An admin changed this session's times (see the entry's `corrections`). */
  corrected?: boolean;
  /** Closed because the worker checked in at another site. */
  switched?: boolean;
  /** Geofence transitions while the session was open. */
  events?: PresenceEvent[];
  work?: { workType: string; squareMeters: number | null } | null;
}

export type Entry = Record<string, unknown>;

const pad = (n: number, w = 2) => String(n).padStart(w, "0");

/** Clamp a phone-supplied UTC offset to the real-world range. */
export function clampOffset(minutes: unknown): number {
  const m = Math.round(Number(minutes ?? 0));
  return Number.isFinite(m) ? Math.max(-14 * 60, Math.min(14 * 60, m)) : 0;
}

/** `d-m-yyyy` doc id and local stamp for an instant in the worker's zone. */
export function localClock(ms: number, utcOffsetMinutes: number) {
  const local = new Date(ms + utcOffsetMinutes * 60_000);
  return {
    dayId: `${local.getUTCDate()}-${local.getUTCMonth() + 1}-${local.getUTCFullYear()}`,
    stamp: `${local.getUTCFullYear()}-${pad(local.getUTCMonth() + 1)}-${pad(local.getUTCDate())} ` +
      `${pad(local.getUTCHours())}:${pad(local.getUTCMinutes())}:${pad(local.getUTCSeconds())}.` +
      `${pad(local.getUTCMilliseconds(), 3)}`,
    hour: local.getUTCHours(),
  };
}

/** Inverse of [localClock]'s stamp; null if it can't be parsed. */
export function stampToMs(stamp: unknown, utcOffsetMinutes: number): number | null {
  const m = /^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,6}))?)?/
    .exec(String(stamp ?? ""));
  if (!m) return null;
  const ms = Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +(m[6] ?? 0),
    Math.round(Number(`0.${m[7] ?? "0"}`) * 1000));
  return ms - utcOffsetMinutes * 60_000;
}

/** Instant of a session boundary, preferring the server timestamp. */
export function instant(ts: Timestamp | null | undefined, stamp: unknown, offset: number) {
  return ts instanceof Timestamp ? ts.toMillis() : stampToMs(stamp, offset);
}

/**
 * Sessions of an entry. Entries written by the 2023 app (or by this server
 * before sessions existed) only have the flat fields; they become a single
 * synthesized session.
 */
export function sessionsOf(entry: Entry | undefined): Session[] {
  if (!entry) return [];
  const raw = entry.sessions;
  if (Array.isArray(raw) && raw.length && raw.every((s) => s && typeof s === "object" && s.siteId)) {
    return raw.map((s) => ({ ...s })) as Session[];
  }
  if (entry.arriving_at == null || !entry.projectId) return [];
  const open = entry.isOnSite === true && entry.leaving_at == null;
  return [{
    siteId: String(entry.projectId),
    siteKind: entry.siteKind === "mockup" ? "mockup" : "project",
    siteName: String(entry.projectName ?? ""),
    in: String(entry.arriving_at),
    inTs: (entry.checkInAt as Timestamp | undefined) ?? null,
    out: entry.leaving_at == null ? null : String(entry.leaving_at),
    outTs: (entry.checkOutAt as Timestamp | undefined) ?? null,
    ...(!open && entry.leaving_at == null ? { noCheckout: true } : {}),
  }];
}

export const isOpen = (s: Session) => !s.out && !s.noCheckout;

export function openSession(sessions: Session[]): Session | undefined {
  return sessions.find(isOpen);
}

/** The flat fields older readers use, derived from [sessions]. */
export function legacyFields(sessions: Session[]) {
  const sorted = [...sessions].sort((a, b) => a.in.localeCompare(b.in));
  const first = sorted[0];
  const open = openSession(sorted);
  const last = open ?? sorted[sorted.length - 1];
  const lastOut = [...sorted].reverse().find((s) => s.out)?.out ?? null;
  return {
    sessions: sorted,
    arriving_at: first?.in ?? null,
    leaving_at: open ? null : lastOut,
    isOnSite: !!open,
    projectId: last?.siteId ?? null,
    projectName: last?.siteName ?? "",
    siteKind: last?.siteKind ?? "project",
    autoCheckout: sorted.some((s) => !!s.auto),
  };
}

/** The last geofence exit of [s] if the worker hasn't come back since. */
export function pendingExit(s: Session): PresenceEvent | undefined {
  const last = s.events?.[s.events.length - 1];
  return last?.type === "exit" ? last : undefined;
}

/**
 * Auto check-out rules (client decision #2 in status.md; adjust once agreed):
 * outside the site this long while checked in closes the session at the exit
 * time; sessions still open at this local hour close at the last moment the
 * phone was known to be alive.
 */
export const AWAY_LIMIT_MIN = 60;
export const END_OF_DAY_HOUR = 22;
/**
 * When and why the system should close [s], or null to leave it open.
 * [lastSeenMs] is the last time the phone reported anything.
 */
export function autoCloseDecision(
  s: Session, dayId: string, offset: number, nowMs: number, lastSeenMs: number | null,
): { reason: AutoReason; outMs: number } | null {
  const inMs = instant(s.inTs, s.in, offset);
  if (inMs == null) return null;
  const exit = pendingExit(s);
  const exitMs = exit ? instant(exit.atTs, exit.at, offset) : null;
  if (exitMs != null && nowMs - exitMs >= AWAY_LIMIT_MIN * 60_000) {
    return { reason: "left_site", outMs: Math.max(exitMs, inMs) };
  }
  const local = localClock(nowMs, offset);
  if (local.dayId === dayId && local.hour < END_OF_DAY_HOUR) return null;
  const endMs = stampToMs(`${s.in.slice(0, 10)} ${END_OF_DAY_HOUR}:00:00`, offset) ?? nowMs;
  // No exit was seen, so the last sign of life is the best estimate of when
  // the worker was still on site. An admin reviews these.
  const lastKnown = exitMs ?? lastSeenMs ?? inMs;
  return { reason: "end_of_day", outMs: Math.min(Math.max(lastKnown, inMs), endMs, nowMs) };
}
