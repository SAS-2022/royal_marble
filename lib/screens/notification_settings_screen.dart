import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/error_reporter.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:royal_marble/models/user_model.dart';

/// Which alerts send a push to this account. Stored as
/// `users/{uid}.notify.{key}`; a missing key means on. The server checks
/// these in `functions/src/notify.ts`. Alerts always stay in the app.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, required this.user, required this.isAdmin});
  final UserData user;
  final bool isAdmin;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late final _doc =
      FirebaseFirestore.instance.collection('users').doc(widget.user.uid);
  late final _blocked = FirebaseMessaging.instance
      .getNotificationSettings()
      .then((s) => s.authorizationStatus == AuthorizationStatus.denied);

  Future<void> _set(String key, bool on) async {
    try {
      await _doc.update({'notify.$key': on});
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.somethingWrong)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final options = [
      // Only admins get new sign-ups.
      if (widget.isAdmin)
        ('newUsers', Icons.person_add_alt, l.notifyNewUsers, null),
      ('leftSite', Icons.directions_walk, l.notifyLeftSite, null),
      ('autoCheckout', Icons.timer_off_outlined, l.notifyAutoCheckout, null),
      ('phoneProblems', Icons.phonelink_erase, l.phoneProblems, l.notifyPhoneProblemsHint),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.notifications)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _doc.snapshots(),
        builder: (context, snap) {
          final prefs = (snap.data?.data()?['notify'] as Map?) ?? const {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l.notificationsIntro,
                  style: const TextStyle(color: AppColors.muted)),
              FutureBuilder<bool>(
                future: _blocked,
                builder: (context, b) => b.data == true
                    ? Card(
                        color: AppColors.badSoft,
                        margin: const EdgeInsets.only(top: 12),
                        child: ListTile(
                          leading: const Icon(Icons.notifications_off,
                              color: AppColors.bad),
                          title: Text(l.notificationsBlocked),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(children: [
                  for (final (i, (key, icon, title, hint)) in options.indexed) ...[
                    if (i > 0) const Divider(indent: 16, endIndent: 16),
                    SwitchListTile(
                      secondary: Icon(icon, color: AppColors.goldDeep),
                      title: Text(title),
                      subtitle: hint == null ? null : Text(hint),
                      value: prefs[key] != false,
                      onChanged: snap.hasData ? (on) => _set(key, on) : null,
                    ),
                  ],
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}
