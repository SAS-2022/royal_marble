import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Single entry point for reporting problems to Firebase Crashlytics.
///
/// Call sites only ever use [record] and [message], so the backend can change
/// without touching the rest of the app.
class ErrorReporter {
  ErrorReporter._();

  static FirebaseCrashlytics get _c => FirebaseCrashlytics.instance;

  /// Reports a caught error as a non-fatal.
  static Future<void> record(Object error,
      {StackTrace? stackTrace, String? reason}) async {
    if (kDebugMode) debugPrint('[ErrorReporter] $error\n$stackTrace');
    try {
      await _c.recordError(error, stackTrace, reason: reason);
    } catch (_) {
      // Reporting must never throw into the caller.
    }
  }

  /// Reports a non-exception problem (an unexpected state worth knowing about).
  static Future<void> message(String text) async {
    if (kDebugMode) debugPrint('[ErrorReporter] $text');
    try {
      _c.log(text);
      await _c.recordError(StateError(text), StackTrace.current,
          reason: 'message');
    } catch (_) {}
  }

  /// Tags subsequent reports with who was signed in.
  static Future<void> setUser({String? uid, String? role}) async {
    try {
      await _c.setUserIdentifier(uid ?? '');
      await _c.setCustomKey('role', role ?? 'none');
    } catch (_) {}
  }
}
