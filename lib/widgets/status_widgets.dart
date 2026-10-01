import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart' as ph;

import '../core/app_theme.dart';
import '../services/tracking_service.dart';

enum Tone { ok, warn, bad, neutral }

extension ToneColors on Tone {
  Color get fg => switch (this) {
        Tone.ok => AppColors.ok,
        Tone.warn => AppColors.warn,
        Tone.bad => AppColors.bad,
        Tone.neutral => AppColors.muted,
      };
  Color get bg => switch (this) {
        Tone.ok => AppColors.okSoft,
        Tone.warn => AppColors.warnSoft,
        Tone.bad => AppColors.badSoft,
        Tone.neutral => const Color(0xFFF0EEE7),
      };
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.tone = Tone.neutral, this.icon});
  final String label;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: tone.fg),
          const SizedBox(width: 4),
        ],
        Text(label,
            style: TextStyle(
                color: tone.fg, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(children: [
        Expanded(
          child: Text(text.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted)),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class _Issue {
  final IconData icon;
  final String title;
  final String detail;
  final Tone tone;
  final String? action;
  final Future<void> Function()? onAction;
  const _Issue(this.icon, this.title, this.detail, this.tone,
      [this.action, this.onAction]);
}

/// Tells the worker, in plain words, anything that stops tracking or
/// check-in from working, with a button that fixes it where possible.
class DeviceStatusBanner extends StatefulWidget {
  const DeviceStatusBanner({super.key});

  @override
  State<DeviceStatusBanner> createState() => _DeviceStatusBannerState();
}

class _DeviceStatusBannerState extends State<DeviceStatusBanner>
    with WidgetsBindingObserver {
  bool? _batteryOptimized;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the settings app: re-read everything.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final provider = await bg.BackgroundGeolocation.providerState;
      await TrackingService.handleEvent(bg.Event.PROVIDERCHANGE, provider);
      final ignoring =
          await bg.DeviceSettings.isIgnoringBatteryOptimizations;
      if (mounted) setState(() => _batteryOptimized = !ignoring);
    } catch (_) {}
  }

  List<_Issue> _issues(LiveDeviceState s) => [
        if (s.locationEnabled == false)
          _Issue(Icons.location_off, 'Location is turned off',
              'Your admin has been notified. Turn it on to continue.', Tone.bad,
              'Turn on', () async => geo.Geolocator.openLocationSettings()),
        if (s.authorization != null && !s.hasAlwaysPermission)
          _Issue(
              Icons.lock_outline,
              'Allow location "All the time"',
              'Needed so check-in works when the app is closed.',
              Tone.bad,
              'Fix', () async {
            final status = await bg.BackgroundGeolocation.requestPermission()
                .catchError((_) => -1);
            if (status != bg.Config.AUTHORIZATION_STATUS_ALWAYS) {
              await ph.openAppSettings();
            }
          }),
        if (s.preciseLocation == false)
          _Issue(Icons.gps_not_fixed, 'Precise location is off',
              'Turn on "Use precise location" for this app.', Tone.bad,
              'Settings', () async => ph.openAppSettings()),
        if (s.online == false)
          const _Issue(Icons.cloud_off, 'No internet connection',
              'Location is saved and will upload when you reconnect.',
              Tone.warn),
        if (s.powerSave == true)
          const _Issue(Icons.battery_saver, 'Battery saver is on',
              'Tracking may be delayed. Turn it off during work hours.',
              Tone.warn),
        if (_batteryOptimized == true)
          _Issue(
              Icons.battery_alert,
              'Battery optimization is on',
              'Your phone may stop tracking in the background.',
              Tone.warn,
              'Allow', () async {
            final req = await bg.DeviceSettings.showIgnoreBatteryOptimizations();
            await bg.DeviceSettings.show(req);
          }),
      ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LiveDeviceState>(
      valueListenable: TrackingService.state,
      builder: (context, s, _) {
        final issues = _issues(s);
        if (issues.isEmpty) {
          final acc = s.lastLocation?.coords.accuracy;
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.okSoft,
                child: Icon(Icons.my_location, color: AppColors.ok),
              ),
              title: const Text('Tracking is active'),
              subtitle: Text(acc == null
                  ? 'Waiting for GPS…'
                  : 'GPS accuracy ±${acc.round()} m'),
            ),
          );
        }
        return Column(
          children: [
            for (final i in issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: i.tone.bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Row(children: [
                    Icon(i.icon, color: i.tone.fg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: i.tone.fg)),
                          const SizedBox(height: 2),
                          Text(i.detail,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.ink)),
                        ],
                      ),
                    ),
                    if (i.action != null)
                      TextButton(
                        onPressed: () async {
                          await i.onAction!();
                          await _refresh();
                        },
                        child: Text(i.action!,
                            style: TextStyle(
                                color: i.tone.fg,
                                fontWeight: FontWeight.w700)),
                      ),
                  ]),
                ),
              ),
          ],
        );
      },
    );
  }
}
