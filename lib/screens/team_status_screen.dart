import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:royal_marble/core/l10n_helpers.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/roles.dart';
import '../models/device_status.dart';
import '../models/user_model.dart';
import '../widgets/status_widgets.dart';

String timeAgo(DateTime? t) {
  if (t == null) return 'never';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return DateFormat('d MMM, HH:mm').format(t);
}

/// Admin/supervisor view: every tracked phone's health, plus the live feed of
/// device events (location off, offline, silent, fake GPS…).
class TeamStatusScreen extends StatelessWidget {
  const TeamStatusScreen({super.key, required this.users, this.initialTab = 0});

  final List<UserData> users;
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Team status'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: AppColors.gold,
            tabs: [Tab(text: 'Phones'), Tab(text: 'Alerts')],
          ),
        ),
        body: TabBarView(children: [
          _PhonesTab(users: users),
          const AlertsFeed(),
        ]),
      ),
    );
  }
}

class _PhonesTab extends StatelessWidget {
  const _PhonesTab({required this.users});
  final List<UserData> users;

  @override
  Widget build(BuildContext context) {
    final tracked = users
        .where((u) =>
            u.isActive == true && !primaryRole(u.roles).canMonitor && u.error == null)
        .toList()
      ..sort((a, b) {
        final pa = DeviceStatus.fromMap(a.deviceStatus).problems.length;
        final pb = DeviceStatus.fromMap(b.deviceStatus).problems.length;
        return pb.compareTo(pa);
      });

    if (tracked.isEmpty) {
      return const Center(child: Text('No active workers'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tracked.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final u = tracked[i];
        final s = DeviceStatus.fromMap(u.deviceStatus);
        final problems = s.problems;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                    backgroundColor: !s.hasData
                        ? Tone.neutral.bg
                        : problems.isEmpty
                            ? Tone.ok.bg
                            : Tone.bad.bg,
                    child: Text(
                      '${u.firstName?.characters.firstOrNull ?? ''}${u.lastName?.characters.firstOrNull ?? ''}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: !s.hasData
                              ? Tone.neutral.fg
                              : problems.isEmpty
                                  ? Tone.ok.fg
                                  : Tone.bad.fg),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${u.firstName ?? ''} ${u.lastName ?? ''}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(
                          '${primaryRole(u.roles).localized(context.l10n)} · seen ${timeAgo(s.lastSeen)}',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  if (s.battery != null && s.battery! >= 0)
                    Row(children: [
                      Icon(
                          s.charging == true
                              ? Icons.battery_charging_full
                              : Icons.battery_std,
                          size: 18,
                          color: AppColors.muted),
                      Text('${(s.battery! * 100).round()}%',
                          style: const TextStyle(color: AppColors.muted)),
                    ]),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  if (!s.hasData)
                    const StatusPill('Not on the new app version yet',
                        tone: Tone.neutral, icon: Icons.help_outline)
                  else if (problems.isEmpty)
                    const StatusPill('All good',
                        tone: Tone.ok, icon: Icons.check_circle)
                  else
                    for (final p in problems)
                      StatusPill(p, tone: Tone.bad, icon: Icons.warning_amber),
                  if (s.lastAccuracy != null)
                    StatusPill('GPS ±${s.lastAccuracy!.round()} m',
                        tone: s.lastAccuracy! <= 30 ? Tone.neutral : Tone.warn),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Live list of `device_events`, newest first. Pass [uid] for one person.
class AlertsFeed extends StatelessWidget {
  const AlertsFeed({super.key, this.uid, this.limit = 200});
  final String? uid;
  final int limit;

  static Stream<List<DeviceEvent>> stream({int limit = 200}) =>
      FirebaseFirestore.instance
          .collection('device_events')
          .orderBy('at', descending: true)
          .limit(limit)
          .snapshots()
          .map((q) => q.docs.map(DeviceEvent.fromDoc).toList());

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DeviceEvent>>(
      stream: stream(limit: limit),
      builder: (context, snap) {
        if (snap.hasError) {
          final denied = '${snap.error}'.contains('permission-denied');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                denied
                    ? 'Alerts are not enabled on the server yet.'
                    : 'Could not load alerts. Check your connection.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final events =
            snap.data!.where((e) => uid == null || e.uid == uid).toList();
        if (events.isEmpty) {
          return const Center(child: Text('No alerts yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: events.length,
          separatorBuilder: (_, __) => const Divider(indent: 72),
          itemBuilder: (context, i) => AlertTile(events[i]),
        );
      },
    );
  }
}

class AlertTile extends StatelessWidget {
  const AlertTile(this.e, {super.key});
  final DeviceEvent e;

  static IconData iconFor(String type) => switch (type) {
        'location_off' || 'location_on' => Icons.location_off,
        'gps_off' || 'gps_on' => Icons.gps_off,
        'offline' || 'online' => Icons.cloud_off,
        'permission_changed' => Icons.lock_outline,
        'precise_off' || 'precise_on' => Icons.gps_not_fixed,
        'power_save_on' || 'power_save_off' => Icons.battery_saver,
        'battery_low' || 'battery_ok' => Icons.battery_alert,
        'mock_location' || 'mock_cleared' => Icons.report,
        'silent' => Icons.phonelink_off,
        'tracking_stopped' || 'tracking_started' => Icons.pause_circle,
        'device_boot' => Icons.restart_alt,
        'app_closed' => Icons.close,
        _ => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) {
    final tone = switch (e.severity) {
      'critical' => Tone.bad,
      'warning' => Tone.warn,
      _ => Tone.ok,
    };
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: tone.bg,
        child: Icon(iconFor(e.type), color: tone.fg, size: 20),
      ),
      title: Text(e.userName,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(e.message),
      trailing: Text(timeAgo(e.at),
          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    );
  }
}
