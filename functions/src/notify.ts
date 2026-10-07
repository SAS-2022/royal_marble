import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions/v2";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

/** Push texts in the reader's language (`users/{uid}.language`). */
const NEW_USER_TEXT: Record<string, { title: string; body: (name: string) => string }> = {
  en: { title: "New sign-up", body: (n) => `${n} is waiting for approval.` },
  ar: { title: "تسجيل جديد", body: (n) => `${n} بانتظار الموافقة.` },
  hi: { title: "नया पंजीकरण", body: (n) => `${n} स्वीकृति की प्रतीक्षा में है।` },
  ur: { title: "نئی رجسٹریشن", body: (n) => `${n} منظوری کا منتظر ہے۔` },
};

/**
 * The person's switch for an alert group (`users/{uid}.notify.{key}`, set in
 * the app's Notifications screen). Missing means on.
 */
const wants = (user: FirebaseFirestore.DocumentSnapshot, key: string) =>
  user.get(`notify.${key}`) !== false;

/** Tokens FCM reports as gone; they are removed from the profile. */
const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

/**
 * Sends one notification to every phone the user is signed in on
 * (`users/{uid}.fcmTokens`, saved by the app) and drops dead tokens.
 * Returns how many phones accepted it.
 */
export async function pushToUser(
  user: FirebaseFirestore.DocumentSnapshot,
  title: string, body: string, data: Record<string, string>,
): Promise<number> {
  const tokens: string[] = (user.get("fcmTokens") ?? []).filter((t: unknown) => typeof t === "string");
  if (!tokens.length) return 0;
  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: { priority: "high" },
  });
  const dead = tokens.filter((_, i) => {
    const code = res.responses[i].error?.code;
    return code != null && DEAD_TOKEN_CODES.has(code);
  });
  // e.g. "messaging/third-party-auth-error" = no APNs key in Firebase for iPhones.
  const failed = res.responses.map((r) => r.error?.code).filter((c) => c != null);
  if (failed.length) logger.warn(`pushToUser ${user.id}: ${failed.join(", ")}`);
  if (dead.length) {
    await user.ref.update({ fcmTokens: FieldValue.arrayRemove(...dead) });
  }
  return res.successCount;
}

/**
 * A new profile starts inactive (sign-up from the app, email or Google/Apple).
 * Tell every active admin so they can approve it; tapping the notification
 * opens that user's page.
 */
export const notifyNewUser = onDocumentCreated("users/{uid}", async (event) => {
  const user = event.data?.data();
  if (!user || user.isActive !== false) return;
  const name = `${user.firstName ?? ""} ${user.lastName ?? ""}`.trim() ||
    user.emailAddress || "Someone";

  const admins = await getFirestore().collection("users")
    .where("roles", "array-contains", "isAdmin").get();
  let sent = 0;
  for (const admin of admins.docs) {
    if (admin.get("isActive") !== true || admin.id === event.params.uid) continue;
    if (!wants(admin, "newUsers")) continue;
    const text = NEW_USER_TEXT[admin.get("language")] ?? NEW_USER_TEXT.en;
    try {
      sent += await pushToUser(admin, text.title, text.body(name),
        { type: "new_user", uid: event.params.uid });
    } catch (e) {
      logger.error(`notifyNewUser: push to ${admin.id} failed`, e);
    }
  }
  logger.info(`notifyNewUser: ${event.params.uid} → ${sent} phone(s) of ${admins.size} admin(s)`);
});

type Texts = Record<string, (site: string) => string>;

/**
 * Alert texts per type, the same wording the app shows in Team Status
 * (`ev*` strings in lib/l10n). Only these types are pushed.
 */
