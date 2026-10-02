import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'error_reporter.dart';

/// `context.l10n.someKey` instead of `AppLocalizations.of(context).someKey`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The user's chosen language. Null means "follow the phone".
///
/// Stored on the device (works before sign-in) and copied to
/// `users/{uid}.language` so admins can see it and it follows the user to a
/// new phone.
class LocaleController extends ChangeNotifier {
  static const _prefKey = 'appLocale';

  /// Display order in the picker.
  static const supported = [
    Locale('en'),
    Locale('ar'),
    Locale('hi'),
    Locale('ur'),
  ];

  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> load() async {
    try {
      final code = (await SharedPreferences.getInstance()).getString(_prefKey);
      if (code != null) _locale = Locale(code);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> set(Locale locale) async {
    _locale = locale;
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance())
          .setString(_prefKey, locale.languageCode);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'language': locale.languageCode});
      }
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
    }
  }

  /// After sign-in: adopt the language saved on the profile if this phone
  /// has none yet (e.g. a new phone).
  Future<void> adoptFromProfile(String? code) async {
    if (_locale != null || code == null) return;
    if (!supported.any((l) => l.languageCode == code)) return;
    _locale = Locale(code);
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(_prefKey, code);
    } catch (_) {}
  }
}
