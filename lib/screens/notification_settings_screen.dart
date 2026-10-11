import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/error_reporter.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/widgets/time_wheel_picker.dart';

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

  /// Saves `quietHours` = `{on, from, to, offsetMin}` (minutes of the day in
  /// this phone's time zone, which the server needs to know when it's night).
  Future<void> _setQuiet(bool on, int from, int to) async {
    try {
      await _doc.update({
        'quietHours': {
          'on': on,
          'from': from,
          'to': to,
          'offsetMin': DateTime.now().timeZoneOffset.inMinutes,
        }
      });
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.somethingWrong)));
      }
    }
  }

  Widget _quietHours(Map quiet, bool ready) {
    final l = context.l10n;
    final on = quiet['on'] == true;
    final from = (quiet['from'] as num?)?.toInt() ?? 22 * 60;
    final to = (quiet['to'] as num?)?.toInt() ?? 7 * 60;
    String fmt(int m) => MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: m ~/ 60, minute: m % 60));
    Future<void> pick(bool isFrom) async {
      final current = isFrom ? from : to;
      final t = await showTimeWheel(context,
          initial: TimeOfDay(hour: current ~/ 60, minute: current % 60),
          title: isFrom ? l.quietFrom : l.quietTo);
      if (t == null) return;
      final m = t.hour * 60 + t.minute;
      await _setQuiet(true, isFrom ? m : from, isFrom ? to : m);
    }

    return Card(
      child: Column(children: [
        SwitchListTile(
          secondary: const Icon(Icons.bedtime_outlined, color: AppColors.goldDeep),
          title: Text(l.quietHours),
          subtitle: Text(l.quietHoursHint),
          value: on,
          onChanged: ready ? (v) => _setQuiet(v, from, to) : null,
        ),
        if (on) ...[
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(l.quietFrom),
            trailing: Text(fmt(from),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => pick(true),
          ),
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(l.quietTo),
            trailing: Text(fmt(to),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => pick(false),
          ),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final options = [
      // Only admins get new sign-ups.
      if (widget.isAdmin)
        ('newUsers', Icons.person_add_alt, l.notifyNewUsers, null),
      ('checkInOut', Icons.login, l.notifyCheckInOut, l.notifyCheckInOutHint),
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
              const SizedBox(height: 12),
              _quietHours(
                  (snap.data?.data()?['quietHours'] as Map?) ?? const {}, snap.hasData),
            ],
          );
        },
      ),
    );
  }
}
