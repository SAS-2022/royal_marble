import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// What the phone currently knows about its own tracking health.
/// Drives the status banner on the worker's home screen.
@immutable
class LiveDeviceState {
  final bool? locationEnabled;
  final bool? gps;
  final int? authorization;
  final bool? preciseLocation;
  final bool? online;
  final bool? powerSave;
  final bool? trackingEnabled;
  final bg.Location? lastLocation;

  const LiveDeviceState({
    this.locationEnabled,
    this.gps,
    this.authorization,
    this.preciseLocation,
    this.online,
    this.powerSave,
    this.trackingEnabled,
    this.lastLocation,
  });

  bool get hasAlwaysPermission =>
      authorization == bg.Config.AUTHORIZATION_STATUS_ALWAYS;

  LiveDeviceState copyWith({
    bool? locationEnabled,
    bool? gps,
    int? authorization,
    bool? preciseLocation,
    bool? online,
    bool? powerSave,
    bool? trackingEnabled,
    bg.Location? lastLocation,
  }) =>
      LiveDeviceState(
        locationEnabled: locationEnabled ?? this.locationEnabled,
        gps: gps ?? this.gps,
        authorization: authorization ?? this.authorization,
        preciseLocation: preciseLocation ?? this.preciseLocation,
        online: online ?? this.online,
        powerSave: powerSave ?? this.powerSave,
        trackingEnabled: trackingEnabled ?? this.trackingEnabled,
        lastLocation: lastLocation ?? this.lastLocation,
      );
}

/// Owns background location tracking for the signed-in user.
///
/// The same [handleEvent] path runs in the foreground app and in the headless
/// task (app swiped away / phone rebooted), so status changes are recorded
/// either way. Only *transitions* are logged to `device_events`; steady-state
/// readings just refresh `users/{uid}.deviceStatus`.
class TrackingService {
  TrackingService._();

  static final ValueNotifier<LiveDeviceState> state =
      ValueNotifier(const LiveDeviceState());

  static bool _listenersAttached = false;

  static const _prefUserId = 'userId';
  static const _prefUserName = 'userName';
  static const _prefProject = 'trackedProject';

  /// Starts tracking for [user]. Safe to call repeatedly (e.g. on every
  /// rebuild of the home screen); work is only redone when needed.
  static Future<void> start(UserData user) async {
    if (user.uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefUserId, user.uid!);
    await prefs.setString(
        _prefUserName, '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim());
    await rememberProject(user.assignedProject);

    if (!_listenersAttached) {
      _listenersAttached = true;
      bg.BackgroundGeolocation.onLocation(
          (l) => handleEvent(bg.Event.LOCATION, l),
          (e) => Sentry.captureMessage('bg location error: ${e.code}'));
      bg.BackgroundGeolocation.onMotionChange(
          (l) => handleEvent(bg.Event.MOTIONCHANGE, l));
      bg.BackgroundGeolocation.onProviderChange(
          (e) => handleEvent(bg.Event.PROVIDERCHANGE, e));
      bg.BackgroundGeolocation.onConnectivityChange(
          (e) => handleEvent(bg.Event.CONNECTIVITYCHANGE, e));
      bg.BackgroundGeolocation.onPowerSaveChange(
          (e) => handleEvent(bg.Event.POWERSAVECHANGE, e));
      bg.BackgroundGeolocation.onEnabledChange(
          (e) => handleEvent(bg.Event.ENABLEDCHANGE, e));
      bg.BackgroundGeolocation.onHeartbeat(
          (e) => handleEvent(bg.Event.HEARTBEAT, e));
    }

    try {
      final s = await bg.BackgroundGeolocation.ready(_config());
      if (!s.enabled) await bg.BackgroundGeolocation.start();
      state.value = state.value.copyWith(trackingEnabled: true);
      // Seed the banner and the server copy with the current provider state.
      await handleEvent(bg.Event.PROVIDERCHANGE,
          await bg.BackgroundGeolocation.providerState);
    } catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
    }
  }

  /// Stops tracking and forgets the user (sign-out).
  static Future<void> stop() async {
    try {
      await bg.BackgroundGeolocation.stop();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefUserId);
    await prefs.remove(_prefUserName);
    await prefs.remove(_prefProject);
    for (final k in prefs.getKeys().where((k) => k.startsWith('ds.'))) {
      await prefs.remove(k);
    }
  }

  /// Caches the assigned project's centre and radius so the headless task
  /// can compute distance-to-site without reading Firestore.
  static Future<void> rememberProject(dynamic assignedProject) async {
    final prefs = await SharedPreferences.getInstance();
    if (assignedProject is Map &&
        assignedProject['projectAddress'] is Map &&
        assignedProject['radius'] != null) {
      final a = assignedProject['projectAddress'];
      await prefs.setStringList(_prefProject, [
        '${a['Lat']}',
        '${a['Lng']}',
        '${assignedProject['radius']}',
      ]);
    } else {
      await prefs.remove(_prefProject);
    }
  }

