import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:royal_marble/account_settings/admin_user_view.dart';
import 'package:royal_marble/core/error_reporter.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:royal_marble/core/roles.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';

/// Push notifications (FCM). Admins and supervisors save this phone's token
/// in `users/{uid}.fcmTokens`; the server (`functions/src/notify.ts`) sends to
/// those tokens. Tapping a notification opens the matching screen.
class PushService {
  PushService._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static UserData? _viewer;
  static bool _listening = false;
  static StreamSubscription<String>? _refresh;

  /// Called by the wrapper for every signed-in profile; only people who get
  /// alerts are registered (and asked for the notification permission).
  static Future<void> start(UserData user) async {
    if (user.isActive != true || !primaryRole(user.roles).canMonitor) return;
    final firstTime = _viewer?.uid != user.uid;
    _viewer = user;
    if (!firstTime) return;
    try {
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();
      final token = await fm.getToken();
      if (token != null) await _save(token);
      await _refresh?.cancel();
      _refresh = fm.onTokenRefresh.listen(_save);

      if (!_listening) {
        _listening = true;
        FirebaseMessaging.onMessageOpenedApp.listen(_open);
        FirebaseMessaging.onMessage.listen(_showInApp);
        // The app was started by tapping a notification.
        final initial = await fm.getInitialMessage();
        if (initial != null) _open(initial);
      }
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
    }
  }

  /// Before sign-out: this phone stops getting the person's notifications.
  static Future<void> stop() async {
    final uid = _viewer?.uid;
    _viewer = null;
    await _refresh?.cancel();
    _refresh = null;
    if (uid == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
    }
  }

  static Future<void> _save(String token) async {
    final uid = _viewer?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  /// Android shows nothing for a message that arrives while the app is open,
  /// so show it as a snack bar with a shortcut.
  static void _showInApp(RemoteMessage m) {
    final n = m.notification;
    final messenger = messengerKey.currentState;
    final context = messengerKey.currentContext;
    if (n == null || messenger == null || context == null) return;
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      content: Text([n.title, n.body].whereType<String>().join('\n')),
      action: _canOpen(m)
          ? SnackBarAction(label: context.l10n.details, onPressed: () => _open(m))
          : null,
    ));
  }

  static bool _canOpen(RemoteMessage m) =>
      m.data['type'] == 'new_user' && m.data['uid'] != null;

  static Future<void> _open(RemoteMessage m) async {
    final viewer = _viewer;
    if (!_canOpen(m) || viewer == null) return;
    try {
      final user = await DatabaseService().getUserPerId(uid: m.data['uid']).first;
      await navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => UserAdminScreen(user: user, viewer: viewer),
      ));
    } catch (e, st) {
      // The account may have been deleted since.
      await ErrorReporter.record(e, stackTrace: st);
    }
  }
}
