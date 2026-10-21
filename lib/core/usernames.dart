/// People added by an admin or HR sign in with a username instead of an
/// email. Firebase still needs an email, so a username is stored as
/// `<username>@` [usernameDomain], which can never receive mail. Keep in step
/// with `USERNAME_DOMAIN` in functions/src/accounts.ts.
const usernameDomain = 'staff.royalmarble.test';

final _usernamePattern = RegExp(r'^[a-z0-9]+(\.[a-z0-9]+)*$');

/// first.last: 3–30 lowercase letters and digits in parts joined by dots.
bool validUsername(String u) =>
    u.length >= 3 && u.length <= 30 && _usernamePattern.hasMatch(u);

/// What the sign-in field holds as Firebase's email: an email as typed, or a
/// username with the hidden domain added.
String signInEmail(String input) {
  final v = input.trim();
  return v.contains('@') ? v : '${v.toLowerCase()}@$usernameDomain';
}

/// Accounts with a username get no reset emails.
bool isUsernameEmail(String? email) =>
    email?.toLowerCase().endsWith('@$usernameDomain') == true;

List<String> _words(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9 ]+'), ' ')
    .trim()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .toList();

/// "Ravi Shankar", "Kumar" → "ravi.kumar"; empty without Latin letters. The
/// server adds 2, 3… if the name is taken.
String suggestUsername(String first, String last) {
  final f = _words(first), l = _words(last);
  final s = [if (f.isNotEmpty) f.first, if (l.isNotEmpty) l.last].join('.');
  return s.length > 26 ? s.substring(0, 26) : s;
}
