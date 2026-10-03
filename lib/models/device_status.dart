import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/app_localizations.dart';

enum ProblemKind {
  silent,
  locationOff,
  permission,
  trackingStopped,
  offline,
  approximate,
  batterySaver,
  lowBattery,
}

class DeviceProblem {
  final ProblemKind kind;
  final String? permission;
  final int? batteryPercent;
  const DeviceProblem(this.kind, {this.permission, this.batteryPercent});

  String text(AppLocalizations l) => switch (kind) {
        ProblemKind.silent => l.problemSilent,
        ProblemKind.locationOff => l.problemLocationOff,
        ProblemKind.permission =>
          l.problemPermission(permissionLabel(l, permission)),
        ProblemKind.trackingStopped => l.problemTrackingStopped,
        ProblemKind.offline => l.problemOffline,
        ProblemKind.approximate => l.problemApproximate,
        ProblemKind.batterySaver => l.problemBatterySaver,
        ProblemKind.lowBattery => l.problemBattery(batteryPercent ?? 0),
      };
}

/// Location permission values as written by the phone (`deviceStatus.permission`).
String permissionLabel(AppLocalizations l, String? value) => switch (value) {
      'always' => l.permAlways,
      'whenInUse' => l.permWhenInUse,
      'denied' => l.permDenied,
      'restricted' => l.permRestricted,
      _ => l.permNotDetermined,
    };

/// Snapshot of a worker's phone health, stored at `users/{uid}.deviceStatus`.
///
/// Written by the phone through `DeviceStatusReporter`; `lastSeen` is a server
/// timestamp so a scheduled Cloud Function can flag phones that stop reporting.
class DeviceStatus {
  final bool? locationEnabled;
  final bool? gps;
  final String? permission;
  final bool? preciseLocation;
  final bool? online;
  final bool? powerSave;
  final bool? trackingEnabled;
  final double? battery;
  final bool? charging;
  final bool silent;
  final DateTime? lastSeen;
  final DateTime? lastLocationAt;
  final double? lastAccuracy;

  const DeviceStatus({
    this.locationEnabled,
    this.gps,
    this.permission,
    this.preciseLocation,
    this.online,
    this.powerSave,
    this.trackingEnabled,
    this.battery,
    this.charging,
    this.silent = false,
    this.lastSeen,
    this.lastLocationAt,
    this.lastAccuracy,
  });

  factory DeviceStatus.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DeviceStatus();
    final lastLocation = map['lastLocation'] as Map<String, dynamic>?;
    return DeviceStatus(
      locationEnabled: map['locationEnabled'] as bool?,
      gps: map['gps'] as bool?,
      permission: map['permission'] as String?,
      preciseLocation: map['preciseLocation'] as bool?,
      online: map['online'] as bool?,
      powerSave: map['powerSave'] as bool?,
      trackingEnabled: map['trackingEnabled'] as bool?,
      battery: (map['battery'] as num?)?.toDouble(),
      charging: map['charging'] as bool?,
      silent: map['silent'] == true,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
      lastLocationAt: (lastLocation?['at'] as Timestamp?)?.toDate(),
      lastAccuracy: (lastLocation?['accuracy'] as num?)?.toDouble(),
    );
  }

  bool get hasData => lastSeen != null;

  /// Problems an admin should act on, most severe first. Use
  /// [DeviceProblem.text] to show one in the user's language.
  List<DeviceProblem> get problems => [
        if (silent) const DeviceProblem(ProblemKind.silent),
        if (locationEnabled == false) const DeviceProblem(ProblemKind.locationOff),
        if (permission != null && permission != 'always')
          DeviceProblem(ProblemKind.permission, permission: permission),
        if (trackingEnabled == false)
          const DeviceProblem(ProblemKind.trackingStopped),
        if (online == false) const DeviceProblem(ProblemKind.offline),
        if (preciseLocation == false)
          const DeviceProblem(ProblemKind.approximate),
        if (powerSave == true) const DeviceProblem(ProblemKind.batterySaver),
        if (battery != null && battery! >= 0 && battery! < 0.15 && charging != true)
          DeviceProblem(ProblemKind.lowBattery,
              batteryPercent: (battery! * 100).round()),
      ];

  bool get healthy => hasData && problems.isEmpty;
}

/// One entry in the `device_events` collection.
class DeviceEvent {
  final String id;
  final String uid;
  final String userName;
  final String type;
  final String message;
  final String severity;
  final DateTime? at;

  /// Site name for attendance alerts (left site, auto check-out).
  final String? site;

  const DeviceEvent({
    required this.id,
    required this.uid,
    required this.userName,
    required this.type,
    required this.message,
    required this.severity,
    this.at,
    this.site,
  });

  factory DeviceEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return DeviceEvent(
      id: doc.id,
      uid: d['uid'] ?? '',
      userName: d['userName'] ?? 'Unknown',
      type: d['type'] ?? '',
      message: d['message'] ?? '',
      severity: d['severity'] ?? 'info',
      at: ((d['at'] ?? d['receivedAt']) as Timestamp?)?.toDate(),
      site: d['site'] as String?,
    );
  }
}
