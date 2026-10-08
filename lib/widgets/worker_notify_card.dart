import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/error_reporter.dart';
import 'package:royal_marble/core/locale_controller.dart';

/// On a worker's page: which of this worker's alerts send a push to the
/// viewer. Stored on the viewer's profile as
/// `notifyAbout.{workerUid}.{group}`; a missing key means on. The server
/// checks these in `functions/src/notify.ts` (`SWITCHES`).
class WorkerNotifyCard extends StatelessWidget {
  const WorkerNotifyCard({super.key, required this.workerUid, required this.viewerUid});
  final String workerUid;
  final String viewerUid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('users').doc(viewerUid);

  Future<void> _set(BuildContext context, String group, bool on) async {
    try {
      await _doc.update({'notifyAbout.$workerUid.$group': on});
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.somethingWrong)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final groups = [
      ('checkInOut', Icons.login, l.notifyCheckInOut, l.notifyCheckInOutHint),
      ('presence', Icons.directions_walk, l.notifyGroupPresence, l.notifyGroupPresenceHint),
      ('location', Icons.location_off_outlined, l.notifyGroupLocation, null),
      ('connection', Icons.wifi_off, l.notifyGroupConnection, null),
      ('phoneSettings', Icons.settings_outlined, l.notifyGroupPhoneSettings,
          l.notifyGroupPhoneSettingsHint),
    ];
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _doc.snapshots(),
      builder: (context, snap) {
        final all = (snap.data?.data()?['notifyAbout'] as Map?) ?? const {};
        final prefs = (all[workerUid] as Map?) ?? const {};
        return Card(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(l.notifyAboutIntro,
                  style: const TextStyle(color: AppColors.muted)),
            ),
            for (final (key, icon, title, hint) in groups)
              SwitchListTile(
                secondary: Icon(icon, color: AppColors.goldDeep),
                title: Text(title),
                subtitle: hint == null ? null : Text(hint),
                value: prefs[key] != false,
                onChanged: snap.hasData ? (on) => _set(context, key, on) : null,
              ),
          ]),
        );
      },
    );
  }
}