const ALERT_TEXT: Record<string, Texts> = {
  left_site: {
    en: (s) => `Left ${s} while checked in`,
    ar: (s) => `غادر ${s} أثناء تسجيل الدخول`,
    hi: (s) => `चेक-इन रहते हुए ${s} से बाहर गया`,
    ur: (s) => `چیک اِن کے دوران ${s} سے باہر گیا`,
  },
  auto_checkout: {
    en: (s) => `Checked out automatically from ${s}`,
    ar: (s) => `تم تسجيل خروجه تلقائياً من ${s}`,
    hi: (s) => `${s} से अपने-आप चेक-आउट हुआ`,
    ur: (s) => `${s} سے خودکار طور پر چیک آؤٹ ہوا`,
  },
  silent: {
    en: () => "Phone stopped reporting. It may be switched off, offline, or the app was force-stopped.",
    ar: () => "توقف الهاتف عن الإرسال. قد يكون مغلقاً أو غير متصل أو تم إيقاف التطبيق.",
    hi: () => "फ़ोन ने रिपोर्ट करना बंद कर दिया। फ़ोन बंद, ऑफ़लाइन, या ऐप ज़बरदस्ती बंद हो सकता है।",
    ur: () => "فون نے رپورٹ کرنا بند کر دیا۔ ہو سکتا ہے فون بند ہو، آف لائن ہو یا ایپ زبردستی بند کی گئی ہو۔",
  },
  location_off: {
    en: () => "Location services turned OFF",
    ar: () => "تم إيقاف خدمة الموقع",
    hi: () => "लोकेशन सेवा बंद की गई",
    ur: () => "لوکیشن سروس بند کر دی گئی",
  },
  precise_off: {
    en: () => "Precise location turned off",
    ar: () => "تم إيقاف الموقع الدقيق",
    hi: () => "सटीक लोकेशन बंद की गई",
    ur: () => "درست لوکیشن بند کر دی گئی",
  },
  tracking_stopped: {
    en: () => "Location tracking stopped",
    ar: () => "توقف تتبع الموقع",
    hi: () => "लोकेशन ट्रैकिंग रुक गई",
    ur: () => "لوکیشن ٹریکنگ رک گئی",
  },
  mock_location: {
    en: () => "Fake GPS / mock location detected",
    ar: () => "تم اكتشاف موقع مزيّف",
    hi: () => "नकली GPS लोकेशन पकड़ी गई",
    ur: () => "جعلی GPS لوکیشن کا پتہ چلا",
  },
  permission_changed: {
    en: () => "Location permission changed",
    ar: () => "تم تغيير إذن الموقع",
    hi: () => "लोकेशन अनुमति बदली गई",
    ur: () => "لوکیشن کی اجازت تبدیل کی گئی",
  },
};

/** The Notifications switch each alert type belongs to; the rest are phone problems. */
const ALERT_GROUP: Record<string, string> = {
  left_site: "leftSite",
  auto_checkout: "autoCheckout",
};

/** At most one push per worker and alert type in this window. */
const THROTTLE_MIN = 15;

/** Site ids from `assignedProject` / `assignedMockup` (a map or a list of maps). */
function siteIds(user: FirebaseFirestore.DocumentData | undefined): Set<string> {
  const ids = new Set<string>();
  for (const field of ["assignedProject", "assignedMockup"]) {
    const v = user?.[field];
    for (const a of Array.isArray(v) ? v : [v]) {
      if (a && typeof a.id === "string") ids.add(a.id);
    }
  }
  return ids;
}

/** True the first time in THROTTLE_MIN for this worker and type. */
async function claimPushSlot(uid: string, type: string): Promise<boolean> {
  const db = getFirestore();
  const ref = db.collection("push_throttle").doc(`${uid}_${type}`);
  return db.runTransaction(async (tx) => {
    const last = (await tx.get(ref)).get("at") as Timestamp | undefined;
    if (last && Date.now() - last.toMillis() < THROTTLE_MIN * 60_000) return false;
    tx.set(ref, { at: Timestamp.now() });
    return true;
  });
}

/**
 * Serious phone/attendance alerts (`device_events`, written by the phones and
 * by the server) go to every active admin and to the active supervisors who
 * share a site with the worker. Tapping opens the worker's page.
 */
export const notifyAlert = onDocumentCreated("device_events/{id}", async (event) => {
  const e = event.data?.data();
  const texts = e ? ALERT_TEXT[e.type] : undefined;
  if (!e || !texts || e.severity === "info" || typeof e.uid !== "string") return;
  if (!(await claimPushSlot(e.uid, e.type))) return;

  const db = getFirestore();
  const worker = (await db.collection("users").doc(e.uid).get()).data();
  const workerSites = siteIds(worker);
  const [admins, supervisors] = await Promise.all([
    db.collection("users").where("roles", "array-contains", "isAdmin").get(),
    db.collection("users").where("roles", "array-contains", "isSupervisor").get(),
  ]);
  const recipients = new Map<string, FirebaseFirestore.DocumentSnapshot>();
  for (const a of admins.docs) recipients.set(a.id, a);
  for (const s of supervisors.docs) {
    if ([...siteIds(s.data())].some((id) => workerSites.has(id))) recipients.set(s.id, s);
  }

  const name = (e.userName as string | undefined)?.trim() ||
    `${worker?.firstName ?? ""} ${worker?.lastName ?? ""}`.trim() || "Worker";
  const site = (e.site as string | undefined) || "the site";
  let sent = 0;
  for (const r of recipients.values()) {
    if (r.get("isActive") !== true || r.id === e.uid) continue;
    if (!wants(r, ALERT_GROUP[e.type] ?? "phoneProblems")) continue;
    const text = texts[r.get("language")] ?? texts.en;
    try {
      sent += await pushToUser(r, name, text(site), { type: "alert", uid: e.uid });
    } catch (err) {
      logger.error(`notifyAlert: push to ${r.id} failed`, err);
    }
  }
  logger.info(`notifyAlert: ${e.type} for ${e.uid} → ${sent} phone(s) of ${recipients.size} recipient(s)`);
});

