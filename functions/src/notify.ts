import { FieldValue, getFirestore } from "firebase-admin/firestore";
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
