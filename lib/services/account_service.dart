import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/error_reporter.dart';
import '../core/roles.dart';
import '../l10n/app_localizations.dart';

/// Accounts that admins and HR add (username sign-in) and passwords.
class AccountService {
  /// The server's reason for a refusal, in the user's language.
  static String _message(AppLocalizations l, FirebaseFunctionsException e) =>
      switch ((e.details as Map?)?['reason']) {
        'username_taken' => l.errUsernameTaken,
        'bad_username' => l.usernameInvalid,
        'username_needed' => l.errUsernameNeeded,
        'weak_password' => l.passwordTooShort,
        'role_admin_only' => l.errRoleAdminOnly,
        _ when e.code == 'unavailable' => l.errNoInternet,
        _ => l.errAccountGeneric,
      };

  /// Creates an active account; returns (username, null) or (null, error).
  /// An empty [username] lets the server pick first.last (then …2, …3).
  static Future<(String?, String?)> create(
    AppLocalizations l, {
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required AppRole role,
    required String username,
    required String password,
  }) async {
    try {
      final res = await FirebaseFunctions.instance
          .httpsCallable('createUserAccount')
          .call<Map<String, dynamic>>({
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'role': role.key,
        'username': username,
        'password': password,
      });
      return ('${res.data['username']}', null);
    } on FirebaseFunctionsException catch (e) {
      return (null, _message(l, e));
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      return (null, l.errAccountGeneric);
    }
  }

  /// Admins and HR set someone's password; returns null or an error.
  static Future<String?> setPassword(AppLocalizations l,
      {required String uid, required String password}) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('setUserPassword')
          .call<Map<String, dynamic>>({'uid': uid, 'password': password});
      return null;
    } on FirebaseFunctionsException catch (e) {
      return _message(l, e);
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      return l.errAccountGeneric;
    }
  }

  /// Whether the signed-in person has a password (not only Google/Apple).
  static bool get hasPassword =>
      FirebaseAuth.instance.currentUser?.providerData
          .any((p) => p.providerId == 'password') ==
      true;

  /// The signed-in person changes their own password; returns null or an error.
  static Future<String?> changeOwn(AppLocalizations l,
      {required String current, required String next}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return l.errAccountGeneric;
    try {
      // Firebase asks for a recent sign-in before a password change.
      await user!.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: current));
      await user.updatePassword(next);
      return null;
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'wrong-password' || 'invalid-credential' => l.errCurrentPasswordWrong,
        'weak-password' => l.passwordTooShort,
        'network-request-failed' => l.errNoInternet,
        'too-many-requests' => l.errTooManyRequests,
        _ => l.errAccountGeneric,
      };
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      return l.errAccountGeneric;
    }
  }
}