  static bg.Config _config() => bg.Config(
        reset: true,
        debug: false,
        logLevel: bg.Config.LOG_LEVEL_ERROR,
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 15.0,
        stopTimeout: 5,
        // Lets the server tell "stationary but alive" from "phone went dark".
        heartbeatInterval: 300,
        stopOnTerminate: false,
        startOnBoot: true,
        enableHeadless: true,
        locationAuthorizationRequest: 'Always',
        backgroundPermissionRationale: bg.PermissionRationale(
          title:
              "Allow {applicationName} to use your location while you're at work",
          message:
              'Royal Marble checks you in and out of your assigned site automatically, even when the app is closed.',
          positiveAction: 'Change to "{backgroundPermissionOptionLabel}"',
          negativeAction: 'Cancel',
        ),
        notification: bg.Notification(
          title: 'Royal Marble',
          text: 'Work location tracking is active',
          priority: bg.Config.NOTIFICATION_PRIORITY_LOW,
          sticky: false,
        ),
      );

  /// Single entry point for plugin events, foreground or headless.
  static Future<void> handleEvent(String name, dynamic event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(_prefUserId);
      if (uid == null) return;
      final reporter = _Reporter(uid, prefs.getString(_prefUserName) ?? '',
          prefs, FirebaseFirestore.instance);

      switch (name) {
        case bg.Event.LOCATION:
        case bg.Event.MOTIONCHANGE:
          final l = event as bg.Location;
          if (l.sample) return;
          state.value = state.value.copyWith(lastLocation: l);
          await reporter.location(l, prefs.getStringList(_prefProject));
        case bg.Event.HEARTBEAT:
          final l = (event as bg.HeartbeatEvent).location;
          await reporter.heartbeat(l);
        case bg.Event.PROVIDERCHANGE:
          final e = event as bg.ProviderChangeEvent;
          state.value = state.value.copyWith(
            locationEnabled: e.enabled,
            gps: e.gps,
            authorization: e.status,
            preciseLocation: e.accuracyAuthorization ==
                bg.ProviderChangeEvent.ACCURACY_AUTHORIZATION_FULL,
          );
          await reporter.provider(e);
        case bg.Event.CONNECTIVITYCHANGE:
          final connected = (event as bg.ConnectivityChangeEvent).connected;
          state.value = state.value.copyWith(online: connected);
          await reporter.flag(
            'online',
            connected,
            onBad: ('offline', 'Phone lost internet connection', 'warning'),
            onGood: ('online', 'Phone is back online', 'info'),
            badWhen: false,
          );
        case bg.Event.POWERSAVECHANGE:
          final on = event as bool;
          state.value = state.value.copyWith(powerSave: on);
          await reporter.flag(
            'powerSave',
            on,
            onBad: (
              'power_save_on',
              'Battery saver turned on (tracking may be delayed)',
              'warning'
            ),
            onGood: ('power_save_off', 'Battery saver turned off', 'info'),
            badWhen: true,
          );
        case bg.Event.ENABLEDCHANGE:
          final on = event as bool;
          state.value = state.value.copyWith(trackingEnabled: on);
          await reporter.flag(
            'trackingEnabled',
            on,
            onBad: ('tracking_stopped', 'Location tracking stopped', 'critical'),
            onGood: ('tracking_started', 'Location tracking started', 'info'),
            badWhen: false,
          );
        case bg.Event.TERMINATE:
          await reporter.log(
              'app_closed', 'App was closed (tracking continues)', 'info');
        case bg.Event.BOOT:
          await reporter.log('device_boot', 'Phone restarted', 'info');
      }
    } catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
    }
  }
}

/// Writes status to Firestore and logs transitions, remembering the last
/// reported value of each flag in SharedPreferences under `ds.<field>`.
class _Reporter {
  _Reporter(this.uid, this.userName, this.prefs, this.db);

  final String uid;
  final String userName;
  final SharedPreferences prefs;
  final FirebaseFirestore db;

  DocumentReference<Map<String, dynamic>> get _user =>
      db.collection('users').doc(uid);

  Future<void> _status(Map<String, dynamic> fields) => _user.update({
        for (final e in fields.entries) 'deviceStatus.${e.key}': e.value,
        'deviceStatus.lastSeen': FieldValue.serverTimestamp(),
        'deviceStatus.silent': false,
      });

  Future<void> log(String type, String message, String severity) =>
      db.collection('device_events').add({
        'uid': uid,
        'userName': userName,
        'type': type,
        'message': message,
        'severity': severity,
        'at': Timestamp.now(),
        'receivedAt': FieldValue.serverTimestamp(),
      });

