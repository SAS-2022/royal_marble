import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onDocumentDeleted } from "firebase-functions/v2/firestore";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";

/**
 * Accounts made with a username sign in with `<username>@` this domain. `.test`
 * can never receive mail, so these accounts have no reset emails: admins and
 * HR set new passwords instead. Keep in step with lib/core/usernames.dart.
 */
export const USERNAME_DOMAIN = "staff.royalmarble.test";

/** first.last: lowercase letters and digits in parts joined by single dots. */
const USERNAME_RE = /^[a-z0-9]+(\.[a-z0-9]+)*$/;
export const validUsername = (u: string) => u.length >= 3 && u.length <= 30 && USERNAME_RE.test(u);

/** Latin letters and digits of a name, lowercase ("José" → "jose"). */
const plain = (s: string) => s.normalize("NFD").replace(/[̀-ͯ]/g, "")
  .toLowerCase().replace(/[^a-z0-9 ]+/g, " ").trim().split(/\s+/).filter(Boolean);

/** "Ravi Shankar", "Kumar" → "ravi.kumar"; empty if the name has no Latin letters. */
export function suggestUsername(first: string, last: string): string {
  const f = plain(first)[0] ?? "";
  const l = plain(last).at(-1) ?? "";
  return [f, l].filter(Boolean).join(".").slice(0, 26);
}

/** Roles only an admin can give (same as the role chips in the app). */
const ADMIN_ONLY_ROLES = ["isAdmin", "isHR", "isCoordinator"];
const ROLES = ["isAdmin", "isHR", "isCoordinator", "isSupervisor", "isSales", "isSiteEngineer", "isNormalUser"];

const fail = (code: "permission-denied" | "invalid-argument" | "already-exists" | "not-found",
  message: string, reason: string) => new HttpsError(code, message, { reason });

/** The caller's profile if they are an active admin or HR; throws otherwise. */
async function staffCaller(req: CallableRequest<unknown>) {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Please sign in again.", { reason: "sign_in_again" });
  const me = (await getFirestore().collection("users").doc(uid).get()).data();
  const roles: string[] = Array.isArray(me?.roles) ? me.roles : [];
  if (me?.isActive !== true || !(roles.includes("isAdmin") || roles.includes("isHR"))) {
    throw fail("permission-denied", "Only admins and HR can manage accounts.", "not_staff");
  }
  return { uid, isAdmin: roles.includes("isAdmin"), name: `${me.firstName ?? ""} ${me.lastName ?? ""}`.trim() };
}

const checkPassword = (p: unknown): string => {
  if (typeof p !== "string" || p.length < 6 || p.length > 64) {
    throw fail("invalid-argument", "The password needs at least 6 characters.", "weak_password");
  }
  return p;
};

interface NewAccount {
  firstName: string;
  lastName: string;
  phoneNumber?: string;
  role: string;
  /** Empty: the server picks first.last (then first.last2, …). */
  username?: string;
  password: string;
}

/**
 * Admins and HR add a person who signs in with a username. The account is
 * active at once (no approval) and the username is reserved in
 * `usernames/{username}`. Returns the username given.
 */
export const createUserAccount = onCall(async (req: CallableRequest<NewAccount>) => {
  const caller = await staffCaller(req);
  const d = req.data ?? ({} as NewAccount);
  const firstName = `${d.firstName ?? ""}`.trim();
  const lastName = `${d.lastName ?? ""}`.trim();
  if (!firstName || !lastName) throw fail("invalid-argument", "First and last name are needed.", "name_missing");
  if (!ROLES.includes(d.role)) throw fail("invalid-argument", "Unknown role.", "bad_role");
  if (ADMIN_ONLY_ROLES.includes(d.role) && !caller.isAdmin) {
    throw fail("permission-denied", "Only an admin can give this role.", "role_admin_only");
  }
  const password = checkPassword(d.password);
  const typed = `${d.username ?? ""}`.trim().toLowerCase();
  if (typed && !validUsername(typed)) throw fail("invalid-argument", "Invalid username.", "bad_username");
  const base = typed || suggestUsername(firstName, lastName);
  if (!validUsername(base)) throw fail("invalid-argument", "Type a username.", "username_needed");

  const db = getFirestore();
  const auth = getAuth();
  // A typed name is taken or not; a suggested one moves on to name2, name3…
  for (let n = 1; n <= (typed ? 1 : 50); n++) {
    const username = n === 1 ? base : `${base}${n}`;
    const nameRef = db.collection("usernames").doc(username);
    if ((await nameRef.get()).exists) continue;
    let uid: string;
    try {
      uid = (await auth.createUser({
        email: `${username}@${USERNAME_DOMAIN}`, password, displayName: `${firstName} ${lastName}`,
      })).uid;
    } catch (e) {
      if ((e as { code?: string }).code === "auth/email-already-exists") continue;
      throw e;
    }
    try {
      await db.runTransaction(async (tx) => {
        if ((await tx.get(nameRef)).exists) throw new Error("taken");
        tx.create(nameRef, { uid, at: FieldValue.serverTimestamp() });
        tx.create(db.collection("users").doc(uid), {
          firstName, lastName,
          phoneNumber: `${d.phoneNumber ?? ""}`.trim() || null,
          emailAddress: null,
          username,
          roles: [d.role],
          isActive: true,
          createdBy: caller.uid,
          createdByName: caller.name,
          createdAt: FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      await auth.deleteUser(uid);
      if ((e as Error).message === "taken") continue;
      throw e;
    }
    logger.info("account created", { uid, username, by: caller.uid });
    return { uid, username };
  }
  throw fail("already-exists", "That username is taken.", "username_taken");
});

/**
 * Admins and HR set someone's password (username accounts get no reset
 * emails). Admin, HR and coordinator accounts: admins only.
 */
export const setUserPassword = onCall(async (req: CallableRequest<{ uid: string; password: string }>) => {
  const caller = await staffCaller(req);
  const uid = `${req.data?.uid ?? ""}`;
  const password = checkPassword(req.data?.password);
  const target = uid ? (await getFirestore().collection("users").doc(uid).get()).data() : undefined;
  if (!target) throw fail("not-found", "No such user.", "no_user");
  const roles: string[] = Array.isArray(target.roles) ? target.roles : [];
  if (!caller.isAdmin && roles.some((r) => ADMIN_ONLY_ROLES.includes(r))) {
    throw fail("permission-denied", "Only an admin can change this person's password.", "role_admin_only");
  }
  await getAuth().updateUser(uid, { password });
  logger.info("password set", { uid, by: caller.uid });
  return { ok: true };
});

/** Deleting a username account's profile frees the name and removes its login. */
export const releaseUsername = onDocumentDeleted("users/{uid}", async (event) => {
  const username = event.data?.get("username");
  if (typeof username !== "string") return;
  const db = getFirestore();
  const ref = db.collection("usernames").doc(username);
  if ((await ref.get()).get("uid") === event.params.uid) await ref.delete();
  try {
    const user = await getAuth().getUser(event.params.uid);
    if (user.email?.endsWith(`@${USERNAME_DOMAIN}`)) await getAuth().deleteUser(event.params.uid);
  } catch (e) {
    if ((e as { code?: string }).code !== "auth/user-not-found") throw e;
  }
});
