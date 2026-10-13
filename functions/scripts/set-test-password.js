/**
 * Sets a new password for a TEST account (email on @royalmarble.test), whose
 * "Forgot password" email can't be received. Refuses any other address so a
 * real user's password can't be changed by mistake.
 *
 * The password is typed at a hidden prompt (twice): it never goes into a
 * file, the shell history or the command line.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=<key.json> node scripts/set-test-password.js \
 *     --project royal-marble quiet.tester@royalmarble.test
 */
const readline = require("readline");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

const args = process.argv.slice(2);
const projectArg = args[args.indexOf("--project") + 1];
const email = args.find((a) => a.includes("@"));
if (!args.includes("--project") || !projectArg || !email) {
  console.error("Usage: node scripts/set-test-password.js --project <id> <email>");
  process.exit(1);
}
if (!email.toLowerCase().endsWith("@royalmarble.test")) {
  console.error(`Refused: ${email} is not a @royalmarble.test test account.`);
  process.exit(1);
}

// One reader for every prompt, and lines are queued as they arrive, so
// nothing typed (or pasted) before a prompt appears is lost.
const rl = readline.createInterface({ input: process.stdin, output: process.stdout, terminal: true });
rl._writeToOutput = () => {}; // never echo what is typed
const lines = [];
let waiting = null;
let ended = false;
rl.on("line", (l) => (waiting ? (waiting.resolve(l), (waiting = null)) : lines.push(l)));
rl.on("close", () => {
  ended = true;
  if (waiting) waiting.reject(new Error("No input; nothing changed."));
});

/** Reads a line without echoing what is typed. */
function hidden(question) {
  process.stdout.write(question);
  return new Promise((resolve, reject) => {
    const done = (l) => { process.stdout.write("\n"); resolve(l); };
    if (lines.length) return done(lines.shift());
    if (ended) return reject(new Error("No input; nothing changed."));
    waiting = { resolve: done, reject };
  });
}

async function main() {
  initializeApp({ projectId: projectArg });
  const user = await getAuth().getUserByEmail(email);
  console.log(`Account: ${user.email} (uid ${user.uid}, ${user.displayName ?? "no display name"})`);
  const pw = await hidden("New password (hidden): ");
  if (pw.length < 8) throw new Error("Use at least 8 characters.");
  if ((await hidden("Repeat it (hidden): ")) !== pw) throw new Error("The two passwords don't match.");
  await getAuth().updateUser(user.uid, { password: pw });
  rl.close();
  console.log("Password changed. Sign in with it on the phone.");
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