  /// Records [value] for [field]; logs [onBad]/[onGood] when it crosses into
  /// or out of the bad state ([badWhen]). A first-ever reading only logs if bad.
  Future<void> flag(
    String field,
    bool value, {
    required (String, String, String) onBad,
    required (String, String, String) onGood,
    required bool badWhen,
  }) async {
    final key = 'ds.$field';
    final previous = prefs.getBool(key);
    await prefs.setBool(key, value);
    await _status({field: value});
    if (previous == value) return;
    if (value == badWhen) {
      await log(onBad.$1, onBad.$2, onBad.$3);
    } else if (previous != null) {
      await log(onGood.$1, onGood.$2, onGood.$3);
    }
  }

  static String _permission(int status) => switch (status) {
        bg.Config.AUTHORIZATION_STATUS_ALWAYS => 'always',
        bg.Config.AUTHORIZATION_STATUS_WHEN_IN_USE => 'whenInUse',
        bg.Config.AUTHORIZATION_STATUS_DENIED => 'denied',
        bg.Config.AUTHORIZATION_STATUS_RESTRICTED => 'restricted',
        _ => 'notDetermined',
      };

  Future<void> provider(bg.ProviderChangeEvent e) async {
    await flag('locationEnabled', e.enabled,
        onBad: ('location_off', 'Location services turned OFF', 'critical'),
        onGood: ('location_on', 'Location services turned back on', 'info'),
        badWhen: false);
    await flag('gps', e.gps,
        onBad: ('gps_off', 'GPS turned off (only network location)', 'warning'),
        onGood: ('gps_on', 'GPS turned back on', 'info'),
        badWhen: false);
    await flag(
        'preciseLocation',
        e.accuracyAuthorization ==
            bg.ProviderChangeEvent.ACCURACY_AUTHORIZATION_FULL,
        onBad: (
          'precise_off',
          'Precise location turned off (approximate only)',
          'critical'
        ),
        onGood: ('precise_on', 'Precise location turned back on', 'info'),
        badWhen: false);

    final permission = _permission(e.status);
    final previous = prefs.getString('ds.permission');
    await prefs.setString('ds.permission', permission);
    await _status({'permission': permission});
    if (previous != permission && (previous != null || permission != 'always')) {
      await log(
        'permission_changed',
        'Location permission changed to "$permission"',
        permission == 'always' ? 'info' : 'critical',
      );
    }
  }

  Future<void> location(bg.Location l, List<String>? project) async {
    double? distanceToEdge;
    if (project != null && project.length == 3) {
      final lat = double.tryParse(project[0]);
      final lng = double.tryParse(project[1]);
      final radius = double.tryParse(project[2]);
      if (lat != null && lng != null && radius != null) {
        distanceToEdge =
            haversineMeters(l.coords.latitude, l.coords.longitude, lat, lng) -
                radius;
      }
    }

    await _user.update({
      'currentLocation': {'Lat': l.coords.latitude, 'Lng': l.coords.longitude},
      if (distanceToEdge != null) 'distanceToProject': distanceToEdge,
      'deviceStatus.lastLocation': {
        'lat': l.coords.latitude,
        'lng': l.coords.longitude,
        'accuracy': l.coords.accuracy,
        'mock': l.mock,
        'moving': l.isMoving,
        'at': Timestamp.fromDate(DateTime.parse(l.timestamp)),
      },
      'deviceStatus.battery': l.battery.level,
      'deviceStatus.charging': l.battery.isCharging,
      'deviceStatus.lastSeen': FieldValue.serverTimestamp(),
      'deviceStatus.silent': false,
    });
    await _user
        .collection('location')
        .doc('current')
        .set({'location': l.toMap()});

    if (l.mock) {
      await flag('mock', true,
          onBad: ('mock_location', 'Fake GPS / mock location detected', 'critical'),
          onGood: ('mock_cleared', 'Real GPS restored', 'info'),
          badWhen: true);
    } else if (prefs.getBool('ds.mock') == true) {
      await flag('mock', false,
          onBad: ('mock_location', '', 'critical'),
          onGood: ('mock_cleared', 'Real GPS restored', 'info'),
          badWhen: true);
    }

    final level = l.battery.level;
    if (level >= 0) {
      await flag('batteryLow', level < 0.15 && !l.battery.isCharging,
          onBad: (
            'battery_low',
            'Battery low (${(level * 100).round()}%)',
            'warning'
          ),
          onGood: ('battery_ok', 'Battery recovered', 'info'),
          badWhen: true);
    }
  }

  Future<void> heartbeat(bg.Location? l) async {
    await _status({
      if (l != null) 'battery': l.battery.level,
      if (l != null) 'charging': l.battery.isCharging,
    });
  }
}

/// Great-circle distance in metres.
double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
  return 2 * r * asin(sqrt(a));
}
