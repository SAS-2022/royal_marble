import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Problems an admin should act on, most severe first.
  List<String> get problems => [
        if (silent) 'Not reporting',
        if (locationEnabled == false) 'Location off',
        if (permission != null && permission != 'always') 'Permission: $permission',
        if (trackingEnabled == false) 'Tracking stopped',
        if (online == false) 'Offline',
        if (preciseLocation == false) 'Approximate location',
        if (powerSave == true) 'Battery saver on',
        if (battery != null && battery! >= 0 && battery! < 0.15 && charging != true)
          'Battery ${(battery! * 100).round()}%',
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

  const DeviceEvent({
    required this.id,
    required this.uid,
    required this.userName,
    required this.type,
    required this.message,
    required this.severity,
    this.at,
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
    );
  }
}
